#!/usr/bin/python3

import click
import os
import pip
import shutil


from configparser import ConfigParser
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
  # create a pdf instead of a request
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


@click.command()
@click.option('--link/--no-link', is_flag=True, expose_value=True,
              default=False)
@click.option('--bind', type=click.Choice(['socket', 'port']), default='socket')
@click.option('--config', type=click.Path(exists=True), default='/etc/nginx/sites-enabled/hawthorne.conf',)
@click.option('--gunicorn/--no-gunicorn', is_flag=True, expose_value=True,
              prompt='reconfigure gunicorn')
@click.option('--nginx/--no-nginx', is_flag=True, expose_value=True,
              prompt='reconfigure nginx config')
@click.option('--logrotate/--no-logrotate', is_flag=True, expose_value=True,
              prompt='reconfigure logrotate.d config')
@click.option('--supervisor/--no-supervisor', is_flag=True, expose_value=True,
              prompt='reconfigure supervisor.d config')
def reconfigure(bind, link, config, gunicorn, nginx, logrotate, supervisor):
  CONFIG_LOCATION = BASE_DIR + '/cli/configs'

  if gunicorn:
    shutil.copy(CONFIG_LOCATION + '/gunicorn.default.conf.py',
                BASE_DIR + '/gunicorn.conf.py')

    if bind == 'port':
      with open(BASE_DIR + '/gunicorn.conf.py', 'r+') as file:
        contents = file.read()
        contents = contents.replace("bind = 'unix:/var/run/hawthorne.sock'",
                                    "bind = '127.0.0.1:8000'")

        file.seek(0)
        file.truncate()
        file.write(contents)

  if supervisor:
    config = ConfigParser()
    config.read(CONFIG_LOCATION + '/supervisor.default.conf')

    for section in config.sections():
      if 'directory' in config[section]:
        config[section]['directory'] = BASE_DIR

    with open(BASE_DIR + '/supervisor.conf', 'w') as file:
      config.write(file)

    if link:
      try:
        os.symlink(BASE_DIR + '/supervisor.conf', '/etc/supervisor/conf.d/hawthorne.conf')
      except Exception as e:
        click.echo('Symlink to supervisor failed. ({})'.format(e))

    run(['supervisorctl', 'reread'], stdout=PIPE, stderr=PIPE)
    run(['supervisorctl', 'update'], stdout=PIPE, stderr=PIPE)
    run(['supervisorctl', 'restart', 'hawthorne'], stdout=PIPE, stderr=PIPE)

  if logrotate:
    try:
      os.symlink(CONFIG_LOCATION + '/logrotate.default', '/etc/logrotate.d/hawthorne')
    except Exception as e:
      click.echo('Symlink to logrotate failed. ({})'.format(e))

  if nginx:
    pass


cli.add_command(update)
cli.add_command(report)
cli.add_command(verify)
cli.add_command(version)
cli.add_command(reconfigure)


if __name__ == '__main__':
  cli()
