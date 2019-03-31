import datetime
import json
import urllib.request

from django.contrib.auth.decorators import login_required, permission_required
from django.db import connection
from django.db.models import Q
from django.db.models.deletion import Collector
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from core.models import Membership, Server, User
from django.shortcuts import render
from django.views.decorators.cache import cache_page
from log.models import ServerChat, ServerDataPoint


def status(server, *args, **kwargs):
  datapoints = ServerDataPoint.objects.filter(server=server).order_by('-created_at')

  dataset = [0] * 4 if not datapoints else [d.clients.count() for d in datapoints[:4]]
  datapoint = ServerDataPoint() if not datapoints else datapoints[0]

  return {'dataset': dataset, 'datapoint': datapoint}


@cache_page(60 * 15)
@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def modals(request, *args, **kwargs):
  servers = Server.objects.all()
  for server in servers:
    server.query = ServerDataPoint.objects.filter(server=server).order_by('-created_at')[0]

  return render(request, 'components/servers/modals/list.pug', {'data': servers})


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def list(request, page, *args, **kwargs):
  obj = Server.objects.all()
  return renderer(request, 'components/servers/overview.pug', obj, page,
                  execute=status, size=1, overwrite=True)


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def overview(request, s, *args, **kwargs):
  server = Server.objects.get(id=s)

  with connection.cursor() as cursor:
    cursor.execute('''
      SELECT AVG(`subquery`.`clients`), `subquery`.`hour`
      FROM (SELECT COUNT(`log_serverdatapoint_clients`.`user_id`) AS `clients`,
                   EXTRACT(HOUR FROM
                           CONVERT_TZ(`log_serverdatapoint`.`created_at`, 'UTC',
                                      'UTC'))                     AS `hour`
            FROM `log_serverdatapoint`
                   LEFT OUTER JOIN `log_serverdatapoint_clients`
                     ON (`log_serverdatapoint`.`id` =
                         `log_serverdatapoint_clients`.`serverdatapoint_id`)
            WHERE `log_serverdatapoint`.`server_id` = %s
            GROUP BY `log_serverdatapoint`.`id`
            ORDER BY NULL) `subquery`
      GROUP BY `subquery`.`hour`
      ORDER BY `subquery`.`hour`;
    ''', [server.id.hex])

    query = cursor.fetchall()

  hourly = {'labels': [str(x) for x in range(0, 24)], 'dataset': [0] * 24}
  for result in query:
    hourly['dataset'][result[1]] = float(result[0])

  with connection.cursor() as cursor:
    cursor.execute('''
      SELECT COUNT(`log_serverdatapoint_clients`.`user_id`) AS `clients`,
             CAST(`created_at` AS DATE)                        `created_date`
      FROM `log_serverdatapoint`
             LEFT OUTER JOIN `log_serverdatapoint_clients`
               ON (`log_serverdatapoint`.`id` =
                   `log_serverdatapoint_clients`.`serverdatapoint_id`)
      WHERE `log_serverdatapoint`.`server_id` = %s
      GROUP BY `created_date`
      ORDER BY `created_date` DESC
      LIMIT 365;
    ''', [server.id.hex])

    query = cursor.fetchall()

  daily = {}
  for result in query:
    date = datetime.datetime(result[1].year, result[1].month, result[1].day)
    daily[str(date.timestamp())] = result[0]

  loc = None
  with urllib.request.urlopen("https://geoip-db.com/json/{}".format(server.ip)) as url:
    data = json.loads(url.read().decode())
  loc = '{}, {}'.format(data['city'], data['country_name']) if data['city'] else data['country_name']

  return render(request, 'components/servers/detailed/overview.pug', {'data': server,
                                                                      'hourly': hourly,
                                                                      'daily': hourly,
                                                                      'location': loc,
                                                                      'status': status(server)})


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def log(request, s, *args, **kwargs):
  server = Server.objects.get(id=s)
  return render(request, 'components/servers/detailed/logs/wrapper.pug', {'data': server})


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def log_entries(request, s, page, *args, **kwargs):
  server = Server.objects.get(id=s)
  logs = ServerChat.objects.filter(server=server).order_by('-created_at')

  return renderer(request, 'components/servers/detailed/logs/entry.pug', logs, page)


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def rcon(request, s, *args, **kwargs):
  server = Server.objects.get(id=s)
  return render(request, 'components/servers/detailed/rcon.pug', {'data': server})


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def modal_players(request, s, *args, **kwargs):
  server = Server.objects.get(id=s)
  clients = ServerDataPoint.objects.filter(server=server).order_by('-created_at')

  if clients:
    clients = clients[0].clients.all()
  else:
    clients = []

  clients = User.objects.filter(namespace='indietyp', is_steam=True)

  return render(request, 'components/servers/detailed/modals/players.pug', {'data': clients})


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def modal_admins(request, s, *args, **kwargs):
  server = Server.objects.get(id=s)
  memberships = Membership.objects.filter(Q(role__server=server) | Q(role__server=None))

  return render(request, 'components/servers/detailed/modals/admins.pug', {'data': memberships})


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def modal_delete(request, s, *args, **kwargs):
  server = Server.objects.get(id=s)

  collector = Collector(using='default')
  collector.collect([server])
  estimate = sum(len(x) for x in collector.data.values())

  breakdown = {}
  for k, v in collector.data.items():
    name = k._meta.verbose_name_plural if len(v) != 1 else k._meta.verbose_name
    breakdown[name] = len(v)

  return render(request, 'components/servers/detailed/modals/delete.pug',
                {'estimate': estimate,
                 'breakdown': breakdown})
