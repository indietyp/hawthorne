import os

from django.http import HttpResponse
from django.shortcuts import render

from panel.settings import PAGE_SIZE


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


def renderer(request, template, obj, page, extra=[], execute=None, size=PAGE_SIZE, overwrite=False, bare=False):
  if execute is None:
    data = [o for o in obj[(page - 1) * size:page * size]]
  else:
    data = []

    for o in obj[(page - 1) * size:page * size]:
      try:
        o.executed = execute(o, request=request)
      except Exception as e:
        o.executed = []
        o.exception = e

      data.append(o)

  if page == 1:
    data.extend(extra)

  if len(data) > 0:
    if overwrite:
      return render(request, template, {'data': data})

    return render(request, 'skeleton/wrappers/pagination.pug', {'data': data,
                                                                'template': template})
  else:
    return HttpResponse('', status=416)
