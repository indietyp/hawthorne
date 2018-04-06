import os
from collections import namedtuple
from configparser import ConfigParser

import requests
from django.conf import settings


class Mainframe:
  def __init__(self):
    self.current = namedtuple('Mainframe', ['id', 'salt', 'mainframe'])

    self.file = '{}/mainframe.ini'.format(settings.BASE_DIR)
    self.config = ConfigParser()

  def __enter__(self):
    if not self.check():
      self.register()

    self.current.id = self.config[settings.MAINFRAME]['ID']

    if 'SALT' in self.config[settings.MAINFRAME]:
      self.current.salt = self.config[settings.MAINFRAME]['SALT']

    self.current.mainframe = settings.MAINFRAME
    return self

  def __exit__(self, *args, **kwargs):
    self.save()

  def __call__(self):
    return self.current

  def register(self):
    # r = requests.get('https://api.ipify.org?format=json')
    payload = {}
    r = requests.put("http://{}/api/v1/instance".format(settings.MAINFRAME), json=payload)

    o = r.json()
    if 'result' not in o:
      return False

    result = o['result']

    if settings.MAINFRAME not in self.config.sections():
      self.config[settings.MAINFRAME] = {}

    self.config[settings.MAINFRAME]['ID'] = result['id']

    if 'salt' in result:
      self.config[settings.MAINFRAME]['SALT'] = result['salt']

    return True

  def save(self):
    with open(self.file, 'w') as out:
      self.config.write(out)

    return self

  def check(self):
    exists = True if os.path.exists(self.file) else False

    if exists:
      self.config.read(self.file)
      if settings.MAINFRAME not in self.config.sections():
        return False
    else:
      return False

    return True

  def invite(self, request, target):
    payload = {'user': str(target.id),
               'target': target.email,
               'from': request.user.namespace if request.user.is_steam else request.user.username}

    r = requests.put("http://{}/api/v1/instance/{}/invite".format(settings.MAINFRAME, self.current.id),
                     json=payload)
    result = r.json()

    return True if 'result' in result else False
