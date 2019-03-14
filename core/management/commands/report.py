import cpuinfo
import datetime
import distro
import natural.size
import os
import platform
import psutil
import requests
import sys
import uuid

from django.conf import settings
from django.core.management.base import BaseCommand
from git import Repo
from tabulate import tabulate


class Command(BaseCommand):
  help = 'creates a disgnostic report'
  MODULES = ['hawthorne', 'system', 'logs', 'python', 'usage']
  HEADERS = ['Property', 'Value']

  def add_arguments(self, parser):
    parser.add_argument(
        '--module', '-m',
        dest='modules',
        action='store',
        nargs='*',
        help='The modules that should be included in the report. ' +
             'Currently %(choices)s are supported. All are selected by default',
        choices=self.MODULES,
        metavar='MODULE'
    )

    parser.add_argument(
        '--provider', '-p',
        action='store',
        dest='provider',
        help='Currently %(choices)s are supported. %(default)s is the default.',
        choices=['rentry', 'hastebin', 'local'],
        metavar='PROVIDER',
        default='rentry'
    )

  # https://stackoverflow.com/questions/136168/get-last-n-lines-of-a-file-with-python-similar-to-tail
  def tail(self, f, lines=1, _buffer=4098):
    """Tail a file and get X lines from the end"""

    result = []
    count = -1
    while len(result) < lines:
      try:
        f.seek(count * _buffer, os.SEEK_END)
      except IOError:
        f.seek(0)
        result = f.readlines()
        break

      result = f.readlines()
      count -= 1

    return ''.join(result[-lines:])

  def hastebin(self, output):
    req = requests.post("https://hastebin.com/documents", data=output.encode('utf-8'))

    return "https://hastebin.com/" + req.json()["key"]

  def rentry(self, output):
    csrf = requests.get('https://rentry.co').cookies['csrftoken']
    headers = {"Referer": 'https://rentry.co'}

    payload = {
        'csrfmiddlewaretoken': csrf,
        'text': output
    }
    return requests.post('https://rentry.co/api/new',
                         data=payload,
                         headers=headers,
                         cookies={'csrftoken': csrf}).json()['url']

  def local(self, output):
    name = "~/report.hawthorne.{}.md".format(datetime.date.today().isoformat())
    with open(name, 'w') as file:
      file.write(output)

    return name

  def handle(self, provider, modules, *args, **options):
    if not modules:
      modules = self.MODULES

    output = ''

    if 'system' in modules:
      output += '# System \n'
      table = [
          ['Distributon', distro.name(pretty=True)],
          ['Architecture', platform.architecture()[0]],
          ['Machine Type', platform.machine()],
          ['Processor', platform.processor()],
      ]

      output += tabulate(table, tablefmt="github", headers=self.HEADERS)
      output += '\n\n'

    if 'usage' in modules:
      output += '# Usage \n'
      output += '## RAM \n'
      ram = psutil.virtual_memory()
      table = [
          ['Total', natural.size.filesize(ram.total, format='binary')],
          ['Used', natural.size.filesize(ram.used, format='binary')],
          ['Available', natural.size.filesize(ram.available, format='binary')],
      ]
      output += tabulate(table, tablefmt="github", headers=self.HEADERS)
      output += '\n\n'

      output += '## CPU \n'
      table = [
          ['Usage', psutil.cpu_percent(interval=1)],
          ['Cores', psutil.cpu_count()],
          ['Name', cpuinfo.get_cpu_info()['brand']],
      ]
      output += tabulate(table, tablefmt="github", headers=self.HEADERS)
      output += '\n\n'

      output += '## Disk \n'
      # disk usage per disk?
      disk = psutil.disk_usage('/')
      table = [
          ['Total', natural.size.filesize(disk.total, format='binary')],
          ['Free', natural.size.filesize(disk.free, format='binary')],
          ['Used', natural.size.filesize(disk.used, format='binary')],
          ['Used (%)', disk.percent]
      ]
      output += tabulate(table, tablefmt="github", headers=self.HEADERS)
      output += '\n\n'

      output += '## Processes \n'
      output += '### Top Memory Usage \n'
      table = []

      def memory(process):
        try:
          return process.memory_percent()
        except (psutil.AccessDenied,
                psutil.ZombieProcess):
          return 0
      procs = sorted(psutil.process_iter(), key=memory, reverse=True)[:3]
      for process in procs:
        table.append([process.name(), process.memory_percent()])
      output += tabulate(table, tablefmt="github",
                         headers=['Process', 'Memory Usage (%)'])
      output += '\n\n'

      output += '### Top CPU Usage \n'
      table = []

      def cpu(process):
        try:
          return sum(process.cpu_times())
        except (psutil.AccessDenied,
                psutil.ZombieProcess):
          return 0
      procs = sorted(psutil.process_iter(), key=cpu, reverse=True)[:3]
      for process in procs:
        table.append([process.name(), process.cpu_percent(0.1)])
      output += tabulate(table, tablefmt="github", headers=['Process', 'CPU Usage (%)'])

      output += '\n\n'

    if 'hawthorne' in modules:
      repo = Repo(settings.BASE_DIR)

      output += '# Hawthorne \n'
      table = [
          ['Location', settings.BASE_DIR],
          ['Branch', repo.active_branch],
          ['Upstream', repo.active_branch.tracking_branch()],
          ['Release', repo.git.describe(abbrev=0, tags=True, match="v*")],
          ['Commit', repo.git.rev_parse('HEAD', short=True)],
      ]

      output += tabulate(table, tablefmt="github", headers=self.HEADERS)
      output += '\n\n'

    if 'python' in modules:
      output += '# Python \n'
      table = [
          ['PYTHONPATH', sys.path],
          ['Version', platform.python_version()],
          ['Implementation', platform.python_implementation()]
      ]

      output += tabulate(table, tablefmt="github", headers=self.HEADERS)
      output += '\n\n'

    if 'logs' in modules:
      output += '# Logs \n'

      with open(settings.LOGGING['handlers']['file']['filename'], 'r') as log:
        log = self.tail(log, 100)

      output += '```\n{}\n```'.format(log)
      output += '\n\n'

    output += '# Report \n'
    output += 'was generated at {} and has the identifier {}'.format(
        datetime.datetime.now(),
        uuid.uuid4()
    )

    if provider == 'rentry':
      url = self.rentry(output)
    elif provider == 'hastebin':
      url = self.hastebin(output)
    elif provider == 'local':
      url = self.local(output)
      self.stdout.write("Your file has been locally saved," +
                        "instead of sending the URL," +
                        "please send the file in the location shown below.")

    url = self.style.SUCCESS(url)
    self.stdout.write("Your file has been successfully uploaded to {}. ".format(url) +
                      "To troubleshoot send the link to indietyp#0001 on Discord " +
                      "or use it in an issue on GitHub for a problem that occured.")

    return
