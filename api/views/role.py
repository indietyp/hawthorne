import datetime
from core.models import User, Server, ServerGroup, ServerPermission
from django.forms.models import model_to_dict
from django.views.decorators.csrf import csrf_exempt
from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from django.views.decorators.http import require_http_methods


@csrf_exempt
@json_response
@authentication_required
@permission_required('role.list')
@validation('role.list')
@require_http_methods(['GET', 'PUT'])
def list(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    roles = ServerGroup.objects.filter(name__contains=validated['match']).values('id', 'name')

    limit = validated['limit']
    offset = validated['offset']
    roles = roles[offset:] if limit < 0 else roles[offset:limit]

    return [g for g in roles]
  else:
    users = []
    for user in validated['members']:
      for u in User.objects.filter(id=user):
        users.append(u)

    role = ServerGroup(name=validated['name'])

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
    role.user_set.set(users)
    role.save()

    return 'passed'


@csrf_exempt
@json_response
@authentication_required
@permission_required('role.detailed')
@validation('role.detailed')
@require_http_methods(['GET', 'POST', 'DELETE'])
def detailed(request, r=None, validated={}, *args, **kwargs):
  role = ServerGroup.objects.get(id=r)

  if request.method == 'GET':
    r = model_to_dict(role)
    r['members'] = [str(a.id) for a in role.user_set.all()]
    r['flags'] = role.flags.convert()

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
      role.usetime = datetime.timedelta(seconds=validated['usetime'])

    if validated['flags'] is not None:
      role.flags = role.flags.convert(validated['flags'])
      role.flags.save()

    role.save()

  elif request.method == 'DELETE':
    role.delete()

  return 'passed'
