import os
from copy import deepcopy

from django.views.decorators.http import require_http_methods

from core.decorators.api import json_response


def walk(d, scope, answer=None, so_far=None):
  if so_far is None:
    so_far = []

  if answer is None:
    answer = []

  for k, v in d.items():
    if k == scope:
      answer.append(so_far + [k])
    if isinstance(v, dict):
      walk(v, scope, answer, so_far + [k])

  return answer


def delete_key(d, scope):
  for path in walk(d, scope):
    dd = d
    while len(path) > 1:
      dd = dd[path[0]]
      path.pop(0)
    dd.pop(path[0])


__all__ = []
for file in os.listdir(os.path.dirname(os.path.realpath(__file__))):
  if file.endswith(".py") and file != '__init__.py':
    __all__.append(file[:-3])


@json_response
@require_http_methods(['GET'])
def documentation(request, *args, **kwargs):
  from api import urls
  from api.validation import validation

  v = deepcopy(validation)
  delete_key(v, 'coerce')
  patterns = {}
  for pattern in urls.urlpatterns[1:]:
    patterns[pattern.name] = str(pattern.pattern)

  output = {}
  for k, i in patterns.items():
    try:
      tmp = v
      kl = k.split('.')

      for ki in kl:
        tmp = tmp[ki]

      output[patterns[k]] = tmp
    except Exception as e:
      print(e)

  return output
