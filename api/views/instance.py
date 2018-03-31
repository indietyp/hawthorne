import json
import hashids
import string
import random
from core.models import Instance, Report
from django.views.decorators.csrf import csrf_exempt
from core.decorators.api import json_response, validation
from core.decorators.auth import permission_required
from django.core.files.base import ContentFile
from django.views.decorators.http import require_http_methods


@csrf_exempt
@json_response
@permission_required('instance.list')
@validation('instance.list')
@require_http_methods(['PUT'])
def list(request, validated={}, *args, **kwargs):
  if request.method == 'PUT':
    instance, created = Instance.objects.get_or_create(ip=validated['ip'])

    return {'id': instance.id}


@csrf_exempt
@json_response
@permission_required('instance.report')
@validation('instance.report')
@require_http_methods(['PUT'])
def report(request, validated={}, i=None, *args, **kwargs):
  instance = Instance.objects.get(id=i)

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
