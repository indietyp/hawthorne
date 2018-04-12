import datetime

from django.core.serializers.json import DjangoJSONEncoder


class HawthorneJSONEncoder(DjangoJSONEncoder):
  """
  JSONEncoder subclass that knows how to encode date/time, decimal types, and
  UUIDs.
  """

  def default(self, o):
    if isinstance(o, datetime.timedelta):
      return o.total_seconds()
    elif isinstance(o, datetime.datetime):
      return o.timestamp()
    else:
      return super().default(o)
