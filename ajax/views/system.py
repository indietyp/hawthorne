from django.contrib.auth.decorators import login_required, permission_required
from django.http import HttpResponse
from django.shortcuts import render
from django.views.decorators.cache import cache_page
from django.views.decorators.http import require_http_methods
from git import Repo
from panel.settings import BASE_DIR


@cache_page(60 * 15)
@login_required
@permission_required('core.view_update', raise_exception=True)
@require_http_methods(['POST'])
def update(request, *args, **kwargs):
  repo = Repo(BASE_DIR)
  repo.git.fetch()

  current = repo.git.describe(abbrev=0, tags=True, match="v*")
  upstream = repo.git.describe('origin/master', abbrev=0, tags=True, match="v*")

  if current != upstream:
    return render(request, 'components/home/update.pug', {'current': current,
                                                          'upstream': upstream})
  else:
    return HttpResponse('')


@login_required
@permission_required('core.view_update', raise_exception=True)
@require_http_methods(['POST'])
def search(request, *args, **kwargs):
  # search for
  # --> User
  # --> Server

  return render(request, 'components/home/update.pug', {'current': '',
                                                        'upstream': ''})
