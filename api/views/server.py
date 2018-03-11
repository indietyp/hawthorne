import socket
from core.models import Server
from django.contrib.auth.hashers import make_password
from rcon.sourcemod import RConSourcemod
from django.views.decorators.csrf import csrf_exempt
from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from django.views.decorators.http import require_http_methods


@csrf_exempt
@json_response
@authentication_required
@permission_required('server.list')
@validation('server.list')
@require_http_methods(['GET', 'PUT'])
def list(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    server = Server.objects.filter(name__contains=validated['match']).values('id', 'name')

    if validated['ip'] is not None:
      server = server.filter(ip=validated['ip'])

    if validated['port'] is not None:
      server = server.filter(port=validated['port'])

    limit = validated['limit']
    offset = validated['offset']
    server = server[offset:] if limit < 0 else server[offset:limit]

    return [s for s in server]
  elif request.method == 'PUT':
    # resolve domain to ip
    server = Server()
    server.port = validated['port']
    server.ip = socket.gethostbyname(validated['ip'])
    server.name = validated['name']
    server.game = validated['game']

    # we don't want to have a plain one, but we need to. RCON does not hash pwds
    server.password = validated['password']
    if 'mode' in validated:
      server.mode = validated['mode']

    server.save()

    return ['passed']


@csrf_exempt
@json_response
@authentication_required
@permission_required('server.detailed')
@validation('server.detailed')
@require_http_methods(['POST', 'GET', 'DELETE'])
def detailed(request, validated={}, s=None, *args, **kwargs):
  server = Server.objects.get(id=s)

  if request.method == 'GET':
    # status = RConSourcemod(server).status()

    status = {}
    return {'adress': "{}:{}".format(server.ip, server.port),
            'name': server.name,
            'status': status}
  elif request.method == 'POST':
    # resolve domain into ip
    if validated['name'] is not None:
      server.name = validated['name']

    if validated['ip'] is not None:
      server.ip = validated['ip']

    if validated['port'] is not None:
      server.port = validated['port']

    if validated['password'] is not None:
      server.password = make_password(validated['password'])

    server.save()
  elif request.method == 'DELETE':
    server.delete()

  return 'passed'


@csrf_exempt
@json_response
@authentication_required
@permission_required('server.action')
@validation('server.action')
@require_http_methods(['PUT'])
def action(request, validated={}, s=None, *args, **kwargs):
  server = Server.objects.get(id=s)
  return RConSourcemod(server).execute(validated['command'])
