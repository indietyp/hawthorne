import calendar
import datetime
import math

from automated_logging.models import Application as DALApplication, Model as DALModel
from django.conf import settings
from django.contrib.auth.decorators import login_required, permission_required
from django.db import connection
from django.db.models import Avg, DurationField, ExpressionWrapper, F
from django.db.models.fields import DateField
from django.db.models.functions import Cast, ExtractMonth, ExtractYear
from django.http import Http404, HttpResponse
from django.shortcuts import render
from django.utils.formats import date_format
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from core.models import Membership, Punishment, Server, User
from log.models import ServerChat, UserConnection, UserIP, UserNamespace


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def list(request, *args, **kwargs):
  current = request.POST.get("page", 1)
  pages = math.ceil(User.objects.filter(is_steam=True).count() / settings.PAGE_SIZE)

  return render(request, 'components/players/wrapper.pug', {'pages': pages,
                                                            'current': current})


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def list_entries(request, page, *args, **kwargs):
  players = User.objects.filter(is_steam=True)
  return renderer(request, 'components/players/entry.pug', players, page)


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def detailed_log(request, u, *args, **kwargs):
  c = request.POST.get("page", 1)
  pages = ServerChat.objects.filter(user=u)\
                            .annotate(created_date=Cast('created_at', DateField()))\
                            .values('created_date')\
                            .distinct()\
                            .order_by('-created_date')\
                            .count()

  return render(request, 'components/players/detailed/logs/wrapper.pug', {'pages': pages,
                                                                          'current': c})


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def detailed_log_date(request, u, date, *args, **kwargs):
  pages = ServerChat.objects.filter(user=u)\
                            .annotate(created_date=Cast('created_at', DateField()))\
                            .values('created_date')\
                            .distinct()\
                            .order_by('-created_date')

  return HttpResponse(date_format(pages[date - 1]['created_date'],
                                  format='SHORT_DATE_FORMAT',
                                  use_l10n=True))


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def detailed_log_entries(request, u, date, page, *args, **kwargs):
  pages = ServerChat.objects.filter(user=u)\
                            .annotate(created_date=Cast('created_at', DateField()))\
                            .values('created_date')\
                            .distinct()\
                            .order_by('-created_date')

  date = pages[date - 1]['created_date']
  logs = ServerChat.objects.annotate(created_date=Cast('created_at', DateField()))\
                           .filter(user=u, created_date=date).order_by('created_at')

  return renderer(request, 'components/players/detailed/logs/entry.pug', logs, page)


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def detailed_actions(request, u, *args, **kwargs):
  c = request.POST.get("page", 1)

  application = DALApplication.objects.get(name='core')
  pages = math.ceil(DALModel.objects.filter(user=u, application=application).count() / settings.PAGE_SIZE)

  return render(request, 'components/players/detailed/actions/wrapper.pug', {'pages': pages,
                                                                             'current': c})


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def detailed_actions_entries(request, u, page, *args, **kwargs):
  application = DALApplication.objects.get(name='core')
  logs = DALModel.objects.filter(user=u, application=application).order_by('created_at')

  return renderer(request, 'components/players/detailed/actions/entry.pug', logs, page)


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def detailed_punishments(request, u, *args, **kwargs):
  c = request.POST.get("page", 1)
  pages = math.ceil(Punishment.objects.filter(user=u).count() / settings.PAGE_SIZE)

  return render(request, 'components/players/detailed/punishments/wrapper.pug', {'pages': pages,
                                                                                 'current': c})


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def detailed_punishments_entries(request, u, page, *args, **kwargs):
  punishments = Punishment.objects.filter(user=u).order_by('created_at')

  return renderer(request, 'components/players/detailed/punishments/entry.pug', punishments, page)


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def modal_usernames(request, u, *args, **kwargs):
  user = User.objects.get(id=u)
  log = UserNamespace.objects.filter(user=user).order_by('-updated_at')

  return render(request, 'components/players/detailed/modals/usernames.pug', {'data': log})


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def modal_roles(request, u, *args, **kwargs):
  user = User.objects.get(id=u)
  mems = Membership.objects.filter(user=user)

  return render(request, 'components/players/detailed/modals/roles.pug', {'data': mems})


@login_required
@permission_required('core.view_server', raise_exception=True)
@require_http_methods(['POST'])
def modal_ips(request, u, *args, **kwargs):
  user = User.objects.get(id=u)
  log = UserIP.objects.filter(user=user).order_by('-updated_at')

  return render(request, 'components/players/detailed/modals/ips.pug', {'data': log})


@login_required
@permission_required('core.view_user', raise_exception=True)
@require_http_methods(['POST'])
def detailed_overview(request, u, *args, **kwargs):
  try:
    user = User.objects.get(id=u)
  except User.DoesNotExist:
    raise Http404('User does not exist')

  with connection.cursor() as cursor:
    cursor.execute('''
      SELECT COUNT(*), `subquery`.`mo`, `subquery`.`da`, `subquery`.`ye`
      FROM (SELECT `log_userconnection`.`user_id` AS `Col1`,
                   EXTRACT(YEAR FROM CONVERT_TZ(`log_userconnection`.`disconnected`, 'UTC', 'UTC'))  AS `ye`,
                   EXTRACT(MONTH FROM CONVERT_TZ(`log_userconnection`.`disconnected`, 'UTC', 'UTC')) AS `mo`,
                   EXTRACT(DAY FROM CONVERT_TZ(`log_userconnection`.`disconnected`, 'UTC', 'UTC'))   AS `da`,
                   COUNT(DISTINCT `log_userconnection`.`user_id`) AS `active`
            FROM `log_userconnection`
            WHERE `log_userconnection`.`user_id` = %s
            GROUP BY `log_userconnection`.`user_id`, `mo`, `da`, `ye`
            ORDER BY NULL) `subquery`
      WHERE `da` IS NOT NULL
      GROUP BY `subquery`.`mo`, `subquery`.`da`, `subquery`.`ye`
      ORDER BY `ye` DESC, `mo` DESC, `da` DESC
      LIMIT 356;
    ''', [user.id.hex])

    query = cursor.fetchall()

  population = {}
  for i in query:
    key = datetime.datetime(year=i[3], month=i[1], day=i[2])
    key = str(int(key.timestamp()))
    population[key] = i[0]

  query = UserConnection.objects.filter(user=user, disconnected__isnull=False)\
                                .annotate(time=ExpressionWrapper(F('disconnected') - F('connected'),
                                                                 output_field=DurationField()))

  average = {'dataset': [], 'labels': []}
  today = datetime.date.today()
  year = today.year
  month = today.month

  derived = query.annotate(month=ExtractMonth('disconnected'),
                           year=ExtractYear('disconnected'))
  for i in range(0, 12):
    year_modifier = 0
    scope = month - i

    if scope < 1:
      scope += 12
      year_modifier = 1

    datapoint = derived.filter(month=scope, year=year - year_modifier)\
                       .aggregate(Avg('time'))['time__avg']
    label = calendar.month_abbr[scope]

    average['dataset'].append(
        round(datapoint.total_seconds() / 60 / 60, 1) if datapoint else 0)
    average['labels'].append("{} '{}".format(label, (year - year_modifier) % 2000))

  average['dataset'] = average['dataset'][::-1]
  average['labels'] = average['labels'][::-1]

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

  return render(request,
                'components/players/detailed/overview.pug',
                {'data': user,
                 'average': average,
                 'population': population,
                 'activity': activity,
                 'games': games})
