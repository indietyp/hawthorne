import logging
import steamapi

from core.models import Country
from django.conf import settings


logger = logging.getLogger(__name__)


def populate(user, save=True):
  if user.is_steam:
    steamapi.core.APIConnection(api_key=settings.SOCIAL_AUTH_STEAM_API_KEY,
                                validate_key=True)

    fetched = steamapi.user.SteamUser(userid=user.username)
    try:
      user.namespace = fetched.name
      user.profile = fetched.profile_url
      user.avatar = fetched.avatar_full

      # switch to IP based country when not present yet
      if fetched.country_code is not None and not user.country:
        user.country = Country.objects.get_or_create(code=fetched.country_code.lower())[0]

      try:
        realname = fetched.real_name
      except Exception:
        realname = None

      if realname is not None:
        realname = realname.split(' ')
        user.first_name = realname[0][:30]
        if len(realname) > 1:
          user.last_name = realname[-1][:150]
    except Exception as e:
      logger.warning("Could not populate user ({})".format(e))
      return

    if save:
      user.save()
