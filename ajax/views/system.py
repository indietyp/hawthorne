import json
import re

from core.models import Server, User
from django.contrib.auth.decorators import login_required, permission_required
from django.http import HttpResponse
from django.shortcuts import render
from django.views.decorators.cache import cache_page
from django.views.decorators.http import require_http_methods
from git import Repo
from panel.settings import BASE_DIR


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
  steamid32 = re.compile(r'^STEAM_(?P<X>\d+):(?P<Y>\d+):(?P<Z>\d+)$')
  steamid64 = re.compile(r'^(?P<W>\d{17})$')

  match = steamid64.match(q)
  if match and 0x0110000100000001 <= int(q) and 0x01100001FFFFFFFF >= int(q):
    return match.group('W'), True

  match = steamid32.match(q)
  if match:
    pass

  match = steamid3.match(q)
  if match:
    pass

  return q, False


@login_required
@permission_required('core.view_update', raise_exception=True)
@require_http_methods(['POST'])
def search(request, *args, **kwargs):
  # --> User
  # --> Server

  payload = json.loads(request.body)
  q = payload['query']

  servers = Server.objects.filter(name__icontains=q)

  q, converted = convert_steamid(q)
  if converted:
    users = User.objects.filter(username__icontains=q, is_steam=True)
  else:
    users = User.objects.filter(namespace__icontains=q, is_steam=True)

  return render(request, 'skeleton/globals/search.pug', {'servers': servers,
                                                         'users': users})
