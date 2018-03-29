from api import codes
import re
from cerberus import Validator


class Validator(Validator):
    def _validate_type_uuid(self, value):
      re_uuid = re.compile(r'[0-9a-f]{8}(?:(?:-)?[0-9a-f]{4}){3}(?:-)?[0-9a-f]{12}', re.I)
      if re_uuid.match(value):
        return True

    def _validate_type_steamid(self, value):
      val = value
      if isinstance(val, str) and value.isdigit():
        val = int(val)

      if isinstance(val, int) and 76561197960265729 <= value < 76561202255233023:
        return True

      return False

    def _validate_type_ip(self, value):
      re_ip = re.compile(r'(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])', re.I)
      if re_ip.match(value):
          return True


validation = {
    'instance': {
        'list': {
            'PUT': {'parameters': {'ip': {'type': 'ip', 'required': True}},
                    'permission': []}
        },
        'report': {
            'PUT': {'parameters': {'path': {'type': 'list', 'required': True},
                                   'version': {'type': 'string', 'required': True},
                                   'system': {'type': 'dict', 'required': True},
                                   'distro': {'type': 'string', 'required': True},
                                   'log': {'type': 'string', 'required': True},
                                   'directory': {'type': 'string', 'required': True}},
                    'permission': []},
        },
    }
}
