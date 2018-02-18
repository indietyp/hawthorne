import uuid
from django.db import models
from django.contrib.auth.models import AbstractUser, Permission


class BaseModel(models.Model):
  id = models.UUIDField(primary_key=True, auto_created=True, default=uuid.uuid4, editable=False, unique=True)
  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

  class Meta:
    abstract = True


class Country(BaseModel):
  code = models.CharField(unique=True, max_length=2)
  name = models.CharField(max_length=100, null=True)

  def __str__(self):
    return self.code.upper()


class User(AbstractUser):
  id = models.UUIDField(primary_key=True, auto_created=True, default=uuid.uuid4, editable=False, unique=True)
  ingame = models.CharField(max_length=255, null=True)

  online = models.BooleanField(default=False)
  ip = models.GenericIPAddressField(null=True)

  roles = models.ManyToManyField('ServerGroup')
  country = models.ForeignKey(Country, on_delete=models.CASCADE, null=True)
  avatar = models.URLField(null=True)
  profile = models.URLField(null=True)

  steam = models.BooleanField(default=True)

  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

  class Meta:
    permissions = [
        ('view_user', 'Can view users'),
        ('kick_user', 'Can kick a user'),
        ('view_group', 'Can view a user group'),
        # ('change_user', 'Can edit a user'),  # built-in
    ]

  def __str__(self):
    return "{} - {}".format(self.ingame, self.username)


class Token(BaseModel):
  owner = models.ForeignKey(User, on_delete=models.CASCADE)
  permissions = models.ManyToManyField(Permission)

  is_active = models.BooleanField(default=True)
  is_anonymous = models.BooleanField(default=False)
  is_superuser = models.BooleanField(default=False)

  def has_perm(self, perm, obj=None):
    if self.is_active and self.is_superuser:
        return True

    perm = perm.split('.')

    try:
      permission = self.permissions.get(codename=perm[-1])
    except Exception as e:
      print(e)
      return False

    if permission.content_type.app_label == perm[0]:
      return True

    return False

  def __str__(self):
    return "({}) - {}".format(self.owner, self.id)


class UserLogIP(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  ip = models.GenericIPAddressField()
  connections = models.IntegerField(default=0)

  active = models.BooleanField(default=False)
  last_used = models.DateTimeField(auto_now=True)

  def __str__(self):
    return "{} - {}".format(self.user, self.ip)


class UserLogTime(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey('Server', on_delete=models.CASCADE)

  connected = models.DateTimeField(auto_now_add=True)
  disconnected = models.DateTimeField(null=True)

  def __str__(self):
    return "{} - {}".format(self.user, self.server)


class UserLogUsername(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  username = models.CharField(max_length=128)

  connections = models.IntegerField(default=0)
  last_used = models.DateTimeField(auto_now=True)

  def __str__(self):
    return "{}".format(self.username)


class ServerPermission(BaseModel):
  can_reservation = models.BooleanField(default=False)
  can_generic = models.BooleanField(default=False)
  can_kick = models.BooleanField(default=False)
  can_ban = models.BooleanField(default=False)
  can_slay = models.BooleanField(default=False)
  can_map = models.BooleanField(default=False)
  can_config = models.BooleanField(default=False)
  can_cvar = models.BooleanField(default=False)
  can_chat = models.BooleanField(default=False)
  can_vote = models.BooleanField(default=False)
  can_password = models.BooleanField(default=False)
  can_rcon = models.BooleanField(default=False)
  can_cheat = models.BooleanField(default=False)

  def convert(self, conv=None):
    if conv is None:
      flags = []
      if self.can_reservation:
        flags.append('A')
      if self.can_generic:
        flags.append('B')
      if self.can_kick:
        flags.append('C')
      if self.can_ban:
        flags.append('D')
        flags.append('E')
      if self.can_slay:
        flags.append('F')
      if self.can_map:
        flags.append('G')
      if self.can_cvar:
        flags.append('H')
      if self.can_config:
        flags.append('I')
      if self.can_chat:
        flags.append('J')
      if self.can_vote:
        flags.append('K')
      if self.can_password:
        flags.append('L')
      if self.can_rcon:
        flags.append('M')
      if self.can_cheat:
        flags.append('N')

      return ''.join(flags)
    else:
      self.can_reservation = False
      self.can_generic = False
      self.can_kick = False
      self.can_ban = False
      self.can_slay = False
      self.can_map = False
      self.can_cvar = False
      self.can_config = False
      self.can_chat = False
      self.can_vote = False
      self.can_password = False
      self.can_rcon = False
      self.can_cheat = False

      for char in conv:
        if char in ['A']:
          self.can_reservation = True
        if char in ['B']:
          self.can_generic = True
        if char in ['C']:
          self.can_kick = True
        if char in ['D', 'E']:
          self.can_ban = True
        if char in ['F']:
          self.can_slay = True
        if char in ['G']:
          self.can_map = True
        if char in ['H']:
          self.can_cvar = True
        if char in ['I']:
          self.can_config = True
        if char in ['J']:
          self.can_chat = True
        if char in ['K']:
          self.can_vote = True
        if char in ['L']:
          self.can_password = True
        if char in ['M']:
          self.can_rcon = True
        if char in ['N']:
          self.can_cheat = True

      return self

  def __str__(self):
    return self.convert()


class ServerGroup(BaseModel):
  name = models.CharField(max_length=255)
  flags = models.OneToOneField(ServerPermission, on_delete=models.CASCADE)
  server = models.ForeignKey('Server', on_delete=models.CASCADE, null=True)

  immunity = models.PositiveSmallIntegerField()
  usetime = models.DurationField(null=True)
  is_admin = models.BooleanField(default=False)

  class Meta:
    permissions = [
        ('view_servergroup', 'Can view server groups'),
        # ('add_servergroup', 'Can add server groups'),
        # ('change_servergroup', 'Can edit server groups'),  # built-in
        # ('delete_servergroup', 'Can delete server groups'),
    ]

  def __str__(self):
    return self.name


class Server(BaseModel):
  name = models.CharField(max_length=255)
  ip = models.GenericIPAddressField()
  port = models.IntegerField()
  password = models.CharField(max_length=255)

  SUPPORTED = (
      ('csgo', 'Counter-Strike: Global Offensive'),
  )
  game = models.CharField(max_length=255, choices=SUPPORTED)
  mode = models.CharField(max_length=255, null=True)
  vac = models.BooleanField(default=True)

  class Meta:
    unique_together = (('ip', 'port'),)

    permissions = [
        ('view_server', 'Can view a server'),
        ('execute_server', 'Can view a server'),
        # ('add_server', 'Add a server'),  # built-in
        # ('change_server', 'Can edit a server'),  # built-in
        # ('delete_server', 'Delete a server')  # built-in
    ]

  def __str__(self):
    return self.name


class Ban(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  issuer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ban_issuer')

  reason = models.CharField(max_length=255)
  length = models.DurationField()
  resolved = models.BooleanField(default=False)

  class Meta:
    permissions = [
        ('view_ban', 'Can view a bans'),
        # ('add_ban', 'Add a ban'),  # built-in
        # ('change_ban', 'Can edit a ban'),  # built-in
        # ('delete_ban', 'Delete bans'),  # built-in
    ]

  def __str__(self):
    return "{} - {}".format(self.user, self.server)


class Chat(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)

  ip = models.GenericIPAddressField()
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  message = models.CharField(max_length=255)

  command = models.BooleanField(default=False)

  class Meta:
    permissions = [
        ('view_chat', 'Can view chat logs'),
        ('view_chat_ip', 'Can view ip of someone in chat logs'),
        ('view_chat_server', 'Can view current server of someone in chat logs'),
        ('view_chat_time', 'Can view current time of message in chat logs'),
    ]

  def __str__(self):
    return "{} - {}".format(self.user, self.server)


class Mutegag(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  issuer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mutegag_issuer')

  MUTEGAG_CHOICES = (
      ('MU', 'mute'),
      ('GA', 'gag'),
      ('BO', 'both')
  )
  type = models.CharField(max_length=2, choices=MUTEGAG_CHOICES, default='MU')

  reason = models.CharField(max_length=255)
  length = models.DurationField()
  resolved = models.BooleanField(default=False)

  class Meta:
    permissions = [
        ('view_mutegag', 'Can view a mutegag'),
        # ('add_mutegag', 'Add mutegags'),  # built-in
        ('add_mutegag_mute', 'Can add a mutegag mute'),
        ('add_mutegag_gag', 'Can add a mutegag gag'),
        # ('change_mutegag', 'Can edit a mutegag'),  # built-in
        # ('delete_mutegag', 'Delete mutegags'),  # built-in
    ]

  def __str__(self):
    return "{} - {}".format(self.user, self.server)


class Log(BaseModel):
  action = models.CharField(max_length=255)
  user = models.ForeignKey(User, on_delete=models.CASCADE)

  class Meta:
    permissions = [
        ('view_log', 'Can view a server logs')
    ]

  def __str__(self):
    return "{} - {}".format(self.user, self.action)
