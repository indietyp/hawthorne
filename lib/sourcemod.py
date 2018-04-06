import datetime
import json

import valve.rcon

from core.lib.steam import populate
from core.models import User
from lib.base import RCONBase


class SourcemodPluginWrapper(RCONBase):
  def __init__(self, server):
    super(SourcemodPluginWrapper, self).__init__(server)

  def ban(self, ban, *args, **kwargs):
    command = 'rcon_ban "{}" "{}" "{}" "{}"'.format(ban.user.username,
                                                    ban.user.created_by,
                                                    ban.reason,
                                                    ban.length.total_seconds())

    try:
      response = self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}

    return response

  def kick(self, target, reason='', *args, **kwargs):
    try:
      response = self.run('sm_kick "#{}" "{}"'.format(target.username, reason))[0]
    except valve.rcon.RCONError as e:
      return {'error': e}

    return response

  def mutegag(self, mutegag, *args, **kwargs):
    command = 'rcon_mutegag__add "{}" "{}" "{}" "{}"'.format(mutegag.user.username,
                                                             mutegag.get_type_display(),
                                                             mutegag.reason,
                                                             mutegag.length.total_seconds())

    try:
      response = self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}

    return response

  def status(self, *args, **kwargs):
    try:
      response = self.run('json_status')[0]
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

    users = []
    for player in response['players']:
      try:
        user = User.objects.get(id=player['id'])
      except User.DoesNotExist:
        user = User.object.create_user(username=player['steamid'])
        user.is_active = False
        user.save()

        populate(user)

      users.append(user)

    response['players'] = users
    return response

  def execute(self, command, *args, **kwargs):
    try:
      return self.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}
