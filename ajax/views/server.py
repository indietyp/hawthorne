import datetime

from django.contrib.auth.decorators import login_required, permission_required
from django.db.models import DateField, Count
from django.db.models.functions import Cast
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from core.models import Server
from lib.sourcemod import SourcemodPluginWrapper
from log.models import UserOnlineTime


def status(server, *args, **kwargs):
  query = UserOnlineTime.objects.filter(server=server) \
                                .annotate(date=Cast('disconnected', DateField()))

  last30 = query.filter(date__gte=datetime.date.today() - datetime.timedelta(days=30))
  online = last30.values('date') \
                 .annotate(active=Count('user', distinct=True)) \
                 .order_by('date')

  recent = last30.values('server').annotate(active=Count('user', distinct=True))
  alltime = query.values('server').annotate(active=Count('user', distinct=True))

  if len(online) > 1:
    online = [o for o in online]

    dpoint = online[0]['date']
    dbreak = datetime.date.today()
    included = [x['date'] for x in online]

    while dpoint < dbreak:
      dpoint += datetime.timedelta(days=1)

      if dpoint not in included:
        online.append({'date': dpoint, 'active': 0})

  else:
    online = [{'date': datetime.date.today(), 'active': 0}]

  online = sorted(online, key=lambda x: x['date'])

  if not recent:
    recent = [{'active': 0}]
  if not alltime:
    alltime = [{'active': 0}]

  return {'status': SourcemodPluginWrapper(server).status(truncated=True),
          'online': online,
          'count': {'last30': recent[0], 'ever': alltime[0]}}


@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def server(request, page, *args, **kwargs):
  obj = Server.objects.all()
  return renderer(request, 'partials/server/server.pug', obj, page, execute=status)


@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def list(request, page, *args, **kwargs):
  obj = Server.objects.all()
  return renderer(request, 'partials/home/instance.pug', obj, page, execute=status)
