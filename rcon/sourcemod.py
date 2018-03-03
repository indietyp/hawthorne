from .__rcon import RCon


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
    return self.rcon.run('json_status')[0]

  def execute(self, *args, **kwargs):
    pass
