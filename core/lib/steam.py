import steamapi
from django.conf import settings
from core.models import Country


def populate(user):
  if user.steam:
    steamapi.core.APIConnection(api_key=settings.SOCIAL_AUTH_STEAM_API_KEY, validate_key=True)
    fetched = steamapi.user.SteamUser(userid=user.username)

    user.ingame = fetched.name
    user.profile = fetched.profile_url
    user.avatar = fetched.avatar

    if fetched.country_code is not None:
      user.country = Country.objects.get_or_create(code=fetched.country_code)[0]

    try:
      realname = fetched.real_name
    except Exception:
      realname = None

    if realname is not None:
      print(realname)
      realname = realname.split(' ')
      user.first_name = realname[0]
      if len(realname) > 1:
        user.last_name = realname[-1]

    print('populated')
    user.save()
