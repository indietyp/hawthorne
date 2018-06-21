import re
import steamapi
from django.conf import settings
from core.models import Country


def populate(user, save=True):
  if user.is_steam:
    steamapi.core.APIConnection(api_key=settings.SOCIAL_AUTH_STEAM_API_KEY, validate_key=True)
    fetched = steamapi.user.SteamUser(userid=user.username)

    # https://stackoverflow.com/questions/13729638/how-can-i-filter-emoji-characters-from-my-input-so-i-can-save-in-mysql-5-5
    try:
      # UCS-4
      highpoints = re.compile(u'[\U00010000-\U0010ffff]')
    except re.error:
      # UCS-2
      highpoints = re.compile(u'[\uD800-\uDBFF][\uDC00-\uDFFF]')
    user.namespace = highpoints.sub(u'\u25FD', fetched.name)

    user.profile = fetched.profile_url
    user.avatar = fetched.avatar

    if fetched.country_code is not None:
      user.country = Country.objects.get_or_create(code=fetched.country_code)[0]

    try:
      realname = fetched.real_name
    except Exception:
      realname = None

    if realname is not None:
      realname = realname.split(' ')
      user.first_name = realname[0]
      if len(realname) > 1:
        user.last_name = realname[-1]

    if save:
      user.save()
