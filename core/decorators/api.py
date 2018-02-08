from django.http import JsonResponse
import json
from api.codes import s_to_l
from functools import wraps
from api.validation import validation as valid_dict
from api.validation import Validator


def jsonparse(content=None, code=200, success=None):
  if success is None:
    # applying best guess
    success = True if code >= 200 and code < 300 else False

  schema = {'success': {'type': 'boolean',
                        'required': True},
            'reason': {'type': ['dict', 'list'],
                       'dependencies': {'success': False}, 'coerce': s_to_l},
            'result': {'dependencies': {'success': True}}}
  v = Validator(schema, update=True, purge_unknown=True)

  if content is None:
    content = 'no return value was supplied'

  document = {'success': success}
  if success:
    document['result'] = content
  else:
    document['reason'] = content

  document = v.normalized(document)
  if not v.validate(document):
    return JsonResponse({'error': 'FATAL ERROR, VALIDATION NOT WORKING. CONTACT SYSTEM ADMINISTRATOR', 'calm': v.errors}, status=500)

  return JsonResponse(document, status=code)


def json_response(f):
  def wrapper(request, *args, **kwargs):
    try:
      response = f(request, *args, **kwargs)
    except Exception as e:
      response = (e.args[-1], 500)

    if not isinstance(response, tuple) or len(response) > 4:
      response = (response,)

    return jsonparse(*response)
  return wrapper


def validation(a):
  def argument_decorator(f):

    @wraps(f)
    def wrapper(request, *args, **kwargs):
      validation = valid_dict

      # try:
      target = a.split('.')
      for t in target:
        validation = validation[t]

      data = {}
      if request.method == 'GET':
        document = dict(request.GET)
        schema = validation['GET']
      else:
        document = json.loads(request.body) if request.body != b'' else {}
        schema = validation[request.method]

      schema = schema['validation']

      v = Validator(schema, update=True, purge_unknown=True)
      document = v.normalized(document)

      if document is None:
        return v.errors, 428

      if not v.validate(document):
        return v.errors, 428

      data = document
      return f(request, validated=data, *args, **kwargs)

    return wrapper
  return argument_decorator
