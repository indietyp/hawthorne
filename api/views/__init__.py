from django.http import JsonResponse
import os

__all__ = []
for file in os.listdir(os.path.dirname(os.path.realpath(__file__))):
  if file.endswith(".py") and file != '__init__.py':
    __all__.append(file[:-3])


def documentation(request):
  return JsonResponse({})
