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

  def ban(self, ban, *args, **kwargs):
    command = 'rcon_ban "{}" "{}" "{}" "{}"'.format(ban.user.username,
                                                    ban.created_by.namespace,
                                                    ban.reason,
                                                    ban.length.total_seconds() if ban.length else 0)

    try:
      response = self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}

    return response

  def kick(self, target, reason='powered by hawthorne', *args, **kwargs):
    try:
      response = self.run('sm_kick {} {}'.format(target.namespace, reason))[0]
    except valve.rcon.RCONError as e:
      return {'error': e}

    return response

  def mutegag(self, mutegag, *args, **kwargs):
    mode = mutegag.get_type_display()
    mode = 'un' + mode if mutegag.resolved else mode

    command = 'rcon_mutegag "{}" "{}" "{}" "{}"'.format(mutegag.user.username,
                                                        mode,
                                                        mutegag.length.total_seconds() if mutegag.length else 0,
                                                        mutegag.reason)

    try:
      response = self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}

    return response

  def status(self, truncated=False, *args, **kwargs):
    try:
      response = self.run('json_status')[0]
      response = response.split('\n')

      if regex.match(r'^L (.+) "json_status"$', response[-1]):
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

    if response['stats']['timeleft'] == -1:
      response['stats']['timeleft'] = None
    else:
      response['stats']['timeleft'] = datetime.timedelta(seconds=response['stats']['timeleft'])

    response['stats']['uptime'] = datetime.timedelta(seconds=response['stats']['uptime'])

    if truncated:
      response['stats']['map'] = response['stats']['map'].split('/')[-1]

    users = []
    for player in response['players']:
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

    response['players'] = users
    return response

  def execute(self, command, *args, **kwargs):
    try:
      return self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}
