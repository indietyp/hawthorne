import io
import re
from functools import wraps
import logging

import ruamel.yaml as yaml
import simplejson as json
import xmltodict
from django.conf import settings
from django.http import JsonResponse

from api.utils import s_to_l
from lib.normalize import Normalize
from lib.validator import BaseValidator
from api.specification import validation as valid_dict
from core.utils import HawthorneJSONEncoder


def jsonparse(content=None, code=200, encoder=None):
  success = True if code >= 200 and code < 300 else False

  schema = {'success': {'type': 'boolean', 'required': True},
            'reason': {'type': ['dict', 'list'], 'dependencies': {'success': False}, 'coerce': s_to_l},
            'result': {'dependencies': {'success': True}}}
  v = BaseValidator(schema, update=True, purge_unknown=True)

  if content is None:
    content = 'no return value was supplied'

  document = {'success': success}
  if success:
    document['result'] = content
  else:
    document['reason'] = content

  document = v.normalized(document)
  if not v.validate(document):
    return JsonResponse({
      'error': 'FATAL ERROR. Validation Error occured. This should not happen ever. Contact the current maintainer ASAP.',
      'calm': v.errors}, status=500)

  if code != 200:
    logger = logging.getLogger(__name__)
    logger.warning(document)

  if encoder is None:
    return JsonResponse(document, status=code, encoder=HawthorneJSONEncoder)
  else:
    return JsonResponse(document, status=code, encoder=encoder)


def json_response(f):
  def wrapper(request, *args, **kwargs):
    try:
      response = f(request, *args, **kwargs)
      if response is None:
        response = []
    except Exception as e:
      response = (e.__str__(), 500)

    if not isinstance(response, tuple) or len(response) > 3:
      response = (response,)

    return jsonparse(*response)

  return wrapper


def validation(a):
  def argument_decorator(f, resolve=False):

    @wraps(f)
    def wrapper(request, *args, **kwargs):
      validation = valid_dict

      if resolve:
        target = request.resolver_match.url_name.split('.')
      else:
        target = a.split('.')
      for t in target:
        validation = validation[t]

      data = {}
      document = dict(request.GET)
      schema = validation[request.method]

      if not document and request.method not in ['GET']:
        if isinstance(request._stream.stream, io.BufferedReader):
          data = request._stream.stream.peek()
        else:
          data = request._stream.stream.read()

        if re.match(r'^[0-9a-fA-F]{2}', data.decode()):
          split = data.split(b'\r\n')

          data = b''
          for i in range(len(split)):
            if i % 2:
              data += split[i]

        meta = request.META['CONTENT_TYPE']
        data = data.decode()
        parser = None

        if re.match(r'^(text/plain|application/json)', meta):
          parser = json.loads
        elif re.match(r'^application/yaml', meta):
          parser = yaml.safe_load
        elif re.match(r'^application/xml', meta):
          parser = lambda x: xmltodict.parse(x)['root']

        try:
          document.update(parser(data) if data else {})
        except Exception as e:
          'Failed parsing payload ({})'.format(e), 512

      converted = {}
      for k, v in schema['parameters'].items():
        converted[k] = v

        if 'coerce' not in converted[k]:
          converted[k]['coerce'] = Normalize(converted[k]['type']).convert

      v = BaseValidator(converted, update=True, purge_unknown=True)
      document = v.normalized(document)

      if document is None:
        return v.errors, 428

      if not v.validate(document):
        return v.errors, 428

      data = document
      return f(request, validated=data, *args, **kwargs)

    return wrapper

  if callable(a):
    return argument_decorator(a, True)
  else:
    return argument_decorator
