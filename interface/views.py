import json
import datetime

from automated_logging.models import Model as LogModel
from django.db.models.functions import Extract
from lib.mainframe import Mainframe
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import Permission
from django.contrib.contenttypes.models import ContentType
from django.db.models import DateField, Count, Q, F, ExpressionWrapper, DateTimeField
from django.db.models.functions import Cast
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate
from django.http import JsonResponse
from django.utils import timezone
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

from core.models import Server, ServerGroup, User, Punishment
from log.models import UserOnlineTime, ServerChat


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
  query = UserOnlineTime.objects.annotate(m=Extract('created_at', 'month'))
                                # .values('user', 'month')
                                # .annotate(active=Count('user', distinct=True))

  print(query.query)
  print(query[0].m)

  # last30 = query.filter(date__gte=datetime.date.today() - datetime.timedelta(days=30))
  # prev30 = query.filter(date__gte=datetime.date.today() - datetime.timedelta(days=60)) \
  #               .filter(date__lte=datetime.date.today() - datetime.timedelta(days=30))

  # recent = last30.count()
  # alltime = query.count()

  # try:
  #   change = int((recent / prev30.count()) - 1) * 100
  # except ZeroDivisionError:
  #   change = 100

  payload = {}
  return render(request, 'pages/home.pug', payload)


@login_required(login_url='/login')
def player(request):
  return render(request, 'pages/player.pug', {})


@login_required(login_url='/login')
def admin(request):
  return render(request, 'pages/admin.pug', {})


@login_required(login_url='/login')
def server(request):
  return render(request, 'pages/server.pug',
                {'supported': [{'label': x[1], 'value': x[0]} for x in Server.SUPPORTED]})


@login_required(login_url='/login')
def ban(request):
  Punishment.objects.annotate(completion=ExpressionWrapper(F('created_at') + F('length'),
                                                           output_field=DateTimeField()))\
             .filter(completion__lte=timezone.now(),
                     resolved=False,
                     length__isnull=False)\
             .filter(Q(is_gagged=True) | Q(is_muted=True)).update(resolved=True)

  return render(request, 'pages/ban.pug', {})


@login_required(login_url='/login')
def mutegag(request):
  Punishment.objects.annotate(completion=ExpressionWrapper(F('created_at') + F('length'),
                                                           output_field=DateTimeField()))\
                    .filter(completion__lte=timezone.now(),
                            resolved=False,
                            length__isnull=False)\
                    .filter(Q(is_gagged=True) | Q(is_muted=True)).update(resolved=True)

  return render(request, 'pages/mutegag.pug')


@login_required(login_url='/login')
def announcement(request):
  return render(request, 'pages/home.pug', {})


@login_required(login_url='/login')
def chat(request):
  return render(request, 'pages/chat.pug', {})


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


def dummy(request):
  return render(request, 'skeleton/main.pug', {})
