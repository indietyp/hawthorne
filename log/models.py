from django.db import models
from core.models import User, BaseModel, Server


class ServerChat(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)

  ip = models.GenericIPAddressField()
  server = models.ForeignKey(Server, on_delete=models.CASCADE)
  message = models.CharField(max_length=255)

  command = models.BooleanField(default=False)

  class Meta:
    permissions = [
        ('view_chat', 'Can view chat log'),
        ('view_chat_ip', 'Can view ip in chat log'),
        ('view_chat_server', 'Can view server in chat log'),
        ('view_chat_time', 'Can view time in chat log'),
    ]

  def __str__(self):
    return "{} - {}".format(self.user, self.server)


class UserIP(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  ip = models.GenericIPAddressField()
  connections = models.IntegerField(default=0)

  is_active = models.BooleanField(default=False)
  last_used = models.DateTimeField(auto_now=True)

  def __str__(self):
    return "{} - {}".format(self.user, self.ip)

  class Meta:
    permissions = []
    default_permissions = ()


class UserOnlineTime(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  server = models.ForeignKey(Server, on_delete=models.CASCADE)

  connected = models.DateTimeField(auto_now_add=True)
  disconnected = models.DateTimeField(null=True)

  def __str__(self):
    return "{} - {}".format(self.user, self.server)

  class Meta:
    permissions = []
    default_permissions = ()


class UserNamespace(BaseModel):
  user = models.ForeignKey(User, on_delete=models.CASCADE)
  namespace = models.CharField(max_length=128)

  connections = models.IntegerField(default=0)
  last_used = models.DateTimeField(auto_now=True)

  class Meta:
    permissions = []
    default_permissions = ()

  def __str__(self):
    return "{}".format(self.namespace)


import log.signals
