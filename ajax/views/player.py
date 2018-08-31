import math

from django.conf import settings
from django.contrib.auth.decorators import login_required, permission_required
from django.shortcuts import render
from django.views.decorators.http import require_http_methods
from django.http import Http404

from ajax.views import renderer
from core.models import User


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def list(request, *args, **kwargs):
  current = request.POST.get("page", 1)
  pages = math.ceil(User.objects.filter(is_steam=True).count() / settings.PAGE_SIZE)

  return render(request, 'components/players/wrapper.pug', {'pages': pages,
                                                            'current': current})


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def list_entries(request, page, *args, **kwargs):
  players = User.objects.filter(is_steam=True)
  return renderer(request, 'components/players/entry.pug', players, page)


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def detailed_overview(request, u, *args, **kwargs):
  try:
    user = User.objects.get(id=u)
  except User.DoesNotExist:
    raise Http404('User does not exist')

  return render(request, 'components/players/detailed/overview.pug', {'data': user,
                                                                      'months': [],
                                                                      'years': []})
