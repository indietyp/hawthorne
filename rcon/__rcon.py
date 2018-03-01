import valve.rcon
from core.models import Server


class RCon:
  def __init__(self, server):
    if isinstance(server, str):
      server = Server.objects.get(id=server)

    self.server = server

  def run(self, command):
    pwd = self.server.password
    addr = (self.server.ip, self.server.port)

    output = []
    with valve.rcon.RCON(addr, pwd) as rcon:
      if isinstance(command, str):
        command = [command]

      for cmd in command:
        response = rcon(cmd)
        output.append(response)

    return output
