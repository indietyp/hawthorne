from functools import wraps
from core.models import Token
from api.validation import validation as valid_dict


def token_retrieve(request):
  token = None
  if 'X_TOKEN' in request.META:
    token = request.META['X_TOKEN']
  elif 'HTTP_X_TOKEN' in request.META:
    token = request.META['HTTP_X_TOKEN']

  if token is not None:
    try:
      token = Token.objects.get(id=token, is_active=True, is_anonymous=False)
    except Exception:
      token = None

  return token


def authentication_required(f):
  def wrapper(request, *args, **kwargs):
    token = token_retrieve(request)
    if not request.user.is_authenticated and token is None:
      return 'Authentication of User failed', 401

    return f(request, *args, **kwargs)
  return wrapper


def permission_required(a):
  def argument_decorator(f):
    @wraps(f)
    def wrapper(request, *args, **kwargs):
      token = token_retrieve(request)
      perm = False
      validation = valid_dict

      target = a.split('.')
      for t in target:
        validation = validation[t]

      permissions = validation[request.method]['permission']
      if len(permissions) == 0:
        perm = True
      else:
        for p in permissions:
          if token is not None and token.has_perm(p):
            perm = True

          if token is None and request.user.has_perm(p):
            perm = True

      if not perm:
        return 'Insufficient Permissions', 403

      return f(request, *args, **kwargs)
    return wrapper
  return argument_decorator