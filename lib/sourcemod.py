import datetime
import json
import logging
import regex

import valve.rcon
from django.utils import timezone

from core.lib.steam import populate
from core.models import User
from lib.base import RCONBase
from log.models import UserOnlineTime


logger = logging.getLogger(__name__)


class SourcemodPluginWrapper(RCONBase):
  def __init__(self, server):
    super(SourcemodPluginWrapper, self).__init__(server)

  def ban(self, punishment, *args, **kwargs):
    command = 'rcon_ban "{}" "{}" "{}" "{}"'.format(punishment.user.username,
                                                    punishment.created_by.namespace,
                                                    punishment.reason,
                                                    punishment.length.total_seconds() if punishment.length else 0)

    try:
      response = self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}

    return response

  def kick(self, punishment, *args, **kwargs):
    try:
      response = self.run('sm_kick {} {}'.format(punishment.user.namespace,
                                                 punishment.reason))[0]
    except valve.rcon.RCONError as e:
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

    command = 'rcon_mutegag "{}" "{}" "{}" "{}"'.format(punishment.user.username,
                                                        mode,
                                                        punishment.length.total_seconds() if punishment.length else 0,
                                                        punishment.reason)

    try:
      response = self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}

    return response

  def status(self, truncated=False, *args, **kwargs):
    try:
      response = self.run('rcon_status')[0]
      logger.warning(response)
      logger.warning('\n' in response)

      response = response.split('\n')
      if response[-1] == "":
        response = response[:-1]

      if regex.match(r'^L (.+) "rcon_status"$', response[-1]):
        response[-1] = ""

      response = ''.join(response)
      logger.warning(response)
    except valve.rcon.RCONError as e:
      return {'error': e}

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
        user = User.object.create_user(username=player['steamid'])
        user.is_active = False
        user.save()

        populate(user)

      online = UserOnlineTime.objects.filter(user=user, disconnected=None)
      if online.count() > 1:
        user.usetime = timezone.now() - online[0].connected

      users.append(user)

    response['clients'] = users
    return response

  def execute(self, command, *args, **kwargs):
    try:
      return self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}
