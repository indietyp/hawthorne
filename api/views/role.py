"""API interface for server roles"""

import datetime

from django.forms.models import model_to_dict
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from core.models import User, Server, Role, ServerPermission, Membership

from lib.api import PropagationUtils


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['GET', 'PUT'])
def list(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    roles = Role.objects.filter(name__icontains=validated['match']).values('id', 'name', 'server')

    limit = validated['limit']
    offset = validated['offset']
    roles = roles[offset:] if limit < 0 else roles[offset:limit]

    return [g for g in roles]
  else:
    users = []
    for user in validated['members']:
      for u in User.objects.filter(id=user):
        users.append(u)

    role = Role(name=validated['name'])

    if validated['flags'] is not None:
      flags = validated['flags']
      permission = ServerPermission().convert(conv=flags)
    else:
      permission = ServerPermission()
    permission.save()

    role.flags = permission
    role.immunity = validated['immunity']

    if validated['server'] is not None:
      role.server = Server.objects.get(id=validated['server'])

    if validated['usetime'] is not None:
      role.usetime = datetime.timedelta(seconds=validated['usetime'])

    role.save()

    for u in users:
      m = Membership(user=u, role=role)
      m.save()

    PropagationUtils.announce_rebuild(role)

    return 'passed'


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['GET', 'POST', 'DELETE'])
def detailed(request, r=None, validated={}, *args, **kwargs):
  if str(r) == "00000000-0000-0000-0000-000000000000" and request.method == 'GET':
    role = None
  else:
    role = Role.objects.get(id=r)

  if request.method == 'GET':
    if role:
      r = model_to_dict(role)
      r['members'] = [str(a.id) for a in role.user_set.all()]
      r['flags'] = role.flags.convert()
    else:
      r = {
        'name': settings.ROOT,
        'flags': 'Z',
        'server': None,
        'tag': None,
        'immunity': 100,
        'usetime': None,
        'is_supergroup': True,
        'members': [u.id for u in User.objects.filter(is_superuser=True)]
      }

    return r

  elif request.method == 'POST':
    if validated['name'] is not None:
      role.name = validated['name']

    if len(validated['members']) > 0:
      users = []
      for m in validated['members']:
        try:
          users.append(User.objects.get(id=m))
        except Exception:
          continue
      role.user_set.set(users)

    if validated['immunity'] is not None:
      role.immunity = validated['immunity']

    if validated['server'] is not None:
      role.server = Server.objects.get(id=validated['server'])

    if validated['usetime'] is not None:
      if validated['usetime'] > 0:
        role.usetime = datetime.timedelta(seconds=validated['usetime'])
      else:
        role.usetime = None

    if validated['flags'] is not None:
      role.flags = role.flags.convert(validated['flags'])
      role.flags.save()

    role.save()

  elif request.method == 'DELETE':
    role.delete()

  PropagationUtils.announce_rebuild(role)
  return 'passed'
