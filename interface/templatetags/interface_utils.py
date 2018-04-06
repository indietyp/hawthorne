import datetime

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
def dict_to_list(dic, key):
  output = [d[key] for d in dic]

  if isinstance(output[0], datetime.date):
    output = [date(d, settings.SHORT_DATE_FORMAT) for d in output]

  return output
