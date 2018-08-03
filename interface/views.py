import json
import datetime
import calendar

from automated_logging.models import Model as LogModel
from django.db.models.functions import Extract
from lib.mainframe import Mainframe
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import Permission
from django.contrib.contenttypes.models import ContentType
from django.db.models import Count, Q, F, ExpressionWrapper, DateTimeField
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate
from django.http import JsonResponse
from django.utils import timezone
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

from core.models import Server, User, Punishment
from log.models import UserOnlineTime


def login(request):
  if request.method == "GET":
    return render(request, 'skeleton/login.pug', {})
  else:
    payload = json.loads(request.body)
    if authenticate(request, payload["username"], payload["password"]):
      return JsonResponse({"success": True})

    return JsonResponse({"success": False, "reason": "credentials incorrect or unkown"})


def setup(request, u=None):
  try:
    user = User.objects.get(id=u)
  except User.DoesNotExist:
    return redirect('/login')

  if user.username != user.email:
    return redirect('/login')

  if request.method == 'PUT':
    data = json.loads(request.body)

    if not data['username']:
      return JsonResponse({'setup': False, 'username': 'cannot be nothing'})

    user.namespace = data['username']
    user.username = data['username']

    try:
      validate_password(data['password'])
    except ValidationError as e:
      return JsonResponse({'setup': False, 'password': str(e)})

    user.set_password(data['password'])
    user.save()

    return JsonResponse({'setup': True})
  else:
    return render(request, 'skeleton/setup.pug', {'user': user})


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
  return render(request, 'pages/player.pug', {})


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
  return render(request, 'pages/admins/servers.pug')

@login_required(login_url='/login')
def admins_web(request):
  return render(request, 'pages/admins/web.pug')


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
  modules = [c for c in ContentType.objects.filter(app_label__in=['core', 'log']) if
             Permission.objects.filter(content_type=c).count() > 0]

  base = request.user.user_permissions if not request.user.is_superuser else Permission.objects
  perms = base.all().order_by('content_type__model')

  mainframe = Mainframe()
  mf = None

  if mainframe.check():
    mf = mainframe.populate().current.id

  return render(request, 'pages/settings.pug', {'simple': modules, 'advanced': perms, 'mainframe': mf, 'discord': None})
