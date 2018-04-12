"""API module for users"""

import datetime
import re

from django.contrib.auth.models import Group, Permission
from django.db.models import F, Q
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from core.lib.steam import populate as steam_populate
from core.models import User, Country, Server, ServerGroup, Ban, Mutegag, Membership
from lib.mainframe import Mainframe
from lib.sourcemod import SourcemodPluginWrapper


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

    selected = User.objects.annotate(steamid=F('username'), name=F('namespace'), has_panel_access=F('is_staff')) \
      .values('id', 'name', 'steamid', 'profile', 'has_panel_access') \
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

    if validated['steamid'] is not None:
      try:
        user = User.objects.get(username=str(validated['steamid']))
        update = True

      except User.DoesNotExist:
        user = User.objects.create_user(username=str(validated['steamid']))
        user.is_active = False
        user.is_steam = True

    elif validated['id'] is not None:
      user = User.objects.get(id=validated['id'])
      update = True

    elif validated['local']:
      user = User.objects.create_user(username=validated['email'])
      user.email = validated['email']
      user.is_steam = False

      with Mainframe() as mainframe:
        mainframe.invite(request, user)

    if validated['internal']:
      user.is_active = True
      user.is_staff = False

      base = Permission.objects if request.user.is_superuser else request.user.user_permissions
      exceptions = []
      perms = []
      for perm in validated['permissions']:
        perm = perm.split('.')
        p = base.filter(content_type__app_label=perm[0], codename=perm[1])

        if not p:
          exceptions.append('.'.join(perm))

        perms.extend(p)

      if exceptions:
        return {'info': 'You are trying to assign permissions that either do not exist or are out of your scope.', 'affects': exceptions}, 403

      user.save()
      user.user_permissions.set(perms)

      for group in Group.objects.filter(id__in=validated['groups']):
        user.groups.add(group)

    if validated['country'] is not None and len(validated['country']) == 2:
      country = validated['country'].upper()
      user.country = Country.objects.get_or_create(code=country)[0]

    if validated['ip'] is not None:
      user.ip = validated['ip']

    if validated['connected'] is not None:
      user.online = validated['connected']

      server = Server.objects.get(id=validated['server'])
      user._server = server

    # https://stackoverflow.com/questions/13729638/how-can-i-filter-emoji-characters-from-my-input-so-i-can-save-in-mysql-5-5
    try:
      # UCS-4
      highpoints = re.compile(u'[\U00010000-\U0010ffff]')
    except re.error:
      # UCS-2
      highpoints = re.compile(u'[\uD800-\uDBFF][\uDC00-\uDFFF]')

    if 'username' in validated:
      user.namespace = highpoints.sub(u'\u25FD', validated['username'])

    user.save()

    if update:
      return {'info': 'updated user', 'id': user.id}
    elif not update and validated['local']:
      return {'info': 'created panel accessible user', 'id': user.id}
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
    if u is not None:
      try:
        user = User.objects.get(id=u)
      except Exception as e:
        return 'not existent user queried - {}'.format(e), 403

    if s is not None:
      user = User.objects.get(username=s)
      try:
        pass
      except Exception as e:
        return 'not existent steamid provided - {}'.format(e), 403

    output = {'id': user.id,
              'ip': user.ip,
              'username': user.namespace if user.is_steam else user.username,
              'steamid': int(user.username) if user.is_steam else None,
              'avatar': user.avatar,
              'profile': user.profile,
              'permissions': [a.content_type.app_label + '.' + a.codename for a in user.user_permissions.all()],
              'groups': [str(a) for a in user.groups.all()],
              'roles': [],
              'has_panel_access': user.is_active,
              'country': None if user.country is None else user.country.code
              }

    memberships = user.membership_set.filter(user=user)
    if validated['server'] is not None:
      server = Server.objects.get(id=validated['server'])
      memberships.filter(Q(role__server=server) | Q(role__server=None))

    memberships = memberships.order_by('-role__immunity')

    if user.is_superuser:
      # fake root role
      output['roles'].append({'server': None,
                              'flags': 'ABCDEFGHIJKLN'.lower(),
                              'immunity': 100,
                              'usetime': None,
                              'timeleft': None
                              })

    for mem in memberships:
      usetime = None if mem.role.usetime is None else mem.role.usetime
      timeleft = None

      if usetime is not None:
        timeleft = (mem.created_at + usetime) - timezone.now()
        usetime = usetime.total_seconds()

        if timeleft < 0:
          mem.delete()
          continue

      output['roles'].append({'server': None if mem.role.server is None else mem.role.server.id,
                              'flags': mem.role.flags.convert().lower(),
                              'immunity': mem.role.immunity,
                              'usetime': usetime,
                              'timeleft': timeleft
                              })

    return output

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
        m = Membership()
        m.user = user
        m.role = group
        m.save()
      else:
        m = Membership.objects.get(user=user, role=group)
        m.delete()

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
      if not user.is_superuser:
        return 'superuser cannot be removed', 403

      if request.user == user:
        return 'you cannot disable yourself', 403

      user.delete()

      return 'CASCADE DELETE', 200

    elif validated['role'] is not None:
      m = Membership.objects.get(user=user, role=validated['role'])
      m.delete()
    else:
      if not user.is_superuser:
        return 'superuser cannot be deactivated', 403

      if request.user == user:
        return 'you cannot disable yourself', 403

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
      server = Server.objects.get(id=validated['server'])
      bans = bans.filter(Q(server=server) | Q(server=None))

    if validated['resolved'] is not None:
      bans = bans.filter(resolved=validated['resolved'])

    return [b for b in bans.annotate(admin=F('created_by__namespace'))
      .values('user', 'server', 'created_at', 'reason', 'resolved', 'created_by', 'length', 'admin')], 200

  elif request.method == 'POST':
    try:
      server = Server.objects.get(id=validated['server'])
    except Exception:
      return 'server not found', 500

    ban = Ban.objects.get(user=user, server=server)
    if validated['resolved'] is not None:
      ban.resolved = validated['resolved']

    if validated['reason'] is not None:
      ban.reason = validated['reason']

    if validated['length'] is not None:
      ban.length = datetime.timedelta(seconds=validated['length'])

    ban.updated_by = request.user
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

    ban = Ban(user=user, server=server, reason=validated['reason'], length=length, created_by=request.user)
    ban.save()

    return SourcemodPluginWrapper(server).ban(ban)

  elif request.method == 'DELETE':
    server = Server.objects.get(id=validated['server'])
    for ban in Ban.objects.filter(user=user, server=server):
      ban.resolved = True

      ban.save()

  return 'successful, nothing to report'


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

    return [m for m in mutegags.values('user', 'created_by', 'created_at', 'reason', 'length', 'resolved', 'type',
                                       'updated_by', 'updated_at')]

  elif request.method == 'POST':
    if 'server' in validated:
      try:
        server = Server.objects.get(id=validated['server'])
      except Exception:
        return 'server not found', 500
    else:
      server = None

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

    mutegag.updated_by = request.user
    mutegag.save()

  elif request.method == 'PUT':
    if 'server' in validated:
      server = Server.objects.get(id=validated['server'])
    else:
      server = None

    if validated['length'] > 0:
      length = datetime.timedelta(seconds=validated['length'])
    else:
      length = None

    if validated['type'] == 'mute':
      mutegag_type = 'MU'
    if validated['type'] == 'gag':
      mutegag_type = 'GA'
    if validated['type'] == 'both':
      mutegag_type = 'BO'

    mutegag = Mutegag(user=user, server=server, reason=validated['reason'], length=length, type=mutegag_type,
                      created_by=request.user)
    mutegag.save()

    SourcemodPluginWrapper(server).mutegag(mutegag)

  elif request.method == 'DELETE':
    server = Server.objects.get(id=validated['server'])
    mutegag = Mutegag.objects.get(user=user, server=server)
    mutegag.resolved = True
    mutegag.save()

  return 'successful, nothing to report'


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
    return 'user not found', 403

  try:
    server = Server.objects.get(id=validated['server'])
  except Exception:
    return 'server not found', 403

  return SourcemodPluginWrapper(server).kick(target=user)


@csrf_exempt
@json_response
@authentication_required
@permission_required('user.auth')
@validation('user.auth')
@require_http_methods(['GET'])
def auth(request, u=None, validated={}, *args, **kwargs):
  user = User.objects.filter(id=u)

  if user and user[0].check_password(validated['password']):
    return 'credentials are correct', 200

  return 'credentials not correct', 401
