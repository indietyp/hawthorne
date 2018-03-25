from core.models import User, Instance
from django.views.decorators.csrf import csrf_exempt
from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from django.views.decorators.http import require_http_methods


@csrf_exempt
@json_response
@authentication_required
@permission_required('system.token')
@validation('system.token')
@require_http_methods(['PUT'])
def list(request, validated={}, *args, **kwargs):
  pass


@csrf_exempt
@json_response
@authentication_required
@permission_required('system.token')
@validation('system.token')
@require_http_methods(['PUT'])
def report(request, validated={}, *args, **kwargs):
  pass
