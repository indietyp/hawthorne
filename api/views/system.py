"""API interface for system specific actions"""

import datetime

from django.contrib.auth.models import Permission
from django.db.models import F
from django.http import HttpResponse
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from core.models import Punishment, Server, Token, User
from lib.sourcemod import SourcemodPluginWrapper
from log.models import ServerChat


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['GET', 'PUT'])
def chat(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    direction = '-created_at' if validated['descend'] else 'created_at'
    chats = ServerChat.objects.filter(message__contains=validated['match']) \
                              .values('ip', 'message', 'command', 'created_at') \
                              .order_by(direction) \
                              .annotate(user=F('user__id'), server=F('server__id'))

    limit = validated['limit']
    offset = validated['offset']
    chats = chats[offset:] if limit < 0 else chats[offset:limit]

    return [c for c in chats]
  elif request.method == 'PUT':
    chat = ServerChat()
    chat.user = User.objects.get(id=validated['user'])
    chat.server = Server.objects.get(id=validated['server'])
    chat.ip = validated['ip']
    chat.message = validated['message']

    # command == None is a best-guess effort
    if validated['command'] is None:
      chat.command = True if chat.message.startswith('sm_') or \
                             chat.message.startswith('rcon_') or \
                             chat.message.startswith('json_') else False
    else:
      chat.command = validated['command']

    chat.save()
    return 'passed'


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['GET', 'PUT'])
def token(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    tokens = Token.objects.all()
    if validated['active'] is not None:
      tokens = tokens.filter(is_active=validated['active'])

    if not request.user.is_superuser:
      tokens = tokens.filter(owner=request.user)

    output = []
    for t in tokens:
      perms = Permission.objects.all() if t.is_supertoken else t.permissions

      output.append({
          'id': t.id,
          'owner': t.owner.id,
          'created_at': t.created_at,
          'active': t.is_active,
          'due': t.due,
          'permissions': ["{}.{}".format(p.content_type.app_label, p.codename) for p in perms]
      })

    return output

  else:
    token = Token()
    token.is_active = validated['active']

    token.due = None
    if validated['due']:
      token.due = timezone.make_aware(datetime.datetime.fromtimestamp(validated['due']))

    token.owner = request.user

    base = Permission.objects.all()\
                             .annotate(encoded=F('content_type__model') + '.' + F('codename'))\
                             .filter(encoded__in=request.user.get_all_permissions())\
                             .order_by('content_type__model')
    exceptions = []
    perms = []
    for perm in validated['permissions']:
      perm = perm.split('.')
      p = base.filter(content_type__model=perm[0], codename=perm[1])

      if not p:
        exceptions.append('.'.join(perm))

      perms.extend(p)

    if exceptions:
      return {'info': 'You are trying to assign permissions you do not have yourself.', 'affects': exceptions}, 403

    token.save()
    token.permissions.set(perms)
    token.save()


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['GET', 'DELETE'])
def token_detailed(request, t=None, validated={}, *args, **kwargs):
  token = Token.objects.filter(id=t)

  if not token:
    return 'token does not exist', 403

  token = token[0]

  if request.method == 'GET':
    perms = Permission.objects.all() if token.is_supertoken else token.permissions

    return {
        'id': token.id,
        'owner': token.owner.id,
        'created_at': token.created_at,
        'active': token.is_active,
        'due': token.due,
        'permissions': ["{}.{}".format(p.content_type.app_label, p.codename) for p in perms]
    }
  else:
    token.delete()


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['POST'])
def authentication(request, validated={}, *args, **kwargs):
  from django.contrib.auth import authenticate
  user = authenticate(username=validated['username'], password=validated['password'])
  if user is not None:
      return [], 200
  else:
      return [], 401


@csrf_exempt
@authentication_required
@permission_required
@validation
@require_http_methods(['GET'])
def sourcemod_verification(request, validated={}, *args, **kwargs):
  target = request.COOKIES.get('id')
  if target and Punishment.objects.filter(is_banned=True, user__id=target, resolved=False):
    punishment = Punishment()
    punishment.user = User.objects.get(id=target)
    punishment.is_banned = True
    punishment.reason = "[Duplicate] This account has been detected as duplicate account."
    punishment.save()

    for s in Server.objects.all():
      SourcemodPluginWrapper(s).ban(punishment)

  response = HttpResponse("You are reading this?", content_type="text/plain")
  response.set_cookie(key='id', value=validated['target'])
  return response
