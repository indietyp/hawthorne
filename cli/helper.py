#!/usr/bin/python3

import click
import os
import pip


from django.core.management import call_command
from django.db import connection
from git import Repo
from git.exc import GitCommandError
from shutil import which
from subprocess import PIPE, run


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
repo = Repo(BASE_DIR)
repo.git.fetch()


@click.group()
def cli():
  pass


@click.command()
@click.option('--supervisor/--no-supervisor', default=True,
              is_flag=True, expose_value=True)
def update(supervisor):

  os.chdir(BASE_DIR)
  os.environ.setdefault("DJANGO_SETTINGS_MODULE", "panel.settings")

  tracked = repo.active_branch.tracking_branch()
  if repo.git.rev_parse("@") == repo.git.rev_parse(tracked):
    click.secho('Hawthorne is already up-to-date', bold=True, fg='green')
    return

  repo.git.pull()
  pip.main(['install', '-U', '-r', BASE_DIR + '/requirements.txt'])
  call_command('migrate', interactive=False)
  call_command('collectstatic', interactive=False)

  timezones = run(['mysql_tzinfo_to_sql', '/usr/share/zoneinfo'],
                  stdout=PIPE, stderr=PIPE).stdout
  with connection.cursor() as cursor:
    cursor.execute('USE mysql')
    cursor.execute(timezones)

  if supervisor and which('supervisorctl'):
    run(['supervisorctl', 'reread'], stdout=PIPE, stderr=PIPE)
    run(['supervisorctl', 'update'], stdout=PIPE, stderr=PIPE)
    run(['supervisorctl', 'restart', 'hawthorne'], stdout=PIPE, stderr=PIPE)


@click.command()
def report():
  click.echo('I am a very big boi report, yes!')


@click.command()
def verify():
  try:
    repo.git.diff_index('HEAD', '--', quiet=True)
    click.echo('You are compatible with the upstream.')
  except GitCommandError:
    click.echo('You are {} compatible with the upstream.'.format(click.style('not', bold=True)))
    stash = click.confirm('Do you want to stash your local changes?')

    if stash:
      repo.git.stash()


@click.command()
@click.option('--yes', is_flag=True, expose_value=True)
def version(yes):
  head = repo.active_branch.tracking_branch()
  current = repo.git.describe(abbrev=0, tags=True, match="v*")
  upstream = repo.git.describe(head, abbrev=0, tags=True, match="v*")

  if current != upstream:
    click.echo('You are currently {} on the latest version of hawthorne.'.format(click.style('not', bold=True)))
    click.echo('Your local current version is {}, but the latest version is {}'.format(click.style(current, bold=True), click.style(upstream, fg='red')))

    if not yes:
      yes = click.confirm("Do you want to update your system?")

    if yes:
      update(True)

  else:
    click.echo("You are up-to-date!")


cli.add_command(update)
cli.add_command(report)
cli.add_command(verify)
cli.add_command(version)


if __name__ == '__main__':
  cli()
