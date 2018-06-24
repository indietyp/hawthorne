"""API interface for internal groups"""

from django.contrib.auth.models import Group, Permission
from django.forms.models import model_to_dict
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from core.models import User


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['GET', 'PUT'])
def list(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    groups = Group.objects.filter(name__contains=validated['match']).values('id', 'name')

    limit = validated['limit']
    offset = validated['offset']
    groups = groups[offset:] if limit < 0 else groups[offset:limit]

    return [g for g in groups]
  else:
    base = Permission.objects.all()\
                             .annotate(encoded=F('content_type__model') + '.' + F('codename'))\
                             .filter(encoded__in=request.user.get_all_permissions())\
                             .order_by('content_type__model')
    exceptions = []
    perms = []
    for perm in validated['permissions']:
      perm = perm.split('.')
      p = base.filter(content_type__app_label=perm[0], codename=perm[1])

      if not p:
        exceptions.append('.'.join(perm))

      perms.extend(p)

    if exceptions:
      return {'info': 'You are trying to assign permissions you do not have yourself.', 'affects': exceptions}, 403

    users = []
    for user in validated['members']:
      for u in User.objects.filter(id=user):
        users.append(u)

    group = Group(name=validated['name'])
    group.save()
    group.permissions.set(perms)
    group.user_set.set(users)
    group.save()

    return 'passed'


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['GET', 'POST', 'DELETE'])
def detailed(request, g=None, validated={}, *args, **kwargs):
  group = Group.objects.get(id=g)

  if request.method == 'GET':
    g = model_to_dict(group)
    g['members'] = [str(a.id) for a in group.user_set.all()]
    g['permissions'] = ["{}.{}".format(p.content_type.app_label, p.codename) for p in group.permissions.all()]

    return g

  elif request.method == 'POST':
    if validated['name'] is not None:
      group.name = validated['name']

    if len(validated['members']) > 0:
      users = []
      for m in validated['members']:
        try:
          users.append(User.objects.get(id=m))
        except Exception:
          continue
      group.user_set.set(users)

    if len(validated['permissions']) > 0:
      perms = []
      for p in validated['permissions']:
        p = p.split('.')
        try:
          perms.append(Permission.objects.get(content_type__app_label=p[0], codename=p[1]))
        except Exception:
          continue
      group.permissions.set(perms)

    group.save()

  elif request.method == 'DELETE':
    group.delete()

  return 'passed'
