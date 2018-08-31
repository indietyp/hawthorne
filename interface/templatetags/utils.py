import datetime

import natural.date
from django.template.defaulttags import register
from django.db.models import F
from django.contrib.auth.models import Group, Permission


@register.filter
def get(value, key):
  if isinstance(value, dict):
    return value.get(key)
  else:
    return value[int(key)]


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


@register.filter
def permission_percentage(value):
  data = value.permissions.all().count() if isinstance(value, Group) else value.get_all_permissions()
  return str(int(round(Permission.objects.all().count() / data * 100)))


@register.filter
def m2m_duration(m2m):
  total = datetime.timedelta()
  for delta in m2m.all():
    total += delta.disconnected - delta.connected

  return total


@register.filter
def count(obj):
  return obj.count()
