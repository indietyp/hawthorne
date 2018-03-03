from django.db.models import F
from core.models import Log, Chat, User, Server
from django.views.decorators.csrf import csrf_exempt
from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from django.views.decorators.http import require_http_methods


@csrf_exempt
@json_response
@authentication_required
@permission_required('system.log')
@validation('system.log')
@require_http_methods(['GET', 'PUT'])
def log(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    direction = '-created_at' if validated['descend'] else 'created_at'
    logs = Log.objects.filter(action__contains=validated['match'])\
                      .values('action', 'created_at')\
                      .order_by(direction)\
                      .annotate(user=F('user__id'))

    limit = validated['limit']
    offset = validated['offset']
    logs = logs[offset:] if limit < 0 else logs[offset:limit]

    return [l for l in logs]
  elif request.method == 'PUT':
    log = Log(action=validated['action'], user=User.objects.get(id=validated['user']))
    log.save()

    return 'passed'


@csrf_exempt
@json_response
@authentication_required
@permission_required('system.chat')
@validation('system.chat')
@require_http_methods(['GET', 'PUT'])
def chat(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    direction = '-created_at' if validated['descend'] else 'created_at'
    chats = Chat.objects.filter(message__contains=validated['match'])\
                        .values('ip', 'message', 'command', 'created_at')\
                        .order_by(direction)\
                        .annotate(user=F('user__id'), server=F('server__id'))

    limit = validated['limit']
    offset = validated['offset']
    chats = chats[offset:] if limit < 0 else chats[offset:limit]

    return [c for c in chats]
  elif request.method == 'PUT':
    chat = Chat()
    chat.user = User.objects.get(id=validated['user'])
    chat.server = Server.objects.get(id=validated['server'])
    chat.ip = validated['ip']
    chat.message = validated['message']

    # command == None is a best-guess effort
    if validated['command'] is None:
      chat.command = True if chat.message.startswith('sm_') else False
    else:
      chat.command = validated['command']

    chat.save()
    return 'passed'
