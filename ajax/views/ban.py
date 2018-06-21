from django.contrib.auth.decorators import login_required, permission_required
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from core.models import Punishment


@login_required(login_url='/login')
@permission_required
@require_http_methods(['POST'])
def user(request, page, *args, **kwargs):
  obj = Punishment.objects.filter(resolved=False, is_banned=True).order_by('created_at')
  return renderer(request, 'partials/ban/user.pug', obj, page)
