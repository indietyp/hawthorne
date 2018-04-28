from collections import namedtuple

import requests
from django.conf import settings
from core.models import Mainframe as MainframeModel


class Mainframe:
  def __init__(self, target=None):
    self.current = namedtuple('Mainframe', ['id', 'salt', 'mainframe'])

    self.target = target if target else settings.MAINFRAME

  def __enter__(self):
    if not self.check():
      self.register()

    self.populate()
    return self

  def __exit__(self, *args, **kwargs):
    self.save()

  def populate(self):
    self.mainframe = MainframeModel.objects.filter(domain=self.target)[0]

    self.current.id = self.mainframe.assigned

    if 'token' in self.mainframe.__dir__():
      self.current.token = self.mainframe.token

    self.current.mainframe = self.target

    return self

  def collect(self):
    output = {}
    for target in MainframeModel.objects.all():
      output[target.domain] = target.assigned

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

    self.mainframe, created = MainframeModel.objects.get_or_create(domain=self.target)
    self.mainframe.assigned = result['id']

    if 'token' in result:
      self.mainframe.token = result['token']

    self.mainframe.save()
    return True

  def save(self):
    self.mainframe.save()

    return self

  def check(self):
    return bool(MainframeModel.objects.filter(domain=self.target))

  def invite(self, request, target):
    payload = {'user': str(target.id),
               'target': target.email,
               'from': request.user.namespace if request.user.is_steam else request.user.username}

    r = requests.put("https://{}/api/v1/instance/{}/invite".format(self.target, self.current.id),
                     json=payload)
    result = r.json()

    return True if 'result' in result else False
