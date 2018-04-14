import uuid
import json
import hashids
import string
import random
import socket
import datetime
from textwrap import dedent
from django.conf import settings
from django.template import loader
from email.mime.image import MIMEImage
from django.db.models import DateField
from django.db.models.functions import Cast
from django.core.files.base import ContentFile
from core.models import Instance, Report, Mail
from django.core.mail import EmailMultiAlternatives
from django.views.decorators.csrf import csrf_exempt
from core.decorators.auth import permission_required
from core.decorators.api import json_response, validation
from django.views.decorators.http import require_http_methods


@csrf_exempt
@json_response
@permission_required('instance.list')
@validation('instance.list')
@require_http_methods(['PUT'])
def list(request, validated={}, *args, **kwargs):
  if request.method == 'PUT':
    ip = request.META['REMOTE_ADDR']
    print(ip)

    try:
      domain = socket.gethostbyaddr(ip)[0]
    except:
      domain = None

    instance, created = Instance.objects.get_or_create(ip=ip, domain=domain)

    if 'name' in validated:
      instance.name = validated['name']

    if 'owner' in validated:
      instance.owner = validated['owner']

    instance.save()

    if created:
      return {'id': instance.id, 'salt': instance.salt}
    else:
      return {'id': instance.id}


@csrf_exempt
@json_response
@permission_required('instance.report')
@validation('instance.report')
@require_http_methods(['PUT'])
def report(request, validated={}, i=None, *args, **kwargs):
  instance = Instance.objects.get(id=i)

  instance.ip = request.META['REMOTE_ADDR']
  instance.domain = socket.gethostbyaddr(instance.ip)[0]
  instance.save()

  if request.method == 'PUT':
    report = Report()
    report.path = json.dumps(validated['path'])
    report.version = validated['version']
    report.directory = validated['directory']

    report.instance = instance

    report.system = json.dumps(validated['system'])
    report.distribution = validated['distro']

    hasher = hashids.Hashids(salt=''.join([random.choice(string.ascii_letters) for _ in range(5)]))
    report.log.save(hasher.encode(1238914084053279234) + '.log', ContentFile(validated['log']))
    report.save()

    return {'id': report.id}


@csrf_exempt
@json_response
@permission_required('instance.invite')
@validation('instance.invite')
@require_http_methods(['PUT'])
def invite(request, validated={}, i=None, *args, **kwargs):
  instance = Instance.objects.get(id=i)

  instance.ip = request.META['REMOTE_ADDR']
  try:
    instance.domain = socket.gethostbyaddr(instance.ip)[0]
  except:
    instance.domain = None
  instance.save()

  if request.method == 'PUT':
    query = Mail.objects.annotate(date=Cast('created_at', DateField()))\
                        .filter(date__gte=datetime.date.today())

    if query.count() >= 10:
      return 'You are being rate limited for today. The maximium capita per day is 5 invites.', 428

    t = loader.get_template('mail.pug')

    user = uuid.UUID(validated['user'])
    url = 'http://{}/setup/{}'.format(instance.domain, str(user))
    context = {'url': url, 'target': validated['from']}

    subject = 'You just got invited!'
    text = """
    Congratulations!

    You just got invited to the hawthorne panel of {target}.
    To begin using the panel just click the button below!
    We will then setup your credentials. c:

    What is hawthorne? <https://hawthorne.in>

    Join Now! <{url}>

    ---

    hawthorne - gameserver management made simple
    """.format(**context)

    text = dedent(text)
    html = t.render(context, request)

    msg = EmailMultiAlternatives(subject, text, "invitation@hawthorne.in", [validated['target']])
    for f in ['logo.png', 'discord.png', 'github.png']:
      path = "{}/interface/templates/assets/{}".format(settings.BASE_DIR, f)
      print(path)

      with open(path, 'rb') as file:
        img = MIMEImage(file.read())
        img.add_header('Content-ID', '<{}>'.format(f))

      msg.attach(img)

    msg.mixed_subtype = 'related'
    msg.attach_alternative(html, "text/html")

    msg.send()

    m = Mail()
    m.url = url
    m.target = validated['user']
    m.instance = instance
    m.save()

    return 'sent'
