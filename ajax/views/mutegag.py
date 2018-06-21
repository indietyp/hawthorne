from django.contrib.auth.decorators import login_required, permission_required
from django.views.decorators.http import require_http_methods
from django.db.models import Q

from ajax.views import renderer
from core.models import Punishment


@login_required(login_url='/login')
@permission_required
@require_http_methods(['POST'])
def user(request, page, *args, **kwargs):
  obj = Punishment.objects.filter(resolved=False)\
                          .filter(Q(is_muted=True) | Q(is_gagged=True))\
                          .order_by('created_at')
  return renderer(request, 'partials/mutegag/user.pug', obj, page)
