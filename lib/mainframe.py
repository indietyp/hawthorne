import os
from collections import namedtuple
from configparser import ConfigParser

import requests
from django.conf import settings


class Mainframe:
  def __init__(self, target=None):
    self.current = namedtuple('Mainframe', ['id', 'salt', 'mainframe'])

    self.file = '{}/mainframe.ini'.format(settings.BASE_DIR)
    self.config = ConfigParser()

    self.target = target if target else settings.MAINFRAME

  def __enter__(self):
    if not self.check():
      self.register()

    self.populate()
    return self

  def __exit__(self, *args, **kwargs):
    self.save()

  def populate(self):
    self.current.id = self.config[self.target]['ID']

    if 'SALT' in self.config[self.target]:
      self.current.salt = self.config[self.target]['SALT']

    self.current.mainframe = self.target

    return self

  def collect(self):
    output = {}
    for target in self.config.sections():
      output[target] = self.config[target]['ID']

    return output

  def __call__(self):
    return self.current

  def register(self):
    payload = {}
    r = requests.put("https://{}/api/v1/instance".format(self.target), json=payload)

    o = r.json()
    if 'result' not in o:
      return False

    result = o['result']

    if self.target not in self.config.sections():
      self.config[self.target] = {}

    self.config[self.target]['ID'] = result['id']

    if 'salt' in result:
      self.config[self.target]['SALT'] = result['salt']

    return True

  def save(self):
    with open(self.file, 'w') as out:
      self.config.write(out)

    return self

  def check(self):
    exists = True if os.path.exists(self.file) else False

    if exists:
      self.config.read(self.file)
      if self.target not in self.config.sections():
        return False
    else:
      return False

    return True

  def invite(self, request, target):
    payload = {'user': str(target.id),
               'target': target.email,
               'from': request.user.namespace if request.user.is_steam else request.user.username}

    r = requests.put("https://{}/api/v1/instance/{}/invite".format(self.target, self.current.id),
                     json=payload)
    result = r.json()

    return True if 'result' in result else False
