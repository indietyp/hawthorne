import datetime
import isodate
import natural.date

from django.contrib.auth.models import Group, Permission
from django.db.models import BooleanField
from django.template.defaulttags import register

from core.models import ServerPermission, Token


@register.filter
def get(value, key):
  if isinstance(value, dict):
    return value.get(key)
  else:
    return value[int(key)]


@register.filter
def duration(delta):
  if isinstance(delta, str):
    return ''

  now = datetime.datetime.now()
  return natural.date.delta(now, now + delta, words=False)[0]


@register.filter
def day(day):
  return natural.date.day(day)


@register.filter
def flatten(value, location):
  return list(map(lambda x: x[int(location)], value))


@register.filter
def warp(duration):
  now = datetime.datetime.now()
  return now + duration


@register.filter
def permission_percentage(value):
  data = value.permissions.all().count() if isinstance(value, (Group, Token)) else len(value.get_all_permissions())

  if data == 0:
    return "0"

  return str(int(round(data / Permission.objects.all().count() * 100)))


@register.filter
def m2m_duration(m2m):
  total = datetime.timedelta()
  for delta in m2m.all():
    total += delta.disconnected - delta.connected

  return total


@register.filter
def count(obj):
  return obj.count()


@register.filter
def mask(target, modifier='0.75'):
  target = str(target)

  start = len(target) - (len(target) * float(modifier))

  result = ""
  for i in range(len(target)):
    if i >= start and target[i] != '-':
      result += "●"
    else:
      result += target[i]

  return result


@register.filter
def isoduration(v):
  return isodate.duration_isoformat(v)


@register.filter
def srv_perms(v):
  output = []
  for field in v._meta.get_fields():
    if isinstance(field, BooleanField):
      name = field.name.split('can_')[1].capitalize().replace('_', ' ')
      output.append([field.help_text, name, getattr(v, field.name)])

  output = sorted(output, key=lambda x: x[0])
  return output


@register.filter
def gen_srv_perms(v):
  return srv_perms(ServerPermission())
