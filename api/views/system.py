from django.db.models import F
from core.models import User, Server
from log.models import ServerChat
from django.views.decorators.csrf import csrf_exempt
from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from django.views.decorators.http import require_http_methods


@csrf_exempt
@json_response
@authentication_required
@permission_required('system.chat')
@validation('system.chat')
@require_http_methods(['GET', 'PUT'])
def chat(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    direction = '-created_at' if validated['descend'] else 'created_at'
    chats = ServerChat.objects.filter(message__contains=validated['match'])\
                              .values('ip', 'message', 'command', 'created_at')\
                              .order_by(direction)\
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
@permission_required('system.token')
@validation('system.token')
@require_http_methods(['GET', 'POST', 'PUT'])
def token(request, validated={}, *args, **kwargs):
  pass
