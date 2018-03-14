from django.template.defaulttags import register
from django.conf import settings
import datetime
import natural.date
from django.utils.dateformat import time_format
from django.template.defaultfilters import date


@register.filter
def get_item(dictionary, key):
  return dictionary.get(key)


@register.filter
def duration(delta):
  now = datetime.datetime.now()
  return natural.date.delta(now, now + delta, words=False)[0]


@register.filter
def dict_to_list(dic, key):
  output = [d[key] for d in dic]

  if isinstance(output[0], datetime.date):
    print(settings.DATE_FORMAT)
    output = [date(d, settings.DATE_FORMAT) for d in output]

  return output
