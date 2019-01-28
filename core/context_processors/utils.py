from core.models import Membership, Server
from django.conf import settings
from django.core.cache import cache


def favicons(request):
  return {'favicon_sizes': ["16", "32", "57", "76", "120", "152", "196", "270"]}


def globals(request):
  cached = cache.get_or_set('servers', Server.objects.all, None)

  return {'root': settings.ROOT,
          'games': Server.SUPPORTED,
          'servers': cached}


def announcement(request):
  # this currently a dummy function
  return {'announcement': settings.DEBUG}


def role(request):
  if request.user.is_anonymous:
    return {'role': ''}

  if request.user.is_superuser:
    return {'role': settings.ROOT}

  if request.user.groups.all():
    return {'role': request.user.groups.all()[0].name}

  return {'role': '-'}


def path(request):
  return {'path': request.path_info.split("/")[1:]}
