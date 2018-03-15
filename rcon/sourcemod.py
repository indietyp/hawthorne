from .__rcon import RCon
import json
import valve.rcon
from core.models import User
import datetime


class RConSourcemod:
  def __init__(self, server):
    self.rcon = RCon(server)

  def ban(self, *args, **kwargs):
    pass

  def kick(self, *args, **kwargs):
    pass

  def mutegag(self, mutegag, *args, **kwargs):
    pass

  def status(self, *args, **kwargs):
    try:
      response = self.rcon.run('json_status')[0]
    except valve.rcon.RCONError as e:
      return {'error': e}

    print(response)
    try:
      response = json.loads(response)
    except:
      return {'error': 'could not load information', 'raw': response}

    if response['stats']['timeleft'] == -1:
      response['stats']['timeleft'] = None
    else:
      response['stats']['timeleft'] = datetime.timedelta(seconds=response['stats']['timeleft'])

    response['stats']['uptime'] = datetime.timedelta(seconds=response['stats']['uptime'])

    for player in response['players']:
      try:
        user = User.objects.get(id=player['id'])
      except User.DoesNotExist:
        user = User.object.creat_user(username=player['steamid'])
        user.is_active = False
        user.save()

      # process further

    return response

  def execute(self, command, *args, **kwargs):
    try:
      return self.rcon.run(command)[0]
    except valve.rcon.RCONError as e:
      return {'error': e}
