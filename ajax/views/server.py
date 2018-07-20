import datetime
import json
import urllib.request

from django.contrib.auth.decorators import login_required, permission_required
from django.db.models import DateField, Count
from django.db.models.functions import Cast, Extract
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from django.shortcuts import render
from core.models import Server
from lib.sourcemod import SourcemodPluginWrapper
from log.models import UserOnlineTime


def status(server, *args, **kwargs):
  return SourcemodPluginWrapper(server).status(truncated=True)


@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def server(request, page, *args, **kwargs):
  obj = Server.objects.all()
  return renderer(request, 'components/servers/overview.pug', obj, page, execute=status)


@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def list(request, page, *args, **kwargs):
  obj = Server.objects.all()
  return renderer(request, 'components/servers/overview.pug', obj, page, execute=status, size=4, overwrite=True)


@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def overview(request, s, *args, **kwargs):
  now = datetime.datetime.now()
  server = Server.objects.get(id=s)

  query = UserOnlineTime.objects.annotate(day=Extract('disconnected', 'day'),
                                          month=Extract('disconnected', 'month'),
                                          year=Extract('disconnected', 'year'))

  month = []
  subquery = query.filter(month=now.month, year=now.year, server=server)\
                  .values('user', 'day')\
                  .annotate(active=Count('user', distinct=True))
  for day in range(1, now.day):
    month.append((day, subquery.filter(day=day).count()))

  ever = []
  subquery = query.filter(server=server)\
                  .values('user', 'year')\
                  .annotate(active=Count('user', distinct=True))
  for year in range(now.year - 2, now.year + 1):
    ever.append((year, subquery.filter(year=year).count()))

  loc = None

  with urllib.request.urlopen("https://geoip-db.com/jsonp/{}".format(server.ip)) as url:
    data = json.loads(url.read().decode().split("(")[1].strip(")"))

  loc = data['city']

  return render(request, 'components/servers/detailed/overview.pug', {'data': server,
                                                                      'months': month,
                                                                      'years': ever,
                                                                      'location': loc,
                                                                      'status': status(server)})


@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def log(request, s, *args, **kwargs):
  server = Server.objects.get(id=s)

  return render(request, 'components/servers/detailed/log.pug', {'data': server})



@login_required(login_url='/login')
@permission_required('core.view_server')
@require_http_methods(['POST'])
def rcon(request, s, *args, **kwargs):
  server = Server.objects.get(id=s)

  return render(request, 'components/servers/detailed/rcon.pug', {'data': server})
