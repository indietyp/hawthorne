"""API module for users"""

import datetime
import re

from django.contrib.auth.models import Group, Permission
from django.db.models import F, Q, DateTimeField, ExpressionWrapper
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from core.lib.steam import populate as steam_populate
from core.models import User, Country, Server, ServerGroup, Punishment, Membership
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

    selected = User.objects.annotate(steamid=F('username'), name=F('namespace'), has_panel_access=F('is_active')) \
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

    if 'steamid' in validated:
      try:
        user = User.objects.get(username=str(validated['steamid']))
        update = True

      except User.DoesNotExist:
        user = User.objects.create_user(username=str(validated['steamid']))
        user.is_active = False
        user.is_steam = True

    elif 'id' in validated:
      user = User.objects.get(id=validated['id'])
      update = True

    elif 'local' in validated and validated['local']:
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
    elif not update and 'local' in validated and validated['local']:
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
      output['roles'].append({'name': 'root',
                              'server': None,
                              'flags': 'ABCDEFGHIJKLNMNOPQRSTUVXYZ'.lower(),
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

      output['roles'].append({'name': mem.role.name,
                              'server': None if not mem.role.server else mem.role.server.id,
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

    if validated['roles']:
      Membership.objects.filter(user=user).delete()

      for role in validated['roles']:
        group = ServerGroup.objects.get(id=role)
        m = Membership()
        m.user = user
        m.role = group
        m.save()

    if validated['groups']:
      groups = Group.objects.filter(id__in=validated['groups'])
      user.groups.set(groups)

    if validated['permissions'] is not None:
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

      user.user_permissions.set(perms)
      user.save()

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
      if user.is_superuser:
        return 'superuser cannot be removed', 403

      if request.user == user:
        return 'you cannot disable yourself', 403

      user.delete()

      return 'CASCADE DELETE', 200

    elif validated['role'] is not None:
      m = Membership.objects.get(user=user, role=validated['role'])
      m.delete()
    else:
      if user.is_superuser:
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


@csrf_exempt
@json_response
@authentication_required
@permission_required('user.punishment')
@validation('user.punishment')
@require_http_methods(['GET', 'POST', 'PUT', 'DELETE'])
def punishment(request, u=None, validated={}, *args, **kwargs):
  try:
    user = User.objects.get(id=u)
  except Exception as e:
    return 'non existent user queried - {}'.format(e), 403

  Punishment.objects.annotate(completion=ExpressionWrapper(F('created_at') + F('length'),
                                                    output_field=DateTimeField()))\
                     .filter(completion__lte=timezone.now(),
                             resolved=False,
                             length__isnull=False).update(resolved=True)

  if request.method == 'GET':
    punishments = Punishment.objects.filter(user=user)
    if validated['server'] is not None:
      server = Server.objects.get(id=validated['server'])
      punishments = punishments.filter(Q(server=server) | Q(server=None))

    if validated['resolved'] is not None:
      punishments = punishments.filter(resolved=validated['resolved'])

    if validated['muted'] is not None:
      punishments = punishments.filter(is_muted=validated['muted'])

    if validated['banned'] is not None:
      punishments = punishments.filter(is_banned=validated['banned'])

    if validated['gagged'] is not None:
      punishments = punishments.filter(is_gagged=validated['gagged'])

    if validated['kicked'] is not None:
      punishments = punishments.filter(is_kicked=validated['kicked'])

    return [p for p in punishments.annotate(admin=F('created_by__namespace'))
                                  .values('user',
                                          'server',
                                          'created_at',
                                          'reason',
                                          'resolved',
                                          'created_by',
                                          'length',
                                          'is_banned',
                                          'is_kicked',
                                          'is_muted',
                                          'is_gagged',
                                          'admin')], 200

  elif request.method == 'POST':
    try:
      server = Server.objects.get(id=validated['server'])
    except Exception:
      return 'server not found', 500

    punishment = Punishment.objects.get(user=user, server=server)
    if validated['resolved'] is not None:
      punishment.resolved = validated['resolved']

    if validated['reason'] is not None:
      punishment.reason = validated['reason']

    if validated['length'] is not None:
      punishment.length = datetime.timedelta(seconds=validated['length'])

    if validated['banned'] is not None:
      punishment.is_banned = validated['banned']

    if validated['kicked'] is not None:
      punishment.is_kicked = validated['kicked']

    if validated['muted'] is not None:
      punishment.is_muted = validated['muted']

    if validated['gagged'] is not None:
      punishment.is_gagged = validated['gagged']

    punishment.updated_by = request.user
    punishment.save()

  elif request.method == 'PUT':
    if 'server' in validated:
      server = Server.objects.get(id=validated['server'])
    else:
      server = None

    if validated['length'] > 0:
      length = datetime.timedelta(seconds=validated['length'])
    else:
      length = None

    punishment = Punishment(user=user,
                            server=server,
                            reason=validated['reason'],
                            is_muted=validated['muted'],
                            is_gagged=validated['gagged'],
                            is_kicked=validated['kicked'],
                            is_banned=validated['banned'],
                            length=length,
                            created_by=request.user)
    punishment.save()

    if validated['plugin']:
      server = [server] if server else Server.objects.all()
      for s in server:
        if punishment.is_gagged or punishment.is_muted:
          SourcemodPluginWrapper(s).mutegag(punishment)
        if punishment.is_banned:
          SourcemodPluginWrapper(s).ban(punishment)
        if punishment.is_kicked:
          punishment.resolved = True
          punishment.save()
          SourcemodPluginWrapper(s).kick(punishment)

  elif request.method == 'DELETE':
    if validated['server']:
      server = Server.objects.get(id=validated['server'])
    else:
      server = None

    punishments = Punishment.objects.filter(user=user, server=server, resolved=False)
    if validated['muted'] is not None:
      punishments = punishments.filter(is_muted=validated['muted'])

    if validated['banned'] is not None:
      punishments = punishments.filter(is_banned=validated['banned'])

    if validated['gagged'] is not None:
      punishments = punishments.filter(is_gagged=validated['gagged'])

    if validated['kicked'] is not None:
      punishments = punishments.filter(is_kicked=validated['kicked'])

    for punishment in punishments:
      punishment.resolved = True
      punishment.save()

      if validated['plugin']:
        server = [server] if server else Server.objects.all()

        for s in server:
          if punishment.is_gagged or punishment.is_muted:
            SourcemodPluginWrapper(s).mutegag(punishment)
          if punishment.is_banned:
            SourcemodPluginWrapper(s).ban(punishment)
          if punishment.is_kicked:
            SourcemodPluginWrapper(s).kick(punishment)

  return []
