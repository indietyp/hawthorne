from django.conf import settings
from valve.steam.api.interface import API as SteamAPI


class SteamUser:
  """
    Pythonic wrapper for Steam API for users
  """

  def __init__(self, steamid, endpoint=None):
    if not endpoint:
      endpoint = SteamAPI(settings.SOCIAL_AUTH_STEAM_API_KEY)

    self.endpoint = endpoint
    self.information = self.endpoint['ISteamUser'].GetPlayerSummaries([steamid])

  def __getattr__(self, name):
    if name not in self.information:
      return None

    return self.information['name']
