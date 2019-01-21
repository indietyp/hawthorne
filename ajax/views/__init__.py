import logging
import os

from django.http import HttpResponse
from django.shortcuts import render
from functools import partial
from multiprocessing import Pool, cpu_count

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


def wrapper(target, func=None, *args, **kwargs):
  try:
    target.executed = func(target, *args, **kwargs)
  except Exception as e:
    target.executed = []
    target.exception = e

  return target


def renderer(request, template, obj, page,
             extra=[], size=PAGE_SIZE, execute=None, overwrite=False):
  logger = logging.getLogger(__name__)
  logger.warning('HEY!')
  data = obj[(page - 1) * size:page * size]
  data = list(data)

  if execute and callable(execute):
    with Pool(cpu_count()) as p:
      target = partial(wrapper, func=execute, user=request.user)
      data = p.map(target, data)

  if page == 1:
    data.extend(extra)

  if len(data) > 0:
    if overwrite:
      return render(request, template, {'data': data})

    return render(request, 'skeleton/wrappers/pagination.pug', {'data': data,
                                                                'template': template})
  else:
    return HttpResponse('', status=416)
