import uuid
import random
import string
from django.db import models
from django.contrib.auth.models import AbstractUser, Permission


class BaseModel(models.Model):
  id = models.UUIDField(primary_key=True, auto_created=True, default=uuid.uuid4, editable=False, unique=True)

  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

  class Meta:
    abstract = True


class Plan(BaseModel):
  name = models.CharField(max_length=255)
  price = models.DecimalField(max_digits=5, decimal_places=2)


class User(AbstractUser):
  id = models.UUIDField(primary_key=True, auto_created=True, default=uuid.uuid4, editable=False, unique=True)

  plan = models.ForeignKey(Plan, on_delete=models.CASCADE, null=True)

  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

  class Meta:
    permissions = [
        ('view_user', 'Can view user'),
        ('view_capabilities', 'Can check capabilities'),
    ]


class DiscordGuild(BaseModel):
  identifier = models.CharField(max_length=255)


def generate_salt():
  out = []
  for _ in range(20):
    out.append(random.choice(string.ascii_letters))

  return ''.join(out)


class Mail(BaseModel):
  url = models.URLField()
  target = models.CharField(max_length=255, null=True)

  instance = models.ForeignKey('Instance', on_delete=models.CASCADE)


class Instance(BaseModel):
  ip = models.GenericIPAddressField()
  domain = models.CharField(max_length=255)

  name = models.CharField(max_length=255, null=True)
  owner = models.CharField(max_length=255, null=True)

  salt = models.CharField(max_length=20, default=generate_salt)


class Report(BaseModel):
  path = models.TextField()
  version = models.CharField(max_length=9)
  directory = models.CharField(max_length=255)

  instance = models.ForeignKey(Instance, on_delete=models.CASCADE)

  system = models.CharField(max_length=255)
  distribution = models.CharField(max_length=255)

  log = models.FileField(upload_to='logs/')


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
        ('view_token', 'Can view token'),
    ]

  def has_perm(self, perm, obj=None):
    if self.is_active and self.is_supertoken:
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
