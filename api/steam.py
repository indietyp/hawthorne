from cerberus import Validator
from .lib import steam
from . import codes


def search(request):
  if request.method != 'GET':
    return codes.method

  schema = {'scope': {'type': 'string', 'allowed': ['user'], 'default': 'user', 'coerce': codes.l_to_s},
            'query': {'type': 'string', 'required': True, 'coerce': codes.l_to_s},
            'mode': {'type': 'string', 'allowed': ['best-guess'], 'default': 'best-guess', 'coerce': codes.l_to_s}}
  document = dict(request.GET)

  v = Validator(schema, update=True, purge_unknown=True)
  document = v.normalized(document)
  print(document)
  if not v.validate(document):
    return codes.wrapper(v.errors, False, 428)

  output = steam.search(document['query'])

  return codes.wrapper(output)
