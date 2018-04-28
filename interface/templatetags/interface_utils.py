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
def dict_to_list(dic, key):
  output = [d[key] for d in dic]

  if len(output) > 0 and isinstance(output[0], datetime.date):
    output = [date(d, settings.SHORT_DATE_FORMAT) for d in output]

  return output


@register.filter
def base85(value):
  return b85encode(unhexlify(value.hex)).decode()


@register.filter
def mask(value, percentage="0.6"):
  percentage = float(percentage)

  if percentage < 1:
    characters = len(value) * percentage
  else:
    characters = int(percentage)

  output = []
  characters = len(value) - characters
  for pointer in range(len(value)):
    output.append(value[pointer] if pointer < characters else '•')

  return ''.join(output)
