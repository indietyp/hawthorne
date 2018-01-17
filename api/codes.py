from django.http import JsonResponse
from cerberus import Validator


l_to_s = lambda v: ''.join(v)


def wrapper(content, success=True, code=200):
  schema = {'success': {'type': 'boolean',
                        'required': True},
            'reason': {'type': ['dict', 'list'],
                       'dependencies': {'success': False}},
            'result': {'dependencies': {'success': True}}}
  v = Validator(schema)

  document = {'success': success}
  if success:
    document['result'] = content
  else:
    document['reason'] = content

  if not v.validate(document):
    return JsonResponse({'error': 'FATAL ERROR, VALIDATION NOT WORKING. CONTACT SYSTEM ADMINISTRATOR', 'calm': v.errors}, status=500)

  return JsonResponse(document, status=code)


method = wrapper(['request method not allowed'], False, 405)
valid = wrapper(['data required was not satisfied'], False, 417)
