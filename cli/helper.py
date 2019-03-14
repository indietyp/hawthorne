#!/usr/bin/python3
import click
import django
import django.core.management
import os
import pip
import random
import shutil
import string
import sys
import warnings


from configparser import ConfigParser
from django.db import connection
from git import Repo
from git.exc import GitCommandError
from shutil import which
from subprocess import PIPE, run
from urllib.parse import urlparse


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(os.path.realpath(__file__))))
sys.path.append(BASE_DIR)
warnings.filterwarnings("ignore", category=FutureWarning)

repo = Repo(BASE_DIR)
repo.git.fetch()


@click.group()
def cli():
  pass


@click.command()
@click.option('--supervisor/--no-supervisor', default=True,
              is_flag=True, expose_value=True)
def update(supervisor):
  """update Hawthorne to the latest version"""

  os.chdir(BASE_DIR)
  os.environ.setdefault("DJANGO_SETTINGS_MODULE", "panel.settings")

  tracked = repo.active_branch.tracking_branch()
  if repo.git.rev_parse("@") == repo.git.rev_parse(tracked):
    click.secho('Hawthorne is already up-to-date', bold=True, fg='green')
    return

  repo.git.pull()
  pip.main(['install', '-U', '-r', BASE_DIR + '/requirements.txt'])

  django.setup()
  django.core.management.call_command('migrate', interactive=False)
  django.core.management.call_command('collectstatic', interactive=False, clear=True)

  timezones = run(['mysql_tzinfo_to_sql', '/usr/share/zoneinfo'],
                  stdout=PIPE, stderr=PIPE).stdout
  with connection.cursor() as cursor:
    cursor.execute('USE mysql')
    cursor.execute(timezones)

  if supervisor and which('supervisorctl'):
    run(['supervisorctl', 'reread'], stdout=PIPE, stderr=PIPE)
    run(['supervisorctl', 'update'], stdout=PIPE, stderr=PIPE)
    run(['supervisorctl', 'restart', 'hawthorne:*'], stdout=PIPE, stderr=PIPE)


@click.command(context_settings=dict(
    allow_extra_args=True,
))
@click.option('--help', is_eager=False, is_flag=True)
def report(*args, **kwargs):
  """creates a disgnostic report"""

  os.chdir(BASE_DIR)
  os.environ.setdefault("DJANGO_SETTINGS_MODULE", "panel.settings")

  django.setup()
  django.core.management.load_command_class('core', 'report').run_from_argv(sys.argv)


@click.command()
def verify():
  """verifies integrity of Hawthorne"""

  try:
    repo.git.diff_index('HEAD', '--', quiet=True)
    click.echo('You are compatible with the upstream.')
  except GitCommandError:
    click.echo('You are {} compatible with the upstream.'.format(click.style('not',
                                                                             bold=True)))
    stash = click.confirm('Do you want to stash your local changes?')

    if stash:
      repo.git.stash()


@click.command()
@click.option('--yes', is_flag=True, expose_value=True)
def version(yes):
  """checks if the current version is installed"""

  head = repo.active_branch.tracking_branch()
  current = repo.git.describe(abbrev=0, tags=True, match="v*")
  upstream = repo.git.describe(head, abbrev=0, tags=True, match="v*")

  if current != upstream:
    click.echo('You are currently {} on the latest ' +
               'version of hawthorne.'.format(click.style('not', bold=True)))
    click.echo('Your current version is {}, but the latest version is {}.' +
               'You are advised to update hawthorne with ' +
               'the hawthorne update command'.format(click.style(current, bold=True),
                                                     click.style(upstream, fg='red')))

    if not yes:
      yes = click.confirm("Do you want to update your system?")

    if yes:
      update(True)

  else:
    click.echo("You are up-to-date!")


@click.command()
@click.option('--gunicorn/--no-gunicorn', is_flag=True, expose_value=True,
              prompt='reconfigure gunicorn')
@click.option('--nginx/--no-nginx', is_flag=True, expose_value=True,
              prompt='reconfigure nginx config')
@click.option('--apache/--no-apache', is_flag=True, expose_value=True,
              prompt='reconfigure apache config')
@click.option('--logrotate/--no-logrotate', is_flag=True, expose_value=True,
              prompt='reconfigure logrotate.d config')
@click.option('--supervisor/--no-supervisor', is_flag=True, expose_value=True,
              prompt='reconfigure supervisor.d config')
@click.option('--bind', type=click.Choice(['socket', 'port', 'container']),
              default='socket',
              help=("This option is used in conjunction with the supervisor"
                    " configuration, it defaults to socket. "
                    "socket creates a UNIX socket, "
                    "port creates a local opens a connection at 127.0.0.1:8000"
                    "container is only meant to be used by docker containers and opens"
                    "a connection at 0.0.0.0:8000"))
@click.option('--config', type=click.Path(dir_okay=False, resolve_path=True,
                                          writable=True, readable=True),
              default='/etc/<system>/sites-enabled/hawthorne.conf',
              help=("The file path of the configuration files for apache and nginx. "
                    "The variable <system> will be replaced with the configured webserver"
                    ". (possible values are nginx, apache)"))
def reconfigure(bind, link, config, gunicorn, nginx, apache, logrotate, supervisor):
  """reconfiguration of external configs"""

  CONFIG_LOCATION = BASE_DIR + '/cli/configs'

  if gunicorn:
    shutil.copy(CONFIG_LOCATION + '/gunicorn.default.conf.py',
                BASE_DIR + '/gunicorn.conf.py')

    if bind in ['port', 'container']:
      with open(BASE_DIR + '/gunicorn.conf.py', 'r+') as file:
        contents = file.read()

        if bind == 'port':
          contents = contents.replace("bind = 'unix:/var/run/hawthorne.sock'",
                                      "bind = '127.0.0.1:8000'")
        else:
          contents = contents.replace("bind = 'unix:/var/run/hawthorne.sock'",
                                      "bind = '0.0.0.0:8000'")

        file.seek(0)
        file.truncate()
        file.write(contents)

  if supervisor:
    ini = ConfigParser()
    ini.read(CONFIG_LOCATION + '/supervisor.default.conf')

    for section in ini.sections():
      if 'directory' in ini[section]:
        ini[section]['directory'] = BASE_DIR

    with open(BASE_DIR + '/supervisor.conf', 'w') as file:
      ini.write(file)

    try:
      os.unlink('/etc/supervisor/conf.d/hawthorne.conf')
    except OSError:
      pass

    os.symlink(BASE_DIR + '/supervisor.conf', '/etc/supervisor/conf.d/hawthorne.conf')

    run(['supervisorctl', 'reread'], stdout=PIPE, stderr=PIPE)
    run(['supervisorctl', 'update'], stdout=PIPE, stderr=PIPE)
    run(['supervisorctl', 'restart', 'hawthorne:*'], stdout=PIPE, stderr=PIPE)

  if logrotate:
    try:
      os.unlink('/etc/logrotate.d/hawthorne')
    except OSError:
      pass

    os.symlink(CONFIG_LOCATION + '/logrotate.default', '/etc/logrotate.d/hawthorne')

  if nginx:
    from panel.settings import ALLOWED_HOSTS
    import nginx

    c = nginx.loadf(CONFIG_LOCATION + '/nginx.example.conf')
    c.server.filter('Key', 'server_name')[0].value = ' '.join(ALLOWED_HOSTS)
    nginx.dumpf(c, config.replace('<system>', 'nginx'))

    run(['nginx', '-s', 'reload'], stdout=PIPE, stderr=PIPE)

  if apache:
    from panel.settings import ALLOWED_HOSTS
    from apacheconfig import make_loader as apacheconfig

    apache = apacheconfig()
    c = apache.loadf(CONFIG_LOCATION + '/apache.example.conf')
    c['VirtualHost']['*:80']['ServerName'] = ' '.join(ALLOWED_HOSTS)

    with open(config.replace('<system>', 'apache'), 'w') as f:
      f.write(apache.dumps(c))

    run(['service', 'apache2', 'reload'], stdout=PIPE, stderr=PIPE)


@click.command()
@click.option('--database', expose_value=True,
              help="MySQL Connection URL as described in RFC1738 Section 3.1")
@click.option('--steam', expose_value=True)
@click.option('--demo', type=bool, expose_value=True)
@click.option('--host', multiple=True, expose_value=True)  # array
@click.option('--root', expose_value=True)
@click.option('--secret', is_flag=True, default=False, expose_value=True)
def initialize(database, steam, demo, host, root, secret):
  """initializes the local hawthorne configs"""

  config = BASE_DIR + '/panel/local.ini'
  target = 'local.ini' if os.path.isfile(config) else "local.default.ini"

  if not os.path.isfile(config):
    shutil.copy(BASE_DIR + '/panel/local.default.py',
                BASE_DIR + '/panel/local.py')

  ini = ConfigParser()
  ini.read(BASE_DIR + '/panel/' + target)

  if database:
    connection = database if database.startswith('mysql://') else 'mysql://' + database

    connection = urlparse(connection)

    if connection.username:
      ini['database']['user'] = connection.username

    if connection.password:
      ini['database']['password'] = connection.password

    if connection.hostname:
      ini['database']['host'] = connection.hostname
    ini['database']['port'] = str(connection.port if connection.port else 3306)

    if connection.path:
      ini['database']['name'] = connection.path[1:]

  if steam:
    ini['system']['steamapi'] = steam

  if demo is not None:
    ini['system']['demo'] = str(demo).lower()

  if host:
    ini['system']['hosts'] = ','.join(host)

  if secret:
    secret = ''
    for _ in range(64):
      secret += random.choice(string.ascii_letters + string.digits)

    ini['system']['secret'] = secret

  if root:
    ini['system']['root'] = root

  with open(config, 'w') as file:
    ini.write(file)


cli.add_command(update)
cli.add_command(report)
cli.add_command(verify)
cli.add_command(version)
cli.add_command(reconfigure)
cli.add_command(initialize)


if __name__ == '__main__':
  cli()
