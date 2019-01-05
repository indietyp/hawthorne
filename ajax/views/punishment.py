import math

from django.contrib.auth.decorators import login_required, permission_required
from django.shortcuts import render
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from core.models import Punishment
from django.conf import settings


@login_required(login_url='/login')
@permission_required('core.view_punishment')
@require_http_methods(['POST'])
def list(request):
  current = request.POST.get("page", 1)
  name = request.resolver_match.url_name
  punishments = Punishment.objects.all()

  if "ban" in name:
    punishments = punishments.filter(is_banned=True)
    mode = "ban"
  elif "mute" in name:
    punishments = punishments.filter(is_muted=True)
    mode = "mute"
  elif "gag" in name:
    punishments = punishments.filter(is_gagged=True)
    mode = "gag"

  pages = math.ceil(punishments.count() / settings.PAGE_SIZE)
  return render(request, 'components/punishments/wrapper.pug', {'pages': pages,
                                                                'current': current,
                                                                'mode': mode})


@login_required(login_url='/login')
@permission_required('core.view_punishment')
@require_http_methods(['POST'])
def entries(request, page):
  name = request.resolver_match.url_name
  punishments = Punishment.objects.all()

  if "ban" in name:
    punishments = punishments.filter(is_banned=True)
  elif "mute" in name:
    punishments = punishments.filter(is_muted=True)
  elif "gag" in name:
    punishments = punishments.filter(is_gagged=True)

  return renderer(request, 'components/punishments/entry.pug', punishments, page)
