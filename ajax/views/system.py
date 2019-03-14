import json
import re
import requests
import xml.etree.ElementTree as ET

from core.models import Server, User
from django.conf import settings
from django.contrib.auth.decorators import login_required, permission_required
from django.http import HttpResponse
from django.shortcuts import render
from django.views.decorators.cache import cache_page
from django.views.decorators.http import require_http_methods
from git import Repo
from panel.settings import BASE_DIR
from valve.steam.id import SteamID, letter_type_map


@cache_page(60 * 15)
@login_required
@permission_required('core.view_update', raise_exception=True)
@require_http_methods(['POST'])
def update(request, *args, **kwargs):
  repo = Repo(BASE_DIR)
  repo.git.fetch()

  current = repo.git.describe(abbrev=0, tags=True, match="v*")
  upstream = repo.git.describe('origin/master', abbrev=0, tags=True, match="v*")

  if current != upstream:
    return render(request, 'components/home/update.pug', {'current': current,
                                                          'upstream': upstream})
  else:
    return HttpResponse('')


def convert_steamid(q):
  steamid3 = re.compile(r'^\[(?P<type>[UgT]):1:(?P<W>\d+)\]$')
  steamid32 = re.compile(r'^STEAM_(?P<X>\d+):(?P<Y>[01]{1}):(?P<Z>\d+)$')
  steamid64 = re.compile(r'^(?P<W>\d{17})$')

  match = steamid64.match(q)
  if match and 0x0110000100000001 <= int(q) and 0x01100001FFFFFFFF >= int(q):
    return match.group('W'), True

  match = steamid32.match(q)
  if match:
    universe = int(match.group('X'))
    flag = int(match.group('Y'))  # defined as sub part of the ID (flag)
    identifier = int(match.group('Z'))

    if universe == 0:
      universe = 1

    return (universe << 56) + (1 << 52) + (1 << 32) + (identifier << 1) + flag, True

  match = steamid3.match(q)
  if match:
    universe = letter_type_map[match.group('type')]
    identifier = int(match.group('W'))

    return (universe << 56) + (1 << 52) + (1 << 32) + identifier, True

  if 'steamcommunity.com' in q:
    if '/id/' in q:
      r = requests.get(q, params={'xml': '1'})
      return ET.fromstring(r.text).find('steamID64').text, True
    else:
      return SteamID.from_community_url(q).as_64(), True

  return q, False


@login_required
@require_http_methods(['POST'])
def search(request, *args, **kwargs):
  # --> User
  # --> Server
  users = []
  servers = []

  payload = json.loads(request.body)
  q = payload['query']

  if request.user.has_perm('core.view_user'):
    q, converted = convert_steamid(q)
    if converted:
      users = User.objects.filter(username__icontains=str(q), is_steam=True)
    else:
      users = User.objects.filter(namespace__icontains=q, is_steam=True)

  if request.user.has_perm('core.view_server'):
    servers = Server.objects.filter(name__icontains=q)

  users = users[:settings.PAGE_SIZE]
  servers = servers[:settings.PAGE_SIZE]
  return render(request, 'skeleton/globals/search.pug', {'servers': servers,
                                                         'users': users})
