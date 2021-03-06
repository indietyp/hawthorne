import os
import platform
import sys

import requests
from django.conf import settings
from django.core.management.base import BaseCommand

from lib.mainframe import Mainframe


class Command(BaseCommand):
  help = 'creates a new report sent to the current maintainer'

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
    with Mainframe() as mainframe:
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
      response = requests.put("https://{}/api/v1/instance/{}/report".format(
                              settings.MAINFRAME, mainframe().id),
                              json=payload)

      identifier = response.json()['result']['id']

      self.stdout.write(self.style.SUCCESS("""
        When talking to the maintainer indietyp,
        please use this ID to identify your ticket:"""))
      self.stdout.write(identifier)
