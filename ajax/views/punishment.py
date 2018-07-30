import math

from django.contrib.auth.decorators import login_required, permission_required
from django.shortcuts import render
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from django.conf import settings
from core.models import Punishment


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def ban(request):
  current = request.POST.get("page", 1)

  pages = math.ceil(Punishment.objects.all().count() / settings.PAGE_SIZE)
  return render(request, 'components/punishments/bans/wrapper.pug', {'pages': pages,
                                                                     'current': current})


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def ban_entries(request, page):
  memberships = Punishment.objects.filter(is_banned=True)
  return renderer(request, 'components/punishments/bans/entry.pug', memberships, page)
