import os
import re
import rstr
import json
import uuid
import random
from faker import Faker
from django.contrib.auth.models import Permission

from django.core.management.base import BaseCommand
from django.conf import settings


class Command(BaseCommand):
  help = 'Generate OpenAPI specification'

  def cerberus_to_swagger(self, rules):
    fake = Faker()

    conversion = {}
    required = []
    for key, rule in rules.items():
      if rule['type'] in ['email', 'date', 'uuid', 'ip']:
        converted = {'type': 'string', 'format': rule['type']}
      elif rule['type'] == 'list':
        example = []
        samples = random.randint(3, 5)
        if 'type' not in rule['schema']:
          specification = {'type': 'string'}

          if 'regex' in rule['schema']:
            if rule['schema']['regex'] == '\w+\.\w+\_\w+':
              # special on for permissions
              p = Permission.objects.all()
              for _ in range(samples):
                c = random.randint(0, p.count())
                example.append("{1}.{0}".format(p[c].codename, p[c].content_type.app_label))
            else:
              specification['pattern'] = rule['schema']['regex']
              for _ in range(samples):
                example.append(rstr.xeger(rule['schema']['regex']))

        elif rule['schema']['type'] in ['email', 'date', 'uuid']:
          specification = {'type': 'string', 'format': rule['schema']['type']}

          if rule['schema']['type'] == 'email':
            for _ in range(samples):
              example.append(fake.email())

          if rule['schema']['type'] == 'uuid':
            for _ in range(samples):
              example.append(str(uuid.uuid4()))

        else:
          specification = {'type': rule['schema']['type']}

        converted = {'type': 'array', 'items': specification}

        if example:
          converted['example'] = example

      else:
        converted = {'type': rule['type']}

      if 'nullable' in rule and rule['nullable']:
        rule['required'] = False

      if 'required' in rule and rule['required']:
        required.append(key)

      if 'default' in rule:
        converted['default'] = rule['default']

      if 'max' in rule:
        converted['maximum'] = rule['max']

      if 'min' in rule:
        converted['minimum'] = rule['min']

      if 'allowed' in rule:
        if not isinstance(rule['allowed'], list):
          rule['allowed'] = [rule['allowed']]

        converted['anyOf'] = [{'enum': rule['allowed']}]

      if rule['type'] == 'email':
        converted['example'] = fake.email()

      if rule['type'] == 'uuid':
        converted['example'] = str(uuid.uuid4())

      if rule['type'] == 'ip':
        converted['example'] = fake.ipv4()

      conversion[key] = converted

    return conversion, required

  def handle(self, *args, **options):
    tmp = Permission.objects.all()
    perms = {}
    for perm in tmp:
      perms["{}.{}".format(perm.content_type.app_label, perm.codename)] = perm.name

    base = {}
    base['openapi'] = '3.0.0'
    base['info'] = {
        'description': 'The hawthorne API is the main way to interact with the management server.',
        'version': '0.8.7',
        'title': 'hawthorne',
        'contact': {'email': 'opensource@indietyp.com'},
    }
    base['servers'] = [
        {'url': 'demo.hawthornepanel.org/api/v1', 'description': 'Demo production server'},
        {'url': 'dev.hawthornepanel.org/api/v1', 'description': 'Bleeding edge test machine for public use'},
        {'url': '{host}:{port}/api/v1', 'description': 'Your own server'}
    ]
    base['components'] = {}
    base['components']['securitySchemes'] = {'api_key': {
        'type': 'apiKey',
        'in': 'header',
        'name': 'X-TOKEN'}}
    base['components']['schemas'] = {}
    base['components']['schemas']['Successful'] = {
        'type': 'object',
        'properties': {
            'success': {
                'type': 'boolean',
                'example': True
            },
            'result': {
                'type': 'object'
            }
        }
    }

    base['components']['schemas']['Failed'] = {
        'type': 'object',
        'properties': {
            'success': {
                'type': 'boolean',
                'example': False
            },
            'reason': {
                'type': 'object'
            }
        }
    }

    path = "{}/api/views".format(settings.BASE_DIR)
    modules = [f.split(".")[0] for f in os.listdir(path) if os.path.isfile("{}/{}".format(path, f)) and f != '__init__.py']

    base['tags'] = []
    for module in modules:
      exec("from api.views import {}".format(module))
      base['tags'].append({
          'name': module.capitalize(),
          'description': eval("{}.__doc__".format(module))
      })

    base['paths'] = {}
    from api.urls import urlpatterns
    from api.specification import validation

    for url in urlpatterns[1:]:
      pattern = "/{}".format(url.pattern)
      pattern = re.sub(r'\<(\w+)\:\w+\>', r"{\1}", pattern)
      base['paths'][pattern] = {}

      name = url.name

      target = validation
      for n in name.split('.'):
        target = target[n]

      for method, value in target.items():
        method = method.lower()
        properties, required = self.cerberus_to_swagger(value['parameters'])

        base['paths'][pattern][method] = {
            'tags': [name.split('.')[0].capitalize()],
            'summary': url.callback.__doc__ if url.callback.__doc__ else '',
            'description': "",
            'parameters': [],
            'responses': {
                "200": {
                    'description': 'Success',
                    'content': {
                        'application/json': {
                            'schema': {
                                "$ref": '#/components/schemas/Successful'
                            }
                        }}
                },
                "403": {
                    'description': 'No Query Found',
                    'content': {
                        'application/json': {
                            'schema': {
                                "$ref": '#/components/schemas/Failed'
                            }
                        }}
                },
                "428": {
                    'description': 'Invalid Parameters',
                    'content': {
                        'application/json': {
                            'schema': {
                                "$ref": '#/components/schemas/Failed'
                            }
                        }}
                },
                "500": {
                    'description': 'Fatal Internal Error',
                    'content': {
                        'application/json': {
                            'schema': {
                                "$ref": '#/components/schemas/Failed'
                            }
                        }}
                },
                "512": {
                    'description': 'Failed Parsing Payload',
                    'content': {
                        'application/json': {
                            'schema': {
                                "$ref": '#/components/schemas/Failed'
                            }
                        }}
                },
            },
            'security': [{'api_key': value['permission']}]
        }

        if method not in ['get', 'delete', 'patch']:
          schema = str(uuid.uuid4())
          base['components']['schemas'][schema] = {
              'type': 'object',
              'properties': properties,
              'xml': {'name': 'root'}
          }

          if required:
            base['components']['schemas'][schema]['required'] = required

          base['paths'][pattern][method]['requestBody'] = {
              'required': True,
              'description': '',
              'content': {
                  'application/json': {
                      'schema': {
                          '$ref': '#/components/schemas/' + schema,
                      }
                  },
                  'application/xml': {
                      'schema': {
                          '$ref': '#/components/schemas/' + schema,
                      }
                  },
                  'text/vnd.yaml': {
                      'schema': {
                          '$ref': '#/components/schemas/' + schema,
                      }
                  },
              }
          }
        else:
          for k, prop in properties.items():
            p = {
                'in': 'query',
                'name': k,
                'schema': prop,
                'required': True if k in required else False,
                'description': ''
            }
            base['paths'][pattern][method]['parameters'].append(p)

        additional = re.match(r'[\w\/]+{(\w+)}', pattern)
        if additional:
          n = additional.groups()[0]

          if n in ['uuid', 'steamid']:
            t = 'string'
            f = n
          elif n == 'int':
            t = 'string'
            f = 'int64'

          base['paths'][pattern][method]['parameters'].append(
              {
                  "name": n,
                  "in": "path",
                  "description": "",
                  "required": True,
                  "schema": {
                      "type": t,
                      "format": f
                  }
              })

    print(json.dumps(base))
