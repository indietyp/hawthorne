from core.models import User, Country, UserLogIP, UserLogTime, UserLogUsername, Server, ServerGroup, Ban, Mutegag
from django.views.decorators.csrf import csrf_exempt
from core.utils import UniPanelJSONEncoder
from django.utils import timezone
from core.lib.steam import populate as steam_populate
from rcon.sourcemod import RConSourcemod
import datetime
from django.contrib.auth.models import Group
from django.db.models import F
from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from django.views.decorators.http import require_http_methods


@csrf_exempt
@json_response
@authentication_required
@permission_required('user.list')
@validation('user.list')
@require_http_methods(['GET', 'PUT'])
def list(request, validated=[], *args, **kwargs):
  if request.method == 'GET':
    # role query
    limit = validated['limit']
    offset = validated['offset']

    selected = User.objects.annotate(steamid=F('username'), name=F('ingame'), has_panel_access=F('is_staff'))\
                           .values('id', 'name', 'steamid', 'profile', 'has_panel_access')\
                           .filter(username__contains=validated['match'])

    if validated['has_panel_access'] is not None:
      selected = selected.filter(has_panel_access=validated['has_panel_access'])

    output = []
    selected = selected[offset:] if limit < 0 else selected[offset:limit]

    for user in selected:
      output.append(user)

    return output

  elif request.method == 'PUT':
    update = False

    try:
      user = User.objects.get(username=str(validated['steamid']))
      update = True
    except Exception as e:
      print(e)
      user = User.objects.create_user(username=str(validated['steamid']), is_active=False)
      user.ingame = str(validated['username'])

    if 'country' in validated:
      country = validated['country'].upper()
      if len(country) == 2:
        user.country = Country.objects.get_or_create(code=country)[0]

    if 'ip' in validated:
      if user.ip != validated['ip']:
        user.ip = validated['ip']

      if user.ip is not None:
        log, created = UserLogIP.objects.get_or_create(user=user, ip=user.ip)

        for l in UserLogIP.objects.filter(user=user, ip=user.ip, is_active=True):
          l.is_active = False
          l.save()

        log.is_active = True

        if 'connected' in validated:
          server = Server.objects.get(id=validated['server'])
          for ultime in UserLogTime.objects.filter(user=user, server=server, disconnected=None):
            ultime.disconnected = timezone.now()
            ultime.save()

          if validated['connected']:
            UserLogTime(user=user, server=server).save()
            log.connections += 1

        log.save()

    if 'connected' in validated:
      if validated['connected']:
        user.online = True
      else:
        user.online = False

    uname, created = UserLogUsername.objects.get_or_create(user=user, username=validated['username'])
    uname.connections += 1
    uname.save()

    user.ingame = validated['username']
    user.save()

    if update:
      return {'info': 'updated user', 'id': user.id}
    else:
      return {'info': 'created non panel accessible user', 'id': user.id}

    return {'id': user.id}


@csrf_exempt
@json_response
@authentication_required
@permission_required('user.detailed')
@validation('user.detailed')
@require_http_methods(['GET', 'POST', 'DELETE'])
def detailed(request, u=None, s=None, validated={}, *args, **kwargs):
  if request.method == 'GET':
    query = User.objects.annotate(has_panel_access=F('is_staff'),
                                  country_code=F('country__code'))

    if u is not None:
      try:
        user = query.annotate(steamid=None, name=F('username')).get(id=u)
      except Exception as e:
        return 'not existent user queried - {}'.format(e), 403

    if s is not None:
      user = query.annotate(steamid=F('username'), name=F('ingame')).get(username=s)
      user.steamid = int(user.steamid)
      try:
        pass
      except Exception as e:
        return 'not existent steamid provided - {}'.format(e), 403

    selected = ['id', 'ip', 'avatar', 'profile', 'permissions', 'steamid', 'name', 'circles', 'positions']
    if validated['server'] is not None:
      try:
        role = user.roles.get(server=Server.objects.get(id=validated['server']))
        user.flags = role.flags.convert()
        user.immunity = role.immunity
        user.usetime = role.usetime.total_seconds()
        selected.append('flags')
        selected.append('immunity')
        selected.append('usetime')
      except Exception as e:
        return 'serverrole does not exist for this user - {}'.format(e), 403

    user.permissions = [a.content_type.app_label + '.' + a.codename for a in user.user_permissions.all()]
    user.circles = [str(a) for a in user.groups.all()]
    user.positions = [{'server': None if a.server is None else a.server.id,
                       'flags': a.flags.convert(),
                       'immunity': a.immunity,
                       'usetime': None if a.usetime is None else a.usetime.total_seconds()
                       } for a in user.roles.all()]
    user = user.__dict__

    tmp = {}
    for k, i in user.items():
      if k in selected:
        tmp[k] = i

    user = tmp
    return user

  elif request.method == 'POST':
    if u is not None:
      try:
        user = User.objects.get(id=u)
      except Exception as e:
        return 'not existent user queried - {}'.format(e), 403

    if s is not None:
      try:
        user = User.objects.get(username=s)
      except Exception as e:
        if validated['force']:
          user = User.objects.create_user(username=str(s))
          user.save()

          steam_populate(user)

        else:
          return 'not existent steamid provided - {}'.format(e), 403

    if validated['role'] is not None:
      group = ServerGroup.objects.get(id=validated['role'])

      if validated['promotion']:
        user.roles.add(group)
      else:
        user.roles.remove(group)

    if validated['group'] is not None:
      group = Group.objects.get(id=validated['group'])
      if validated['promotion']:
        user.groups.add(group)
      else:
        user.groups.remove(group)

    return ':+1:'

  elif request.method == 'DELETE':
    if u is not None:
      try:
        user = User.objects.get(id=u)
      except Exception as e:
        return 'not existent user queried - {}'.format(e), 403

    if s is not None:
      try:
        user = User.objects.get(username=s)
      except Exception as e:
        return 'not existent steamid provided - {}'.format(e), 403

    if not user.is_active:
      return 'user not using panel'

    if validated['purge']:
      user.delete()

      return 'CASCADE DELETE', 200
    else:
      user.is_active = False
      user.is_staff = False
      user.is_superuser = False

      if validated['reset']:
        user.user_permissions.clear()
        user.groups.clear()

      user.save()

    return '+1'


# TESTING
@csrf_exempt
@json_response
@authentication_required
@permission_required('user.ban')
@validation('user.ban')
@require_http_methods(['GET', 'POST', 'PUT', 'DELETE'])
def ban(request, u=None, validated={}, *args, **kwargs):
  try:
    user = User.objects.get(id=u)
  except Exception as e:
    return 'non existent user queried - {}'.format(e), 403

  if request.method == 'GET':
    bans = Ban.objects.filter(user=user)
    if validated['server'] is not None:
      bans.filter(server=Server.objects.get(id=validated['server']))

    if validated['resolved'] is not None:
      bans.filter(resolved=validated['resolved'])

    return [b for b in bans.values('user', 'server', 'created_at', 'reason', 'resolved', 'issuer', 'length')], 200, UniPanelJSONEncoder

  elif request.method == 'POST':
    try:
      server = Server.objects.get(id=validated['server'])
    except Exception:
      return 'server not found', 500

    try:
      ban = Ban.objects.get(user=user, server=server)
    except Exception:
      return 'ban not found', 500

    if validated['resolved'] is not None:
      ban.resolved = validated['resolved']

    if validated['reason'] is not None:
      ban.reason = validated['reason']

    if validated['length'] is not None:
      ban.length = datetime.timedelta(seconds=validated['length'])

    ban.save()

  elif request.method == 'PUT':
    if 'server' in validated:
      server = Server.objects.get(id=validated['server'])
    else:
      server = None

    if validated['length'] > 0:
      length = datetime.timedelta(seconds=validated['length'])
    else:
      length = None

    ban = Ban(user=user, server=server, reason=validated['reason'], length=length)

    RConSourcemod(server).ban(ban)

  elif request.method == 'DELETE':
    server = Server.objects.get(id=validated['server'])
    ban = Ban.objects.get(user=user, server=server)
    ban.resolved = True

  return 'successful, nothing to report'


# TESTING
@csrf_exempt
@json_response
@authentication_required
@permission_required('user.mutegag')
@validation('user.mutegag')
@require_http_methods(['GET', 'PUT', 'DELETE', 'POST'])
def mutegag(request, u=None, validated={}, *args, **kwargs):
  try:
    user = User.objects.get(id=u)
  except Exception as e:
    return 'non existent user queried - {}'.format(e), 403

  if request.method == 'GET':
    mutegags = Mutegag.objects.filter(user=user)
    if validated['server'] is not None:
      mutegags.filter(server=Server.objects.get(id=validated['server']))

    if validated['resolved'] is not None:
      mutegags.filter(resolved=validated['resolved'])

    return [m for m in mutegags.values('user', 'issuer', 'created_at', 'reason', 'length', 'resolved', 'type')]

  elif request.method == 'POST':
    try:
      server = Server.objects.get(id=validated['server'])
    except Exception:
      return 'server not found', 500

    try:
      mutegag = Mutegag.objects.get(user=user, server=server)
    except Exception:
      return 'mute/gag not found', 500

    if validated['type'] is not None:
      if validated['type'] == 'mute':
        mutegag.type = 'MU'
      if validated['type'] == 'gag':
        mutegag.type = 'GA'
      if validated['type'] == 'both':
        mutegag.type = 'BO'

    if validated['resolved'] is not None:
      mutegag.resolved = validated['resolved']

    if validated['reason'] is not None:
      mutegag.reason = validated['reason']

    if validated['length'] is not None:
      mutegag.length = datetime.timedelta(seconds=validated['length'])

    mutegag.save()

  elif request.method == 'PUT':
    server = Server.objects.get(id=validated['server'])
    length = datetime.timedelta(seconds=validated['length'])

    if validated['type'] == 'mute':
      mutegag_type = 'MU'
    if validated['type'] == 'gag':
      mutegag_type = 'GA'
    if validated['type'] == 'both':
      mutegag_type = 'BO'

    mutegag = Mutegag(user=user, server=server, reason=validated['reason'], length=length, type=mutegag_type)

    RConSourcemod(server).mutegag(mutegag)

  elif request.method == 'DELETE':
    server = Server.objects.get(id=validated['server'])
    ban = Mutegag.objects.get(user=user, server=server)
    ban.resolved = True

  return 'successful, nothing to report'


# TESTING
@csrf_exempt
@json_response
@authentication_required
@permission_required('user.kick')
@validation('user.kick')
@require_http_methods(['PUT'])
def kick(request, u=None, validated={}, *args, **kwargs):
  try:
    user = User.objects.get(id=u)
  except Exception:
    return 'user not found', 500

  try:
    server = Server.objects.get(id=validated['server'])
  except Exception:
    return 'server not found', 500

  return RConSourcemod(server).kick(user=user, server=server)
