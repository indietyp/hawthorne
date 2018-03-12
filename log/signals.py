from django.db.models.signals import pre_save
from django.dispatch import receiver
from core.models import User
from log.models import UserOnlineTime, UserIP, UserNamespace
from django.utils import timezone


# https://djangosnippets.org/snippets/2281/
def compare(state1, state2):
  d1, d2 = state1.__dict__, state2.__dict__
  included_keys = 'online', 'ip', 'namespace'

  changeset = []
  for k, v in d1.items():
    if k not in included_keys:
      continue
    try:
      if v != d2[k]:
        changeset.append(k)

    except KeyError:
      changeset.append(k)

  return changeset


@receiver(pre_save, sender=User, weak=False)
def user_log_handler(sender, instance, raw, using, update_fields, **kwargs):
  state = User.objects.get(id=instance.id)
  changelog = compare(state, instance)

  for l in UserIP.objects.filter(user=instance, ip=instance.ip, is_active=True):
    l.is_active = False
    l.save()

  namespace, created = UserNamespace.objects.get_or_create(user=instance, namespace=instance.namespace)
  ip, created = UserIP.objects.get_or_create(user=instance, ip=instance.ip)
  ip.is_active = True

  if 'online' in changelog and '_server' in instance.__dict__.keys():
    for disconnect in UserOnlineTime.objects.filter(user=state, server=instance._server, disconnected=None):
      disconnect.disconnected = timezone.now()
      disconnect.save()

    if instance.online:
      UserOnlineTime(user=instance, server=instance._server).save()
      ip.connections += 1
      namespace.connections += 1

  namespace.save()
  ip.save()
