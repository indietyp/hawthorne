from django.http import HttpResponseRedirect

from core.models import User


def get_user(backend, details, response, uid, user, *args, **kwargs):
  information = details['player']

  try:
    return {'user': User.objects.get(username=information['steamid'], is_active=True)}
  except Exception:
    return HttpResponseRedirect('/login?insufficient=1')
