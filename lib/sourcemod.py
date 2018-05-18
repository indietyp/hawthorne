import datetime
import json

import valve.rcon

from core.lib.steam import populate
from core.models import User
from lib.base import RCONBase
from log.models import UserOnlineTime


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
      print(response)
      response = response.split('\n')[0]
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
      try:
        user = User.objects.get(id=player['id'])
      except User.DoesNotExist:
        user = User.object.create_user(username=player['steamid'])
        user.is_active = False
        user.save()

        populate(user)

      usetime = UserOnlineTime.objects.filter(user=user, disconnected=None)[0]
      user.usetime = datetime.datetime.now() - usetime.connected
      users.append(user)

    response['players'] = users
    return response

  def execute(self, command, *args, **kwargs):
    try:
      return self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}
