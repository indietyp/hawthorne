import datetime
import json
import logging
import regex

import valve.rcon

from django.utils import timezone

from core.lib.steam import populate
from core.models import User
from django.core.cache import cache
from lib.base import RCONBase
from log.models import UserConnection
from panel.settings import RCON_TIMEOUT


logger = logging.getLogger(__name__)


class SourcemodPluginWrapper(RCONBase):
  def __init__(self, server):
    super(SourcemodPluginWrapper, self).__init__(server, timeout=RCON_TIMEOUT)

  def ban(self, punishment, *args, **kwargs):
    command = 'rcon_ban "{}" "{}" "{}" "{}"'.format(punishment.user.username,
                                                    punishment.created_by.namespace,
                                                    punishment.reason,
                                                    punishment.length.total_seconds() if punishment.length else 0)

    try:
      response = self.run(command)[0]
    except (valve.rcon.RCONError, IndexError) as e:
      return {'error': e}

    return response

  def kick(self, punishment, *args, **kwargs):
    try:
      response = self.run('sm_kick {} {}'.format(punishment.user.namespace,
                                                 punishment.reason))[0]
    except (valve.rcon.RCONError, IndexError) as e:
      return {'error': e}

    return response

  def message(self, message, clients=[], kick=False, console=False, *args, **kwargs):
    if clients:
      selector = ''
      for client in clients:
        selector += client.username + '|'

      selector = selector[:-1]
    else:
      selector = '.*'

    # selector = '({})'.format(selector)  # dunno if needed w/ SourcePawn

    try:
      response = self.run('sm_message {} {} {} {}'.format(selector,
                                                          int(kick),
                                                          int(console),
                                                          message))[0]
    except (valve.rcon.RCONError, IndexError) as e:
      return {'error': e}

    return response

  def mutegag(self, punishment, *args, **kwargs):
    if punishment.is_gagged and punishment.is_muted:
      mode = 'silence'
    elif punishment.is_muted:
      mode = 'mute'
    elif punishment.is_gagged:
      mode = 'gag'
    else:
      return {'error': 'operation not supported'}

    mode = 'un' + mode if punishment.resolved else mode
    length = punishment.length.total_seconds() if punishment.length else 0

    command = 'rcon_mutegag "{}" "{}" "{}" "{}"'.format(punishment.user.username,
                                                        mode,
                                                        length,
                                                        punishment.reason)

    try:
      response = self.run(command)[0]
    except (valve.rcon.RCONError, IndexError) as e:
      return {'error': e}

    return response

  def status(self, truncated=False, *args, **kwargs):
    try:
      response = self.run('rcon_status')[0]

      response = response.split('\n')
      if response[-1] == "":
        response = response[:-1]

      if regex.match(r'^L (.+) "rcon_status"$', response[-1]):
        response[-1] = ""

      response = ''.join(response)
    except (valve.rcon.RCONError, IndexError) as e:
      return {'error': e.__class__.__name__}

    response = response.split('\n')[0]
    try:
      response = json.loads(response)
    except Exception:
      return {'error': 'could not load information', 'raw': response}

    if response['time']['left'] == -1:
      response['time']['left'] = None
    else:
      response['time']['left'] = datetime.timedelta(seconds=response['time']['left'])

    response['time']['up'] = datetime.timedelta(seconds=response['time']['up'])

    if truncated:
      response['map'] = response['map'].split('/')[-1]

    users = []
    for player in response['clients']:
      if not player['id']:
        continue

      try:
        user = User.objects.get(id=player['id'])
      except User.DoesNotExist:
        user = User.objects.create_user(username=player['steamid'])
        user.is_active = False
        user.is_steam = True
        user.save()

        populate(user)

      online = UserConnection.objects.filter(user=user, disconnected=None)\
                                     .order_by('-created_at')

      if online.count() > 0:
        user.usetime = timezone.now() - online[0].connected

      users.append(user)

    response['clients'] = users
    return response

  def raw(self, command, *args, **kwargs):
    try:
      return self.run(command)[0]
    except (valve.rcon.RCONError, IndexError) as e:
      return {'error': e}
