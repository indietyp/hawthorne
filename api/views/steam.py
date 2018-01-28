from api.lib import steam
from core.decorators.api import json_response, validation
from django.views.decorators.http import require_http_methods


@json_response
@validation('steam.search')
@require_http_methods(['GET'])
def search(request, validated={}, *args, **kwargs):
  output = steam.search(validated['query'])

  return output
