from MySQLdb import connect
import valve
from valve.steam.id import SteamID
from django.utils import timezone
import socket
import datetime
from core.models import Server, ServerGroup, ServerPermission, User, Membership, Ban, Mutegag
from core.lib.steam import populate
from lib.base import RCONBase


class Importer:
  def __init__(self, host, port, user, password, database):
    self.conn = connect(host, user, password, database, port)
    self.now = datetime.datetime.now()

  def sourcemod(self):
    # get servers
    self.conn.query("""SELECT * FROM sb_servers""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    servers = {}
    for raw in result:
      if raw['enabled'] != 1:
        continue
      server, _ = Server.objects.get_or_create(ip=raw['ip'], port=raw['port'])
      server.password = raw['rcon']
      server.name = "{}:{}".format(raw['ip'], raw['port'])

      servers[raw['sid']] = server
      try:
        conn = RCONBase(server, timeout=3)
        conn.connect()
        conn.authenticate(timeout=3)
        conn.close()
      except (valve.rcon.RCONTimeoutError,
              valve.rcon.RCONAuthenticationError,
              ConnectionError,
              TimeoutError,
              socket.timeout) as e:

        server.delete()
        print("Warning: Could not connect to server {}:{} ({})".format(raw['ip'], raw['port'], e))
        continue

      server.save()

    # get groups
    self.conn.query("""SELECT * FROM sb_srvgroups""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    for raw in result:
      flags = ServerPermission().convert(raw['flags'])
      flags.save()
      role, _ = ServerGroup.objects.get_or_create(name=raw['name'], defaults={'flags': flags,
                                                                              'immunity': raw['immunity']})
      role.immunity = raw['immunity']
      role.flags = flags
      role.save()


    # get admins
    self.conn.query("""SELECT * FROM sb_admins""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    users = {0: User.objects.filter(is_superuser=True)[0]}
    generated = {}
    for raw in result:
      try:
        steamid = SteamID.from_text(raw['authid']).as_64()
      except:
        print("Could not add admin {}".format(raw['user']))
        continue

      query = User.objects.filter(username=steamid)

      if not query:
        user = User.objects.create_user(username=steamid)
        user.is_active = False
        user.is_steam = True

        populate(user)
      else:
        user = query[0]

      user.namespace = raw['user']
      user.save()

      if not raw['srv_group'] and raw['srv_flags']:
        m = Membership()
        m.user = user
        if raw['srv_flags'] in generated:
          m.role = generated[raw['srv_flags']]
        else:
          m.role = ServerGroup()
          m.role.immunity = 0
          m.role.name = raw['srv_flags']
          m.role.flags = ServerPermission().convert(raw['srv_flags'])
          m.role.flags.save()
          m.role.save()
          m.save()

          generated[raw['srv_flags']] = m.role

      elif raw['srv_group']:
        m = Membership()
        m.role = ServerGroup.objects.get(name=raw['srv_group'])
        m.user = user
        m.save()

      users[raw['aid']] = user


    # get bans
    self.conn.query("""SELECT * FROM sb_bans""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    for raw in result:
      if raw['aid'] not in users or raw['sid'] not in servers:
        continue

      try:
        steamid = SteamID.from_text(raw['authid']).as_64()
      except:
        print("Could not add ban of user {}".format(raw['name']))
        continue

      query = User.objects.filter(username=steamid)

      if not query:
        user = User.objects.create_user(username=steamid)
        user.is_active = False
        user.is_steam = True

        populate(user)
      else:
        user = query[0]

      b = Ban()
      b.user = user
      b.server = servers[raw['sid']] if raw['sid'] != 0 else None
      b.created_by = users[raw['aid']]
      m.created_at = timezone.make_aware(datetime.datetime.fromtimestamp(raw['created']))
      b.reason = raw['reason']
      b.length = datetime.timedelta(seconds=raw['length']) if raw['length'] != 0 else None
      b.resolved = False
      if raw['created'] + raw['length'] < self.now.timestamp() and raw['length'] != 0:
        b.resolved = True

      if raw['RemovedOn']:
        b.resolved = True
      b.save()

    # get comms
    self.conn.query("""SELECT * FROM sb_comms""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    for raw in result:
      if raw['aid'] not in users or raw['sid'] not in servers:
        continue

      try:
        steamid = SteamID.from_text(raw['authid']).as_64()
      except:
        print("Could not add mutegag of user {}".format(raw['name']))
        continue

      query = User.objects.filter(username=steamid)

      if not query:
        user = User.objects.create_user(username=steamid)
        user.is_active = False
        user.is_steam = True

        populate(user)
      else:
        user = query[0]

      m = Mutegag()
      m.user = user
      m.server = servers[raw['sid']] if raw['sid'] != 0 else None
      m.created_by = users[raw['aid']]
      m.created_at = timezone.make_aware(datetime.datetime.fromtimestamp(raw['created']))
      m.reason = raw['reason']
      m.length = datetime.timedelta(seconds=raw['length']) if raw['length'] != 0 else None
      m.type = 'MU' if raw['type'] == 1 else 'GA'

      m.resolved = False
      if raw['created'] + raw['length'] < self.now.timestamp() and raw['length'] != 0:
        m.resolved = True

      if raw['RemovedOn']:
        m.resolved = True

      m.save()

    return True

  def boompanel(self):
    self.conn.query("""SELECT * FROM bp_players""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    users = {}
    for raw in result:
      query = User.objects.filter(username=result['steamid'])
      if not query:
        user = User.objects.create_user(username=result['steamid'])
        user.is_active = False
        user.is_steam = True

        populate(user)
      else:
        user = query[0]
      user.save()

      users[result["id"]] = user

    self.conn.query("""SELECT * FROM bp_servers""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    servers = {}
    for raw in result:
      server, _ = Server.objects.get_or_create(ip=raw['ip'], port=raw['port'])
      server.password = raw['rcon_pw']
      server.name = raw['name']

      servers[raw['id']] = server
      try:
        conn = RCONBase(server, timeout=3)
        conn.connect()
        conn.authenticate(timeout=3)
        conn.close()
      except (valve.rcon.RCONTimeoutError,
              valve.rcon.RCONAuthenticationError,
              ConnectionError,
              TimeoutError,
              socket.timeout) as e:

        print("Warning: Could not connect to server {}:{} ({})".format(raw['ip'], raw['port'], e))
        continue

      server.save()

    self.conn.query("""SELECT * FROM bp_admin_groups""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    roles = {}
    for raw in result:
      role, _ = ServerGroup.objects.get_or_create(name=raw['name'])
      role.immunity = raw['immunity']
      role.flags = ServerPermission().convert(raw['flags'])
      role.usetime = None if raw['usetime'] == 0 else raw['usetime']
      role.save()

      roles[raw['id']] = role

    self.conn.query("""SELECT * FROM bp_admins""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    admins = {}
    for raw in result:
      m = Membership()
      m.role = roles[raw['sid']]
      m.user = roles[raw['pid']]
      m.save()

      admins[raw['aid']] = m

    self.conn.query("""SELECT * FROM bp_mutegag""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    for raw in result:
      if raw['aid'] not in users or raw['pid'] not in users or raw['sid'] not in servers:
        continue

      m = Mutegag()
      m.user = users[raw["pid"]]
      m.server = servers[raw['sid']] if raw['sid'] != 0 else None
      m.created_by = users[raw['aid']]
      m.created_at = timezone.make_aware(datetime.datetime.fromtimestamp(raw['time']))
      m.reason = raw['reason']
      m.length = datetime.timedelta(seconds=raw['length'] * 60) if raw['length'] != 0 else None
      m.type = 'MU' if raw['type'] == 1 else 'GA'

      m.resolved = False
      if raw['time'] + raw['length'] < self.now.timestamp() and raw['length'] != 0:
        m.resolved = True

      if raw['unbanned'] == 1:
        m.resolved = True
      m.save()

    self.conn.query("""SELECT * FROM bp_bans""")
    r = self.conn.store_result()
    result = r.fetch_row(maxrows=0, how=1)

    for raw in result:
      if raw['aid'] not in users or raw['pid'] not in users or raw['sid'] not in servers:
        continue

      b = Ban()
      b.user = users[raw["pid"]]
      b.server = servers[raw['sid']] if raw['sid'] != 0 else None
      b.created_by = users[raw['aid']]
      m.created_at = timezone.make_aware(datetime.datetime.fromtimestamp(raw['time']))
      b.reason = raw['reason']
      b.length = datetime.timedelta(seconds=raw['length']) if raw['length'] != 0 else None
      b.resolved = False
      if raw['time'] + raw['length'] < self.now.timestamp() and raw['length'] != 0:
        b.resolved = True

      if raw['unbanned'] == 1:
        b.resolved = True
      b.save()

    return True
