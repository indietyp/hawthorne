"""API interface current capabilities"""

from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required
from core.models import Server


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['GET'])
def games(request, validated={}, *args, **kwargs):
  return [{'value': g[0], 'label': g[1]} for g in Server.SUPPORTED]
