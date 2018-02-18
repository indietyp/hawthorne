from django.contrib.auth.decorators import login_required, permission_required
from core.models import Server
from django.views.decorators.http import require_http_methods
from ajax.views import renderer


@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def server(request, page, *args, **kwargs):
  obj = Server.objects.all()
  # CALL STATUS?
  return renderer(request, 'partials/server/server.pug', obj, page)
