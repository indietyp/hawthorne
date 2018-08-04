from django.conf import settings
from django.http import HttpResponseRedirect
from django.contrib.auth.models import Group

from core.models import User


def get_user(backend, details, response, uid, user, *args, **kwargs):
  information = details['player']

  try:
    return {'user': User.objects.get(username=information['steamid'], is_active=True)}
  except User.DoesNotExist:
    if settings.DEMO:
      user = User.objects.create_user(username=information['steamid'])
      user.namespace = information['personaname']
      user.is_active = True
      user.is_steam = True
      user.save()

      groups = Group.objects.filter(name='Demo')

      if groups:
        user.groups.add(*groups)
      user.save()

      return {'user': user}

    else:
      return HttpResponseRedirect('/login?insufficient=1')
