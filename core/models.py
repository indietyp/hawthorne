import uuid
from django.db import models
from django.contrib.auth.models import AbstractUser


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
  steamid = models.CharField(max_length=17, null=True)
  country = models.ForeignKey(Country, on_delete=models.CASCADE, null=True)
  avatar = models.URLField(null=True)
  profile = models.URLField(null=True)


class AdminGroup(BaseModel):
  name = models.CharField(max_length=255)
  flags = models.CharField(max_length=25)

  immunity = models.DurationField()
  usetime = models.DurationField()
  isadmingroup = models.BooleanField(default=False)


class Flag(BaseModel):
  country = models.ForeignKey(Country, on_delete=models.CASCADE)
  icon = models.FileField(upload_to='flags/')

  priority = models.PositiveSmallIntegerField()

# class BpPanelAdminPermissions(BaseModel):
#   paneladmin = models.ForeignKey('BpPanelAdmins', db_column='paneladmin', blank=True, null=True)
#   permissionid = models.ForeignKey('BpPanelPermissions', db_column='permissionid', blank=True, null=True)


class PanelAdmin(BaseModel):
  steamid = models.CharField(unique=True, max_length=20, blank=True, null=True)


# class BpPanelPermissions(BaseModel):
#   permissionid = models.AutoField(primary_key=True)
#   name = models.CharField(unique=True, max_length=40)


class Server(BaseModel):
  name = models.CharField(max_length=255)
  ip = models.GenericIPAddressField()
  port = models.IntegerField()
  password = models.CharField(max_length=255)

  class Meta:
    unique_together = (('ip', 'port'),)


class UserIP(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  ip = models.GenericIPAddressField()
  connections = models.IntegerField(default=0)

  active = models.BooleanField(default=False)
  last_used = models.DateTimeField(auto_now=True)


class UserOnline(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  connected = models.DateTimeField(auto_now=True)
  disconnected = models.DateTimeField()


class PlayerUsername(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  username = models.CharField(max_length=128)
  connections = models.IntegerField()
  last_used = models.DateTimeField()


class Admin(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  group = models.ForeignKey(AdminGroup, on_delete=models.CASCADE)


class Ban(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  issuer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ban_issuer')

  reason = models.CharField(max_length=255)
  length = models.DurationField()
  resolved = models.BooleanField(default=False)


class Chat(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  message = models.CharField(max_length=255)

  command = models.BooleanField(default=False)


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

  reason = models.CharField(max_length=150)
  length = models.DurationField()
  resolved = models.BooleanField(default=False)
