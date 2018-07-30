from django.conf import settings
from core.models import Membership


def favicons(request):
  return {'favicon_sizes': ["16", "32", "57", "76", "120", "152", "196", "270"]}


def globals(request):
  return {'root': settings.ROOT}


def announcement(request):
  # this currently a dummy function
  return {'announcement': settings.DEBUG}


def role(request):
  if request.user.is_anonymous:
    return {'role': ''}

  if request.user.is_superuser:
    return {'role': settings.ROOT}

  memberships = Membership.objects.filter(user=request.user).order_by('-role__immunity')

  if memberships:
    return {'role': memberships[0].name}

  return {'role': '-'}
