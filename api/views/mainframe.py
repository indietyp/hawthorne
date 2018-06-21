"""API interface interactions to the mainframe"""

from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from lib.mainframe import Mainframe
from core.decorators.api import json_response, validation
from core.decorators.auth import authentication_required, permission_required


@csrf_exempt
@json_response
@authentication_required
@permission_required
@validation
@require_http_methods(['GET', 'PUT'])
def connect(request, validated={}, *args, **kwargs):
  if request.method == 'GET':
    limit = validated['limit']
    offset = validated['offset']

    mainframe = Mainframe()
    mainframe.check()
    selected = [k for k, v in mainframe.collect().items() if validated['match'] in k]
    return selected[offset:] if limit < 0 else selected[offset:limit]

  else:
    with Mainframe(validated['mainframe']) as mainframe:
      return {'id': mainframe().id}
