import redis

from core.models import Server
from celery import group, shared_task
from celery.utils.log import get_task_logger
from django.conf import settings
from lib.sourcemod import SourcemodPluginWrapper


logger = get_task_logger(__name__)


@shared_task(name='core.tasks.rcon.wrapper')
def wrapper():
  from core.models import Server

  task = group(entry.s(server.id) for server in Server.objects.all())
  task.delay()

  return


@shared_task(name='core.tasks.rcon.server')
def entry(server):
  from log.models import ServerDataPoint, ServerScore
  from core.models import Server

  server = Server.objects.get(id=server)
  logger.info('processing %s...', server)
  response = SourcemodPluginWrapper(server).status(truncate=True)

  datapoint = ServerDataPoint()
  datapoint.server = server
  if 'error' in response:
    datapoint.is_online = False
    datapoint.save()

    logger.error('Error with {} occured ({})'.format(server.name, response['error']))
    return

  datapoint.map = response['map']
  datapoint.uptime = response['time']['up']
  datapoint.time_left = response['time']['left']

  server.protected = response['password']
  server.max_clients = response['limitations']['clients']

  scores = []
  for name, score in response['teams'].items():
    score, _ = ServerScore.objects.get_or_create(team_name=name,
                                                 team_id=score['id'],
                                                 score=score['score'])

    scores.append(score)

  datapoint.save()
  server.save()

  datapoint.clients.set(response['clients'])
  datapoint.score.set(scores)

  logger.info('finished %s...', server)
  return


@shared_task(name='core.tasks.server.propagate')
def propagate():
  cache = redis.Redis.from_url(settings.INTERMEDIATE_BROKER_URL)

  for server in Server.objects.all():
    indication = cache.get('ht-srv-{}'.format(server.id))
    sm = SourcemodPluginWrapper()

    if indication and indication > 0:
      logger.info('rebuilding admin cache for %s...', server)
      sm.rebuild_cache()