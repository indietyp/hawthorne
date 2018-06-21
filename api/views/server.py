"""API interface for servers"""

import socket

import valve.rcon
from django.utils.translation import gettext_lazy as _
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from core.models import Server
from lib.base import RCONBase
from lib.sourcemod import SourcemodPluginWrapper


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
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
    try:
      ip = socket.gethostbyname(validated['ip'])
    except socket.gaierror as e:
      return _('Could not resolve host by domain ({0})').format(e), 500

    server = Server()
    server.port = validated['port']
    server.password = validated['password']
    server.ip = ip
    server.name = validated['name']
    server.game = validated['game']

    if validated['verify']:
      try:
        conn = RCONBase(server, timeout=3)
        conn.connect()
        conn.authenticate(timeout=3)
        conn.close()
      except valve.rcon.RCONTimeoutError:
        return _('Server timed out'), 500
      except valve.rcon.RCONAuthenticationError:
        return _('Could not authenticate with given password'), 500
      except ConnectionError as e:
        return _('Could not reach server ({0})').format(e), 500
      except TimeoutError as e:
        return _('Could not reach server ({0})').format(e), 500

    # we don't want to have a plain password, but we need to. RCON does not hash pwds
    server.password = validated['password']
    if 'mode' in validated:
      server.mode = validated['mode']

    server.save()

    return ['passed']


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['POST', 'GET', 'DELETE'])
def detailed(request, validated={}, s=None, *args, **kwargs):
  server = Server.objects.get(id=s)

  if request.method == 'GET':
    status = SourcemodPluginWrapper(server).status()

    return {'adress': "{}:{}".format(server.ip, server.port),
            'name': server.name,
            'status': status}

  elif request.method == 'POST':
    if validated['name'] is not None:
      server.name = validated['name']

    if validated['ip'] is not None:
      try:
        ip = socket.gethostbyname(validated['ip'])
      except socket.gaierror as e:
        return _('Could not resolve host by domain ({0})').format(e), 500
      server.ip = ip

    if validated['port'] is not None:
      server.port = validated['port']

    if validated['gamemode'] is not None:
      server.gamemode = validated['gamemode']

    if validated['password'] is not None:
      server.password = validated['password']

    if validated['verify']:
      try:
        conn = RCONBase(server, timeout=3)
        conn.connect()
        conn.authenticate(timeout=3)
        conn.close()
      except valve.rcon.RCONTimeoutError:
        return _('Server timed out'), 500
      except valve.rcon.RCONAuthenticationError:
        return _('Could not authenticate with given password'), 500
      except ConnectionError as e:
        return _('Could not reach server ({0})').format(e), 500
      except TimeoutError as e:
        return _('Could not reach server ({0})').format(e), 500
      except socket.timeout as e:
        return _('Could not reach server ({0})').format(e), 500

    server.save()

  elif request.method == 'DELETE':
    server.delete()

  return 'passed'


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['PUT'])
def action(request, validated={}, s=None, *args, **kwargs):
  server = Server.objects.get(id=s)
  return {'response': SourcemodPluginWrapper(server).execute(validated['command'])}
