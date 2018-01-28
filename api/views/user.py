from core.models import User, Country, UserLogIP, UserLogTime, UserLogUsername
from django.views.decorators.csrf import csrf_exempt
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
    limit = validated['limit']
    offset = validated['offset']

    # TODO: add server role objects
    selected = User.objects.extra({'has_panel_access': 'is_staff'})\
                           .values('id', 'username', 'steamid', 'profile', 'has_panel_access')\
                           .filter(username__contains=validated['match'])

    output = []
    selected = selected[offset:] if limit < 0 else selected[offset:limit]

    for user in selected:
      output.append(user)

    return output

  elif request.method == 'PUT':
    print(validated)
    update = False

    try:
      user = User.objects.get(username=str(validated['steamid']))
      update = True
    except Exception as e:
      print(e)
      user = User.objects.create_user(username=validated['steamid'])
      user.ingame = str(validated['username'])
      user.is_active = False

    if 'country' in validated:
      country = validated['country'].upper()
      if len(country) == 2:
        user.country = Country.objects.get_or_create(code=country)[0]

    if 'ip' in validated:
      if user.ip is not None:
        log, created = UserLogIP.objects.get_or_create(user=user, ip=user.ip)

        for l in UserLogIP.objects.filter(user=user, ip=user.ip, active=True):
          l.active = False
          l.save()

        log.active = True
        if 'connected' in validated:
          # server = validated['server']
          # UserLogTime(user=user, server=server).save()
          log.connections += 1

        log.save()

      if user.ip != validated['ip']:
        user.ip = validated['ip']

    uname, created = UserLogUsername.objects.get_or_create(user=user, username=validated['username'])
    uname.connections += 1
    uname.save()
    user.username = validated['username']

    user.save()

    if update:
      return 'updated user'
    else:
      return 'created non panel accessible user'


@csrf_exempt
@json_response
@authentication_required
@permission_required('user.detailed')
@validation('user.detailed')
@require_http_methods(['GET', 'POST', 'DELETE'])
def detailed(request, u=None, s=None, validated={}, *args, **kwargs):
  pass


@csrf_exempt
@json_response
@authentication_required
@permission_required('user.ban')
@validation('user.ban')
@require_http_methods(['POST'])
def ban():
  pass


@csrf_exempt
@json_response
@authentication_required
@permission_required('user.mutegag')
@validation('user.mutegag')
@require_http_methods(['POST'])
def mutegag():
  pass


@csrf_exempt
@json_response
@authentication_required
@permission_required('user.kick')
@validation('user.kick')
@require_http_methods(['POST'])
def kick():
  pass


@csrf_exempt
@json_response
@authentication_required
@permission_required('user.s_perm')
@validation('user.s_perm')
@require_http_methods(['GET'])
def serverpermission():
  pass
