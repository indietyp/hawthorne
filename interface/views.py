import calendar
import datetime
import json
import random

from automated_logging.models import Model as LogModel
from django.contrib.auth import authenticate
from django.contrib.auth.decorators import login_required
from django.db.models import Count, DateTimeField, ExpressionWrapper, F
from django.db.models.deletion import Collector
from django.db.models.functions import Extract
from django.http import Http404, JsonResponse
from django.shortcuts import render
from django.utils import timezone

from core.models import Punishment, Role, Server, User
from log.models import UserOnlineTime


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
  query = UserOnlineTime.objects.annotate(mo=Extract('disconnected', 'month'))\
                                .values('user', 'mo')\
                                .annotate(active=Count('user', distinct=True))

  population = []
  for month in range(current, current - 12, -1):
    if month < 1:
      month += 12

    population.append((calendar.month_abbr[month], query.filter(mo=month).count()))

  payload = {'population': population[::-1],
             'punishments': Punishment.objects.all().count(),
             'users': User.objects.all().count(),
             'servers': Server.objects.all().count(),
             'actions': LogModel.objects.all().count()}
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

  collector = Collector(using='default')
  collector.collect([server])
  estimate = sum(len(x) for x in collector.data.values())
  breakdown = {k._meta.verbose_name_plural if len(v) != 1 else k._meta.verbose_name: len(v) for k, v in collector.data.items()}
  return render(request, 'pages/servers/detailed.pug', {'data': server,
                                                        'estimate': estimate,
                                                        'breakdown': breakdown})


@login_required(login_url='/login')
def admins_servers(request):
  roles = Role.objects.all()
  return render(request, 'pages/admins/servers.pug', {'roles': roles})


@login_required(login_url='/login')
def admins_web(request):
  from django.contrib.auth.models import Permission

  permissions = Permission.objects.order_by('content_type__model')
  excluded = ['core', 'log', 'auth']
  return render(request, 'pages/admins/web.pug', {'permissions': permissions,
                                                  'excluded': excluded})


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

  return render(request, 'pages/punishments/general.pug', {'mode': mode})


@login_required(login_url='/login')
def settings(request):
  # modules = [c for c in ContentType.objects.filter(app_label__in=['core', 'log']) if
  #            Permission.objects.filter(content_type=c).count() > 0]

  # base = request.user.user_permissions if not request.user.is_superuser else Permission.objects
  # perms = base.all().order_by('content_type__model')

  # mainframe = Mainframe()
  # mf = None

  # if mainframe.check():
  #   mf = mainframe.populate().current.id

  return render(request, 'pages/settings.pug', {})


def page_not_found(request, exception=None, template_name='404.pug'):
  creatures = ['retarded', 'hot', 'crazed', 'embarrassed', 'worried', 'annoyed']
  return render(request, 'skeleton/errors/404.pug', {'creature': random.choice(creatures)})
