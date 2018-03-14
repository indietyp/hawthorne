import valve.rcon
from core.models import Server


class RCon:
  def __init__(self, server):
    if isinstance(server, str):
      server = Server.objects.get(id=server)

    self.server = server
    self.pwd = self.server.password
    self.addr = (self.server.ip, self.server.port)

  def run(self, command):
    output = []
    with valve.rcon.RCON(self.addr, self.pwd) as rcon:
      # rcon.authenticate()
      if isinstance(command, str):
        command = [command]

      for cmd in command:
        response = rcon.execute(cmd)
        output.append(response.text)

    return output
