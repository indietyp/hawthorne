import math
import datetime

from django.conf import settings
from django.contrib.auth.decorators import login_required, permission_required
from django.db.models import F, ExpressionWrapper, DurationField
from django.shortcuts import render
from django.views.decorators.http import require_http_methods
from django.http import Http404

from ajax.views import renderer
from core.models import User, Server
from log.models import UserOnlineTime, ServerChat


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def list(request, *args, **kwargs):
  current = request.POST.get("page", 1)
  pages = math.ceil(User.objects.filter(is_steam=True).count() / settings.PAGE_SIZE)

  return render(request, 'components/players/wrapper.pug', {'pages': pages,
                                                            'current': current})


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def list_entries(request, page, *args, **kwargs):
  players = User.objects.filter(is_steam=True)
  return renderer(request, 'components/players/entry.pug', players, page)


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def detailed_log(request, u, *args, **kwargs):
  current = request.POST.get("page", 1)
  pages = math.ceil(ServerChat.objects.filter(user=u).count() / settings.PAGE_SIZE)

  return render(request, 'components/players/detailed/logs/wrapper.pug',  {'pages': pages,
                                                                           'current': current})


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def detailed_log_entries(request, u, page, *args, **kwargs):
  logs = ServerChat.objects.filter(user=u)
  return renderer(request, 'components/players/detailed/logs/entry.pug', logs, page)


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def detailed_overview(request, u, *args, **kwargs):
  try:
    user = User.objects.get(id=u)
  except User.DoesNotExist:
    raise Http404('User does not exist')

  years = []
  months = []
  query = UserOnlineTime.objects.filter(user=user)\
                                .annotate(time=ExpressionWrapper(F('disconnected') - F('connected'),
                                                                 output_field=DurationField()))

  current = datetime.datetime.now()
  for year in range(current.year - 2, current.year + 1):
    sub = query.filter(disconnected__year=year)

    times = datetime.timedelta()
    for s in sub:
      times += s.time

    if sub:
      years.append([year, round(times.seconds / 3600)])
    else:
      years.append([year, 0])

  for day in range(1, current.day + 1):
    sub = query.filter(disconnected__year=current.year,
                       disconnected__month=current.month,
                       disconnected__day=day)

    times = datetime.timedelta()
    for s in sub:
      times += s.time

    formatting = datetime.datetime.now() - datetime.timedelta(days=day)
    formatting = formatting.strftime(settings.DATE_INPUT_FORMATS[0])
    if sub:
      months.append([formatting, round(times.seconds / 3600)])
    else:
      months.append([formatting, 0])

  activity = []
  for server in Server.objects.all():
    sub = query.filter(server=server)

    times = datetime.timedelta()
    for s in sub:
      times += s.time

    activity.append([server, times])

  games = {}
  for a in activity:
    if a[0].get_game_display() in games:
      games[a[0].get_game_display()] += a[1]
    else:
      games[a[0].get_game_display()] = a[1]

  activity = sorted(activity, reverse=True, key=lambda x: x[1].seconds)[0][0]
  games = sorted(games.items(), reverse=True, key=lambda x: x[1].seconds)[0][0]

  return render(request, 'components/players/detailed/overview.pug', {'data': user,
                                                                      'months': months,
                                                                      'years': years,
                                                                      'activity': activity,
                                                                      'games': games})
