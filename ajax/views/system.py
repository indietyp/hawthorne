from git import Repo
from django.shortcuts import render
from django.http import HttpResponse
from panel.settings import BASE_DIR
from django.views.decorators.http import require_http_methods
from django.contrib.auth.decorators import login_required, permission_required


@login_required(login_url='/login')
@permission_required('core.view_update')
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

