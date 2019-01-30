import calendar
import datetime
import json
import random

from automated_logging.models import Model as LogModel
from django.contrib.auth import authenticate
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import Group, Permission
from django.db import connection
from django.db.models import Count, DateTimeField, ExpressionWrapper, F, Subquery
from django.db.models.functions import Extract
from django.http import Http404, JsonResponse
from django.shortcuts import render
from django.utils import timezone

from core.models import Punishment, Role, Server, User
from log.models import UserConnection


def login(request):
  if request.method == "GET":
    return render(request, 'skeleton/login.pug', {})
  else:
    payload = json.loads(request.body)
    if authenticate(request, payload["username"], payload["password"]):
      return JsonResponse({"success": True})

    return JsonResponse({"success": False, "reason": "credentials incorrect or unkown"})


@login_required(login_url='/login')
def home(request):
  current = datetime.datetime.now().month

  # there seems to be now way to derive a django query from another one
  with connection.cursor() as cursor:
    cursor.execute('''
      SELECT COUNT(*), `subquery`.`mo`
      FROM (SELECT `log_userconnection`.`user_id` AS `Col1`,
                   EXTRACT(MONTH FROM CONVERT_TZ(`log_userconnection`.`disconnected`, 'UTC', 'UTC')) AS `mo`,
                   COUNT(DISTINCT `log_userconnection`.`user_id`) AS `active`
            FROM `log_userconnection`
            GROUP BY `log_userconnection`.`user_id`,
                     `mo`
            ORDER BY NULL) `subquery`
      GROUP BY `subquery`.`mo`;
    ''')

    query = cursor.fetchall()

  query = {i[1]: i[0] for i in query if i[1] is not None}

  population = []
  for month in range(current, current - 12, -1):
    if month < 1:
      month += 12

    value = 0 if month not in query else query[month]
    population.append((calendar.month_abbr[month], value))

  payload = {'population': population[::-1],
             'punishments': Punishment.objects.count(),
             'users': User.objects.count(),
             'servers': Server.objects.count(),
             'actions': LogModel.objects.count()}
  return render(request, 'pages/home.pug', payload)


@login_required(login_url='/login')
def player(request):
  return render(request, 'pages/players/list.pug', {})


@login_required(login_url='/login')
def player_detailed(request, u):
  try:
    user = User.objects.get(id=u)
  except User.DoesNotExist:
    raise Http404('This user is nowhere to be found!')

  return render(request, 'pages/players/detailed.pug', {'data': user})


@login_required(login_url='/login')
def server(request):
  return render(request, 'pages/servers/list.pug')


@login_required(login_url='/login')
def server_detailed(request, s):
  server = Server.objects.filter(id=s)

  if not server:
    return render(request, 'skeleton/404.pug')

  server = server[0]

  return render(request, 'pages/servers/detailed.pug', {'data': server})


@login_required(login_url='/login')
def admins_servers(request):
  roles = Role.objects.all()
  return render(request, 'pages/admins/servers.pug', {'roles': roles})


@login_required(login_url='/login')
def admins_web(request):
  permissions = Permission.objects.order_by('content_type__model')
  excluded = ['core', 'log', 'auth']
  groups = Group.objects.all()
  return render(request, 'pages/admins/web.pug', {'permissions': permissions,
                                                  'excluded': excluded,
                                                  'groups': groups})


@login_required(login_url='/login')
def punishments(request):
  name = request.resolver_match.url_name

  if "ban" in name:
    mode = "ban"
  elif "mute" in name:
    mode = "mute"
  elif "gag" in name:
    mode = "gag"

  Punishment.objects.annotate(completion=ExpressionWrapper(F('created_at') + F('length'),
                                                           output_field=DateTimeField()))\
                    .filter(completion__lte=timezone.now(),
                            resolved=False,
                            length__isnull=False).update(resolved=True)
  servers = Server.objects.all()

  return render(request, 'pages/punishments/general.pug', {'mode': mode,
                                                           'servers': servers})


@login_required(login_url='/login')
def settings(request):
  permissions = Permission.objects.order_by('content_type__model')
  excluded = ['core', 'log', 'auth']

  return render(request, 'pages/settings.pug', {'permissions': permissions,
                                                'excluded': excluded})


def page_not_found(request, exception=None, template_name='404.pug'):
  creatures = ['retarded', 'hot', 'crazed', 'embarrassed', 'worried', 'annoyed']
  return render(request, 'skeleton/errors/404.pug', {'creature': random.choice(creatures)})
