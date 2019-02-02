import datetime
import humanize
import natural.date

from django.conf import settings
from django.template.defaulttags import register
from steam import SteamID, WebAPI


api = WebAPI(key=settings.SOCIAL_AUTH_STEAM_API_KEY)


@register.filter
def as32(value):
  return SteamID(value).as_32


@register.filter
def as2(value):
  return SteamID(value).as_steam2


@register.filter
def as3(value):
  return SteamID(value).as_steam3


@register.filter
def vac(value):
  ban = api.ISteamUser.GetPlayerBans(steamids=value)['players'][0]
  if ban['VACBanned']:
    return "currently banned"
  elif ban['DaysSinceLastBan'] == 0:
    return "no recorded ban(s)"
  else:
    now = datetime.datetime.now()
    delta = datetime.timedelta(days=ban['DaysSinceLastBan'])
    return "{} on record and expired {}".format(ban['NumberOfVACBans'],
                                                natural.date.duration(now - delta))


@register.filter
def level(value):
  return api.IPlayerService.GetSteamLevel(steamid=value)['response']['player_level']


@register.filter
def created(value):
  user = api.ISteamUser.GetPlayerSummaries(steamids=value)['response']
  timestamp = user['players'][0]['timecreated']

  return humanize.naturaltime(datetime.datetime.fromtimestamp(timestamp))
