import re

from core.models import Country


def populate(strategy, details, backend, user=None, *args, **kwargs):
  if backend.name == 'steam' and user is not None:
    information = details['player']

    if 'realname' in information and information['realname']:
      information['realname'] = information['realname'].split(' ')

      user.first_name = information['realname'][0]

      if len(information['realname']) > 1:
        user.last_name = information['realname'][-1]

    try:
      # UCS-4
      highpoints = re.compile(u'[\U00010000-\U0010ffff]')
    except re.error:
      # UCS-2
      highpoints = re.compile(u'[\uD800-\uDBFF][\uDC00-\uDFFF]')

    user.namespace = highpoints.sub(u'\u25FD', information['personaname'])

    if 'loccountrycode' in information and information['loccountrycode']:
      user.country = Country.objects.get_or_create(code=information['loccountrycode'])[0]

    user.avatar = information['avatar']
    user.profile = information['profileurl']
    user.save()
