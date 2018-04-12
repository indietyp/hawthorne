from django.conf import settings


def favicons(request):
  return {'favicon_sizes': ["16", "32", "57", "76", "120", "152", "196", "270"]}


def announcement(request):
  # this currently a dummy function
  return {'announcement': settings.DEBUG}
