import uuid

from django.contrib.auth.models import AbstractUser, Permission
from django.db import models


class BaseModel(models.Model):
  id = models.UUIDField(db_index=True, primary_key=True, auto_created=True, default=uuid.uuid4, editable=False, unique=True)
  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

  class Meta:
    abstract = True


class Tag(BaseModel):
  name = models.CharField(max_length=255, null=True)

  COLORS = (
      ("default", "Default Color"),
      ("teamcolor", "Current Team Color"),
      ("red", "Red"),
      ("lightred", "Lighter Red"),
      ("darkred", "Darker Red"),
      ("bluegrey", "Blueish Grey"),
      ("blue", "Blue"),
      ("darkblue", "Darker Blue"),
      ("purple", "Purple"),
      ("orchid", "Orchid"),
      ("yellow", "Yellow"),
      ("gold", "Gold"),
      ("lightgreen", "Lighter Green"),
      ("green", "Green"),
      ("lime", "Lime"),
      ("grey", "Grey"),
      ("darkgrey", "Darker Grey"),
  )

  # colors
  chat = models.CharField(max_length=10, choices=COLORS, default="default")
  name = models.CharField(max_length=10, choices=COLORS, default="default")

  # nametag
  base = models.CharField(max_length=10, choices=COLORS, default="default")


class Mainframe(BaseModel):
  assigned = models.UUIDField(null=True)
  token = models.UUIDField(null=True)

  domain = models.CharField(max_length=255, null=True)

  class Meta:
    permissions = [
        # ('view_mainframe', 'Can check mainframe'),
    ]


class Country(BaseModel):
  code = models.CharField(unique=True, max_length=2)
  name = models.CharField(max_length=100, null=True)

  class Meta:
    verbose_name = 'country'
    verbose_name_plural = 'countries'

    permissions = []
    default_permissions = ()

  def __str__(self):
    return self.code.upper()


class User(AbstractUser):
  id = models.UUIDField(db_index=True, primary_key=True, auto_created=True, default=uuid.uuid4, editable=False, unique=True)
  namespace = models.CharField(max_length=255, null=True)

  online = models.BooleanField(default=False)
  ip = models.GenericIPAddressField(null=True)

  roles = models.ManyToManyField('Role', through='Membership')
  country = models.ForeignKey(Country, on_delete=models.CASCADE, null=True)
  avatar = models.URLField(null=True)
  profile = models.URLField(null=True)

  is_steam = models.BooleanField(default=True)

  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

  tag = models.ForeignKey(Tag, on_delete=models.CASCADE, null=True)

  class Meta:
    permissions = [
        # ('view_user', 'Can view user'),
        ('kick_user', 'Can kick user'),
        # ('view_group', 'Can view user group'),

        ('view_settings', 'Can view settings'),
        ('view_capabilities', 'Can check capabilities'),
    ]

  def __str__(self):
    return "{} - {}".format(self.namespace, self.username)


class Token(BaseModel):
  owner = models.ForeignKey(User, on_delete=models.CASCADE)
  permissions = models.ManyToManyField(Permission)

  is_active = models.BooleanField(default=True)
  is_anonymous = models.BooleanField(default=False)
  is_supertoken = models.BooleanField(default=False)

  due = models.DateTimeField(null=True)

  class Meta:
    verbose_name = 'token'
    verbose_name_plural = 'tokens'

    permissions = [
        # ('view_token', 'Can view token'),
    ]

  def has_perm(self, perm, obj=None):
    if self.is_active and self.is_supertoken:
      return True

    perm = perm.split('.')

    try:
      self.permissions.get(codename=perm[-1], content_type__app_label=perm[0])
    except Exception:
      return False

    return True

  def __str__(self):
    return "({}) - {}".format(self.owner, self.id)


class ServerPermission(BaseModel):
  can_reservation = models.BooleanField(default=False, help_text='A')
  can_generic = models.BooleanField(default=False, help_text='B')
  can_kick = models.BooleanField(default=False, help_text='C')
  can_ban = models.BooleanField(default=False, help_text='DE')
  can_slay = models.BooleanField(default=False, help_text='F')
  can_map = models.BooleanField(default=False, help_text='G')
  can_config = models.BooleanField(default=False, help_text='H')
  can_cvar = models.BooleanField(default=False, help_text='I')
  can_chat = models.BooleanField(default=False, help_text='J')
  can_vote = models.BooleanField(default=False, help_text='K')
  can_password = models.BooleanField(default=False, help_text='L')
  can_rcon = models.BooleanField(default=False, help_text='M')
  can_cheat = models.BooleanField(default=False, help_text='N')

  can_custom_1 = models.BooleanField(default=False, help_text='O')
  can_custom_2 = models.BooleanField(default=False, help_text='P')
  can_custom_3 = models.BooleanField(default=False, help_text='Q')
  can_custom_4 = models.BooleanField(default=False, help_text='R')
  can_custom_5 = models.BooleanField(default=False, help_text='S')
  can_custom_6 = models.BooleanField(default=False, help_text='T')

  class Meta:
    default_permissions = ()
    permissions = ()

  def convert(self, conv=None):
    fields = {}
    tmp = self._meta.get_fields()
    for field in tmp:
      fields[field.name] = field

    if not conv:
      if 'role' in self.__dict__.keys() and self.role.is_supergroup:
        return 'Z'
      flags = []

      for field, value in self.__dict__.items():
        if field in fields and value is True:
          flags.append(fields[field].help_text)

      return ''.join(flags)
    else:
      conv = ''.join(sorted(set(conv.upper())))
      if 'role' in self.__dict__.keys() and self.role.is_supergroup:
        conv = 'ABCDEFGHIJKLMNOPQRST'

      for field in [x for x in self._meta.get_fields() if x.name.startswith('can')]:
        exec("self.{} = False".format(field.name))
        if field.help_text in conv:
          exec("self.{} = True".format(field.name))

      return self

  def __str__(self):
    return self.convert()


class Role(BaseModel):
  name = models.CharField(max_length=255)
  flags = models.OneToOneField(ServerPermission, on_delete=models.CASCADE)
  server = models.ForeignKey('Server', on_delete=models.CASCADE, null=True)
  tag = models.ForeignKey(Tag, on_delete=models.CASCADE, null=True)

  immunity = models.PositiveSmallIntegerField()
  usetime = models.DurationField(null=True)
  is_supergroup = models.BooleanField(default=False)

  class Meta:
    verbose_name = 'server role'
    verbose_name_plural = 'server roles'
    permissions = [
      # ('view_role', 'Can view server role'),
    ]

  def __str__(self):
    return self.name


class Server(BaseModel):
  name = models.CharField(max_length=255)
  slug = models.SlugField()

  ip = models.GenericIPAddressField()
  port = models.IntegerField()
  password = models.CharField(max_length=255)

  SUPPORTED = (
    ('csgo', 'Counter-Strike: Global Offensive'),
    ('tf2', 'Team Fortress 2'),
  )
  game = models.CharField(max_length=255, choices=SUPPORTED)
  mode = models.CharField(max_length=255, null=True)
  vac = models.BooleanField(default=True)

  class Meta:
    unique_together = (('ip', 'port'),)

    permissions = [
      # ('view_server', 'Can view server'),
      ('execute_server', 'Can execute command'),
    ]

  def __str__(self):
    return self.name


class Punishment(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE, null=True)

  reason = models.CharField(max_length=255)
  length = models.DurationField(null=True)
  resolved = models.BooleanField(default=False)

  is_banned = models.BooleanField(default=False)
  is_kicked = models.BooleanField(default=False)
  is_muted = models.BooleanField(default=False)
  is_gagged = models.BooleanField(default=False)

  created_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='punishment_created_by', null=True)
  updated_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='punishment_updated_by', null=True)

  class Meta:
    permissions = []

  def __str__(self):
    return "{} - {}".format(self.user, self.server)


class Membership(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  role = models.ForeignKey(Role, on_delete=models.CASCADE)

  class Meta:
    permissions = ()
    default_permissions = ()


from core.signals import user_log_handler
