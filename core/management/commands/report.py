from django.core.management.base import BaseCommand
from django.conf import settings
from configparser import ConfigParser
import sys
import platform
import os
import requests
import json


class Command(BaseCommand):
  help = 'Creates a new report'

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

  def handle(self, *args, **options):
    config = ConfigParser()
    file = '{}/panel/mainframe.ini'.format(settings.BASE_DIR)
    register = False

    if os.path.exists(file):
      config.read(file)

      if settings.MAINFRAME not in config.sections():
        register = True
    else:
      register = True

    if register:
      r = requests.get('https://api.ipify.org?format=json')
      r = requests.put("https://{}/api/v1/instance".format(settings.MAINFRAME), json=r.json())
      config[settings.MAINFRAME] = {}
      config[settings.MAINFRAME]['ID'] = r.json()['result']['id']

      with open(file, 'w') as configfile:
        config.write(configfile)

    uname = platform.uname()
    with open(settings.LOGGING['handlers']['file']['filename'], 'r') as log:
      traceback = self.tail(log, 100)

    payload = {
        'path': sys.path,
        'version': platform.python_version(),
        'system': {x: uname.__getattribute__(x) for x in uname._fields},
        'distro': '-'.join(platform.linux_distribution()),
        'log': traceback,
        'directory': settings.BASE_DIR
    }

    response = requests.put("https://{}/api/v1/instance/{}/report".format(settings.MAINFRAME, config[settings.MAINFRAME]['ID']), json=payload)
    identifier = response.json()['result']['id']

    self.stdout.write(self.style.SUCCESS('When talking to the maintainer indietyp, please use this ID to identify your ticket:'))
    self.stdout.write(identifier)
