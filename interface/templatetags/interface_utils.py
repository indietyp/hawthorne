import datetime
from base64 import b85encode
from binascii import unhexlify

import natural.date
from django.conf import settings
from django.template.defaultfilters import date
from django.template.defaulttags import register


@register.filter
def get_item(dictionary, key):
  return dictionary.get(key)


@register.filter
def duration(delta):
  now = datetime.datetime.now()
  return natural.date.delta(now, now + delta, words=False)[0]


@register.filter
def flatten(value, location):
  return list(map(lambda x: x[int(location)], value))


@register.filter
def warp(duration):
  now = datetime.datetime.now()
  return now + duration
