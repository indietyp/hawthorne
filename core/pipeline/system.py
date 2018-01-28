from core.models import User


def get_user(strategy, details, backend, user=None, *args, **kwargs):
  information = details['player']
  if not user:
    try:
      return {'user': User.objects.get(username=information['steamid'], is_active=True)}
    except Exception:
      return
