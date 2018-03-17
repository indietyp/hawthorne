from rcon.base import RCONBase
import json
import valve.rcon
from core.models import User
import datetime
from core.lib.steam import populate


class SourcemodPluginWrapper(RCONBase):
  def __init__(self, server):
    super(SourcemodPluginWrapper, self).__init__(server)

  def ban(self, *args, **kwargs):
    pass

  def kick(self, *args, **kwargs):
    pass

  def mutegag(self, mutegag, *args, **kwargs):
    pass

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
