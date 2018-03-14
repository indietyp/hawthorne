from django.contrib.auth.decorators import login_required, permission_required
from core.models import Server
from log.models import UserOnlineTime
from django.views.decorators.http import require_http_methods
from django.db.models.functions import Cast
import datetime
from django.db.models import DateField, Count
from ajax.views import renderer
from rcon.sourcemod import RConSourcemod


def status(server):
  online = UserOnlineTime.objects.all()\
                                 .annotate(date=Cast('disconnected', DateField()))\
                                 .filter(date__gte=datetime.date.today() - datetime.timedelta(days=30))\
                                 .values('date')\
                                 .annotate(active=Count('user', distinct=True))\
                                 .order_by('date')

  if len(online) > 1:
    online = list(online)

    dpoint = online[0]['date']
    dbreak = datetime.date.today()
    pointer = 1

    while dpoint < dbreak:
      dpoint += datetime.timedelta(days=1)

      if len(online) <= pointer or dpoint != online[pointer]['date']:
        online.append({'date': dpoint, 'active': 0})

      pointer += 1

  else:
    online = [{'date': datetime.date.today(), 'active': 0}]

  online = sorted(online, key=lambda x: x['date'])

  return {'status': RConSourcemod(server).status(),
          'online': online}


@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def server(request, page, *args, **kwargs):
  obj = Server.objects.all()
  return renderer(request, 'partials/server/server.pug', obj, page, execute=status)
