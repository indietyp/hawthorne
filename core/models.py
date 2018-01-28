import uuid
from django.db import models
from django.contrib.auth.models import AbstractUser, Permission
from django.contrib.contenttypes.models import ContentType


class BaseModel(models.Model):
  id = models.UUIDField(primary_key=True, auto_created=True, default=uuid.uuid4, editable=False, unique=True)
  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

  class Meta:
    abstract = True


class Country(BaseModel):
  code = models.CharField(unique=True, max_length=2)
  name = models.CharField(max_length=100, null=True)


class User(AbstractUser):
  id = models.UUIDField(primary_key=True, auto_created=True, default=uuid.uuid4, editable=False, unique=True)
  # steamid = models.CharField(max_length=17, null=True)
  ingame = models.CharField(max_length=255, null=True)

  ip = models.GenericIPAddressField(null=True)

  country = models.ForeignKey(Country, on_delete=models.CASCADE, null=True)
  avatar = models.URLField(null=True)
  profile = models.URLField(null=True)

  steam = models.BooleanField(default=True)

  class Meta:
    permissions = [
        ('view_user', 'View users'),
        ('kick_user', 'Kick a user'),
        ('modify_user', 'Kick a user'),
        # ('search_user', 'Search for users'),
    ]


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
      application = ContentType.objects.get(id=permission.content_type.id)
    except Exception as e:
      print(e)
      return False

    if application.app_label == perm[0]:
      return True

    return False


class UserLogIP(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  ip = models.GenericIPAddressField()
  connections = models.IntegerField(default=0)

  active = models.BooleanField(default=False)
  last_used = models.DateTimeField(auto_now=True)


class UserLogTime(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey('Server', on_delete=models.CASCADE)

  connected = models.DateTimeField(auto_now_add=True)
  disconnected = models.DateTimeField()


class UserLogUsername(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  username = models.CharField(max_length=128)

  connections = models.IntegerField(default=0)
  last_used = models.DateTimeField(auto_now=True)


class PanelPermission(BaseModel):
  can_reservation = models.BooleanField(default=False)
  can_generic = models.BooleanField(default=False)
  can_ban = models.BooleanField(default=False)
  can_slay = models.BooleanField(default=False)
  can_map = models.BooleanField(default=False)
  can_cvar = models.BooleanField(default=False)
  can_vote = models.BooleanField(default=False)
  can_password = models.BooleanField(default=False)
  can_rcon = models.BooleanField(default=False)
  can_cheat = models.BooleanField(default=False)


class PanelGroup(BaseModel):
  name = models.CharField(max_length=255)
  flags = models.CharField(max_length=25)

  immunity = models.DurationField()
  usetime = models.DurationField()
  isadmingroup = models.BooleanField(default=False)

  permissions = models.OneToOneField(PanelPermission, on_delete=models.CASCADE)

  class Meta:
    permissions = [
        ('view_admin_group', 'View server groups'),
        ('add_admin_group', 'Add server groups'),
        ('modify_admin_group', 'Edit server groups'),
        ('delete_admin_group', 'Delete server groups'),
    ]


class Server(BaseModel):
  name = models.CharField(max_length=255)
  ip = models.GenericIPAddressField()
  port = models.IntegerField()
  password = models.CharField(max_length=255)

  class Meta:
    unique_together = (('ip', 'port'),)

    permissions = [
        ('view_server', 'View the servers'),
        # ('add_server', 'Add a server'),  # built-in
        ('modify_server', 'Edit a server'),
        # ('delete_server', 'Delete a server')  # built-in
    ]


class ServerRole(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  group = models.ForeignKey(PanelGroup, on_delete=models.CASCADE)

  class Meta:
    permissions = [
        ('view_admin_role', 'View server roles'),
        ('add_admin_role', 'Add server roles'),
        ('modify_admin_role', 'Edit server roles'),
        ('delete_admin_role', 'Delete server roles'),
    ]


class Ban(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  issuer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ban_issuer')

  reason = models.CharField(max_length=255)
  length = models.DurationField()
  resolved = models.BooleanField(default=False)

  class Meta:
    permissions = [
        ('view_ban', 'View bans'),
        # ('add_ban', 'Add a ban'),  # built-in
        ('modify_ban', 'Edit a ban'),
        # ('delete_ban', 'Delete bans'),  # built-in
    ]


class Chat(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)

  ip = models.GenericIPAddressField()
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  message = models.CharField(max_length=255)

  command = models.BooleanField(default=False)

  class Meta:
    permissions = [
        ('view_chat', 'View chat logs'),
        ('view_chat_ip', 'View ip of someone in chat logs'),
        ('view_chat_server', 'View current server of someone in chat logs'),
        ('view_chat_time', 'View current time of message in chat logs'),
    ]


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
        ('view_mutegag', 'View mutegags'),
        # ('add_mutegag', 'Add mutegags'),  # built-in
        ('add_mutegag_mute', 'Add mutegag mutes'),
        ('add_mutegag_gag', 'Add mutegag gags'),
        ('modify_mutegag', 'Edit mutegags'),
        # ('delete_mutegag', 'Delete mutegags'),  # built-in
    ]


class Log(BaseModel):
  action = models.CharField(max_length=255)
  user = models.ForeignKey(User, on_delete=models.CASCADE)

  class Meta:
    permissions = [
        ('view_admin_log', 'View server logs')
    ]
