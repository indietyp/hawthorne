import json

from django.conf import settings
from django.contrib.auth.decorators import login_required, permission_required
from django.core.cache import cache
from django.shortcuts import render
from django.views.decorators.http import require_http_methods
from functools import partial
from jellyfish import jaro_winkler
from multiprocessing import Pool, cpu_count
from steam.steamid import SteamID

from core.lib.steam import populate
from core.models import User


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def search(request, *args, **kwargs):
  payload = json.loads(request.body.decode())

  if 'steam' in payload:
    steamid = SteamID.from_url('https://steamcommunity.com/id/' + payload['steam'])
    if not steamid:
      data = []
    else:
      data = User.objects.filter(username=str(steamid.as_64))
      if not data:
        user = User()
        user.is_steam = True
        user.is_active = False
        user.username = str(steamid.as_64)
        user.save()

        populate(user)
        data = [user]

  elif 'steam64' in payload:
    data = User.objects.filter(username=str(payload['steam64']))
    if not data:
      user = User()
      user.is_steam = True
      user.is_active = False
      user.username = str(payload['steam64'])

      populate(user)
      data = [user]

  elif 'local' in payload:
    data = User.objects.filter(is_steam=True, namespace__icontains=payload['local'])
    data = list(data)

  elif 'steam' in payload:
    user = User()
    user.is_steam = False
    user.is_active = False
    user.username = payload['steam']
    user.save()

    data = [user]

  return render(request, 'components/globals/dropdown/wrapper.pug',
                {'data': data[:settings.PAGE_SIZE]})
