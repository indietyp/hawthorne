import logging

from core.models import Country
from lib.steam import SteamUser


logger = logging.getLogger(__name__)


def populate(user, save=True):
  if user.is_steam:
    fetched = SteamUser(user.username)

    try:
      user.namespace = fetched.personaname
      user.profile = fetched.profileurl
      user.avatar = fetched.avatarfull

      # switch to IP based country when not present yet
      if fetched.loccountrycode and not user.country:
        country = fetched.loccountrycode.lower()
        user.country = Country.objects.get_or_create(code=country)[0]

      if fetched.realname:
        realname = fetched.realname.split(' ')
        user.first_name = realname[0][:30]
        if len(realname) > 1:
          user.last_name = realname[-1][:150]
    except Exception as e:
      logger.warning("Could not populate user ({})".format(e))
      return

    if save:
      user.save()
