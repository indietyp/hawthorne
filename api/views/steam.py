"""API interface for the (unofficial) steam api"""

from django.views.decorators.http import require_http_methods

from api.lib.steam import search as steamsearch
from core.decorators.api import json_response, validation
from core.models import User


@json_response
@validation
@require_http_methods(['GET'])
def search(request, i=False, validated={}, *args, **kwargs):
  if i:
    output = User.objects.filter(is_steam=True, namespace__icontains=validated['query'])[:16]
    output = [{'name': o.namespace, 'url': o.id, 'image': o.avatar} for o in output]
  else:
    output = steamsearch(validated['query'])

  output = {'data': output}

  if '_ts' in validated:
    output['_ts'] = validated['_ts']

  return output
