import functools
import socket

from valve.rcon import RCON, RCONAuthenticationError, RCONTimeoutError, RCONError

from core.models import Server


class RCONBase(RCON):
  def __init__(self, server, timeout=None):
    if isinstance(server, str):
      server = Server.objects.get(id=server)

    self.server = server
    self.pwd = self.server.password
    self.addr = (self.server.ip, self.server.port)

    super(RCONBase, self).__init__(self.addr, self.pwd, timeout=timeout)

  def _ensure(state, value=True):
    def decorator(function):
      @functools.wraps(function)
      def wrapper(instance, *args, **kwargs):
        if getattr(instance, state) is not value:
          raise RCONError("Must {} {}".format(
            "be" if value else "not be", state))
        return function(instance, *args, **kwargs)

      return wrapper

    return decorator

  @_ensure('connected', False)
  @_ensure('closed', False)
  def connect(self):
    """Create a connection to a server."""
    self._socket = socket.socket(
      socket.AF_INET, socket.SOCK_STREAM, socket.IPPROTO_TCP)
    self._socket.settimeout(self._timeout)
    self._socket.connect(self._address)

  def run(self, command):
    output = []
    try:
      if isinstance(command, str):
        command = [command]

      self.connect()
      self.authenticate()
      for cmd in command:
        response = self.execute(cmd)
        output.append(response.text)

    except RCONAuthenticationError:
      pass
    except RCONTimeoutError:
      pass
    finally:
      self.close()

    return output
