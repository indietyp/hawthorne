from django.contrib.auth.decorators import login_required, permission_required
from core.models import Server
from log.models import UserOnlineTime
from django.views.decorators.http import require_http_methods
from django.db.models.functions import Cast
from django.db.models import DateField, Count
from ajax.views import renderer
from rcon.sourcemod import RConSourcemod


def status(server):
  online = UserOnlineTime.objects.all()\
                                 .annotate(date=Cast('updated_at', DateField()))\
                                 .values('date')\
                                 .annotate(active=Count('user', distinct=True))

  return {'status': RConSourcemod(server).status(),
          'online': online}


@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def server(request, page, *args, **kwargs):
  obj = Server.objects.all()
  return renderer(request, 'partials/server/server.pug', obj, page, execute=status)
