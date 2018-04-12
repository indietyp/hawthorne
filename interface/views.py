import json
import datetime

from automated_logging.models import Model as LogModel
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import Permission
from django.contrib.contenttypes.models import ContentType
from django.db.models import DateField, Count, Q
from django.db.models.functions import Cast
from django.shortcuts import render, redirect
from django.contrib.auth import authenticate
from django.http import JsonResponse
from django.contrib.auth.password_validation import validate_password

from core.models import Server, ServerGroup, User
from log.models import UserOnlineTime, ServerChat


def login(request):
  return render(request, 'skeleton/login.pug', {})


def setup(request, u=None):
  try:
    user = User.objects.get(id=u)
  except User.ObjectDoesNotExist:
    return redirect('/login')

  if user.username != user.email:
    return redirect('/login')

  if request.method == 'PUT':
    data = json.loads(request.body)

    user.namespace = data['username']
    user.username = data['username']
    user.set_password(data['password'])

    user.save()

    return redirect('/login')
  else:
    return render(request, 'skeleton/setup.pug', {'user': user})


@login_required(login_url='/login')
def home(request):
  query = UserOnlineTime.objects.annotate(date=Cast('disconnected', DateField())) \
    .values('user') \
    .annotate(active=Count('user', distinct=True))

  last30 = query.filter(date__gte=datetime.date.today() - datetime.timedelta(days=30))
  prev30 = query.filter(date__gte=datetime.date.today() - datetime.timedelta(days=60)) \
    .filter(date__lte=datetime.date.today() - datetime.timedelta(days=30))

  recent = last30.count()
  alltime = query.count()

  try:
    change = int((recent / prev30.count()) - 1) * 100
  except ZeroDivisionError:
    change = 100

  payload = {'instances': Server.objects.all().count(),
             'counts': {'all': alltime,
                        'month': recent,
                        'change': change},
             'roles': ServerGroup.objects.all().count(),
             'mem_roles': User.objects.filter(Q(roles__isnull=False) | Q(is_superuser=True)).count(),
             'messages': ServerChat.objects.filter(command=False)
               .annotate(date=Cast('created_at', DateField()))
               .filter(date__gte=datetime.date.today() - datetime.timedelta(days=30))
               .count(),
             'actions': LogModel.objects.filter(user__isnull=False)
               .annotate(date=Cast('created_at', DateField()))
               .filter(date__gte=datetime.date.today() - datetime.timedelta(days=30))
               .count()
             }
  return render(request, 'components/home.pug', payload)


@login_required(login_url='/login')
def player(request):
  return render(request, 'components/player.pug', {})


@login_required(login_url='/login')
def admin(request):
  return render(request, 'components/admin.pug', {})


@login_required(login_url='/login')
def server(request):
  return render(request, 'components/server.pug',
                {'supported': [{'label': x[1], 'value': x[0]} for x in Server.SUPPORTED]})


@login_required(login_url='/login')
def ban(request):
  return render(request, 'components/ban.pug', {})


@login_required(login_url='/login')
def mutegag(request):
  return render(request, 'components/mutegag.pug')


@login_required(login_url='/login')
def announcement(request):
  return render(request, 'components/home.pug', {})


@login_required(login_url='/login')
def chat(request):
  return render(request, 'components/chat.pug', {})


@login_required(login_url='/login')
def settings(request):
  modules = [c for c in ContentType.objects.filter(app_label__in=['core', 'log']) if
             Permission.objects.filter(content_type=c).count() > 0]

  base = request.user.user_permissions if not request.user.is_superuser else Permission.objects
  perms = base.all().order_by('content_type__model')

  return render(request, 'components/settings.pug', {'simple': modules, 'advanced': perms})


def dummy(request):
  return render(request, 'skeleton/main.pug', {})
