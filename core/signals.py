import logging

from core.lib.steam import populate
from core.models import Server, User
from django.core.cache import cache
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.template.defaultfilters import slugify
from django.utils import timezone


logger = logging.getLogger(__name__)


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
  if not instance.namespace:
    if instance.is_steam:
      populate(instance, False)
    else:
      instance.namespace = instance.username

  from log.models import UserNamespace, UserOnlineTime, UserIP

  try:
    state = User.objects.get(id=instance.id)
  except User.DoesNotExist:
    return

  changelog = compare(state, instance)

  for l in UserIP.objects.filter(user=instance, ip=instance.ip, is_active=True):
    l.is_active = False
    l.save()

  namespaces = UserNamespace.objects.filter(user=instance, namespace=instance.namespace)
  if namespaces.count() > 1:
    namespaces.delete()

  namespace, created = UserNamespace.objects.get_or_create(user=instance,
                                                           namespace=instance.namespace)

  try:
    ip, created = UserIP.objects.get_or_create(user=instance, ip=instance.ip)
    ip.is_active = True
    iplog = True
  except Exception:
    iplog = False

  if 'online' in changelog and '_server' in instance.__dict__.keys():
    for disconnect in UserOnlineTime.objects.filter(user=instance,
                                                    server=instance._server,
                                                    disconnected=None):
      disconnect.disconnected = timezone.now()
      disconnect.save()

    if instance.online:
      online = UserOnlineTime(user=instance, server=instance._server)
      online.save()

      if iplog:
        ip.connections += 1
      namespace.connections += 1

  namespace.save()

  if iplog:
    ip.save()


@receiver(pre_save, sender=Server, weak=False)
def server_slug_handler(sender, instance, raw, using, update_fields, **kwargs):
  try:
    state = Server.objects.get(id=instance.id)
  except Server.DoesNotExist:
    state = None

  if state and state.name == instance.name:
    return

  instance.slug = slugify(instance.name)[:50]


@receiver(post_save, sender=Server, weak=False)
def refresh_cache(*args, **kwargs):
  cache.set('servers', Server.objects.all(), None)
