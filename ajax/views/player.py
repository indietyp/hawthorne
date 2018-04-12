from django.contrib.auth.decorators import login_required, permission_required
from django.db.models import F
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from core.models import User


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def user(request, page, *args, **kwargs):
  obj = User.objects.filter(online=True) \
                    .annotate(time=F('useronlinetime__disconnected')) \
                    .filter(time=None) \
                    .annotate(otime=F('useronlinetime__connected')) \
                    .annotate(server=F('useronlinetime__server')) \
                    .annotate(sname=F('useronlinetime__server__name')) \
                    .order_by('updated_at')
  return renderer(request, 'partials/player/online.pug', obj, page)
