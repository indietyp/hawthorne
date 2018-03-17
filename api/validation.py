from api import codes
import re
from cerberus import Validator
from cerberus.errors import BasicErrorHandler
from django.utils.translation import gettext_lazy as _


class HumanReadableValidationError(BasicErrorHandler):
  messages = {0x00: "{0}",

              0x01: _("document is missing"),
              0x02: _("required field"),
              0x03: _("unknown field"),
              0x04: _("field '{0}' is required"),
              0x05: _("depends on these values: {constraint}"),
              0x06: _("{0} must not be present with '{field}'"),

              0x21: _("'{0}' is not a document, must be a dict"),
              0x22: _("empty values not allowed"),
              0x23: _("value needs to be supplied"),
              0x24: _("must be of {constraint} type"),
              0x25: _("must be of dict type"),
              0x26: _("length of list should be {constraint}, it is {0}"),
              0x27: _("min length is {constraint}"),
              0x28: _("max length is {constraint}"),

              0x41: _("value does not match regex '{constraint}'"),
              0x42: _("min value is {constraint}"),
              0x43: _("max value is {constraint}"),
              0x44: _("unallowed value {value}"),
              0x45: _("unallowed values {0}"),
              0x46: _("unallowed value {value}"),
              0x47: _("unallowed values {0}"),

              0x61: _("field '{field}' cannot be coerced: {0}"),
              0x62: _("field '{field}' cannot be renamed: {0}"),
              0x63: _("field is read-only"),
              0x64: _("default value for '{field}' cannot be set: {0}"),

              0x81: _("mapping doesn't validate subschema: {0}"),
              0x82: _("one or more sequence-items don't validate: {0}"),
              0x83: _("one or more keys of a mapping  don't validate: {0}"),
              0x84: _("one or more values in a mapping don't validate: {0}"),
              0x85: _("one or more sequence-items don't validate: {0}"),

              0x91: _("one or more definitions validate"),
              0x92: _("none or more than one rule validate"),
              0x93: _("no definitions validate"),
              0x94: _("one or more definitions don't validate")
              }


class Validator(Validator):
    def __init__(self, *args, **kwargs):
      kwargs['error_handler'] = HumanReadableValidationError()
      super().__init__(*args, **kwargs)
      # self.error_handler = HumanReadableValidationError

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
    'user': {
        'list': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s},
                                   'has_panel_access': {'type': 'boolean', 'default': None, 'nullable': True, 'coerce': codes.l_to_b},
                                   'role': {'type': 'uuid', 'default': None, 'nullable': True, 'coerce': codes.l_to_s}},
                    'permission': ['core.view_user']},
            'PUT': {'parameters': {'steamid': {'type': 'integer', 'min': 76561197960265729, 'max': 76561202255233023, 'coerce': codes.s_to_i, 'dependencies': {'id': None}, 'nullable': True, 'default': None},
                                   'id': {'type': 'uuid', 'dependencies': {'steamid': None}, 'nullable': True, 'default': None},
                                   'username': {'type': 'string', 'required': False},
                                   'country': {'type': 'string', 'nullable': True, 'default': None},
                                   'ip': {'type': 'ip', 'nullable': True, 'default': None},
                                   'connected': {'type': 'boolean', 'dependencies': ['server'], 'nullable': True, 'default': None},
                                   'server': {'type': 'uuid'}},
                    'permission': ['core.add_user']}
        },
        'detailed': {
            'GET': {'parameters': {'server': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False, 'coerce': codes.l_to_s}},
                    'permission': ['core.view_user']},
            'POST': {'parameters': {'promotion': {'type': 'boolean', 'default': False},
                                    'force': {'type': 'boolean', 'default': False},
                                    'role': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False},
                                    'group': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False}},
                     'permission': ['core.change_user']},
            'DELETE': {'parameters': {'purge': {'type': 'boolean', 'default': False, 'required': False},
                                      'reset': {'type': 'boolean', 'default': True, 'required': False},
                                      'role': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False}},
                       'permission': ['core.delete_user']}
        },
        'ban': {
            'GET': {'parameters': {'server': {'type': 'uuid', 'nullable': True, 'default': None, 'coerce': codes.l_to_s},
                                   'resolved': {'type': 'boolean', 'nullable': True, 'default': None, 'coerce': codes.l_to_b}},
                    'permission': ['core.view_ban']},
            'POST': {'parameters': {'server': {'type': 'uuid', 'required': True},
                                    'resolved': {'type': 'boolean', 'nullable': True, 'default': None},
                                    'reason': {'type': 'string', 'nullable': True, 'default': None},
                                    'length': {'type': 'integer', 'nullable': True, 'default': None}},
                     'permission': ['core.change_ban']},
            'PUT': {'parameters': {'server': {'type': 'uuid', 'required': False},
                                   'reason': {'type': 'string', 'required': True},
                                   'length': {'type': 'integer', 'required': True},
                                   'issuer': {'type': 'integer', 'default': None, 'nullable': True, 'required': False}},
                    'permission': ['core.add_ban']},
            'DELETE': {'parameters': {'server': {'type': 'uuid', 'required': True}},
                       'permission': ['core.delete_ban']},
        },
        'kick': {
            'PUT': {'parameters': {'server': {'type': 'uuid', 'required': True}},
                    'permission': ['kick_user']},
        },
        'mutegag': {
            'GET': {'parameters': {'server': {'type': 'uuid', 'nullable': True, 'default': None, 'coerce': codes.l_to_s},
                                   'resolved': {'type': 'boolean', 'nullable': True, 'default': None, 'coerce': codes.l_to_b}},
                    'permission': ['core.view_mutegag']},
            'POST': {'parameters': {'server': {'type': 'uuid', 'required': False},
                                    'resolved': {'type': 'boolean', 'nullable': True, 'default': None},
                                    'type': {'type': 'string', 'allowed': ['mute', 'gag', 'both'], 'default': 'both', 'coerce': codes.lower},
                                    'reason': {'type': 'string', 'nullable': True, 'default': None},
                                    'length': {'type': 'integer', 'nullable': True, 'default': None}},
                     'permission': ['core.change_mutegag']},
            'PUT': {'parameters': {'server': {'type': 'uuid', 'required': False},
                                   'reason': {'type': 'string', 'required': True},
                                   'type': {'type': 'string', 'allowed': ['mute', 'gag', 'both'], 'default': 'both', 'coerce': codes.lower},
                                   'length': {'type': 'integer', 'required': True}},
                    'permission': ['core.add_mutegag']},
            'DELETE': {'parameters': {'server': {'type': 'uuid', 'required': True}},
                       'permission': ['core.delete_mutegag']},
        }
    },
    'group': {
        'list': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s}},
                    'permission': ['core.view_group']},
            'PUT': {'parameters': {'name': {'type': 'string', 'required': True},
                                   'permissions': {'type': 'list', 'default': [], 'schema': {'regex': '\w+\.\w+\_\w+'}},
                                   'members': {'type': 'list', 'default': [], 'schema': {'type': 'uuid'}}},
                    'permission': ['auth.add_group']}
        },
        'detailed': {
            'GET': {'parameters': {},
                    'permission': ['core.view_group']},
            'POST': {'parameters': {'name': {'type': 'string', 'default': None, 'nullable': True},
                                    'permissions': {'type': 'list', 'default': [], 'schema': {'regex': '\w+\.\w+\_\w+'}},
                                    'members': {'type': 'list', 'default': [], 'schema': {'type': 'uuid'}}},
                     'permission': ['auth.change_group']},
            'DELETE': {'parameters': {},
                       'permission': ['auth.delete_group']}
        }
    },
    'role': {
        'list': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s}},
                    'permission': ['core.view_servergroup']},
            'PUT': {'parameters': {'name': {'type': 'string', 'required': True},
                                   'immunity': {'type': 'integer', 'required': True, 'min': 0, 'max': 100},
                                   'server': {'type': 'uuid', 'default': None, 'nullable': True},
                                   'usetime': {'type': 'integer', 'default': None, 'nullable': True, 'min': 0},
                                   'flags': {'type': 'string', 'default': None, 'nullable': True, 'regex': r'[A-N]+'},
                                   'members': {'type': 'list', 'default': [], 'schema': {'type': 'uuid'}}},
                    'permission': ['core.add_servergroup']}
        },
        'detailed': {
            'GET': {'parameters': {},
                    'permission': ['core.view_servergroup']},
            'POST': {'parameters': {'name': {'type': 'string', 'default': None, 'nullable': True},
                                    'immunity': {'type': 'integer', 'default': None, 'nullable': True, 'min': 0, 'max': 100},
                                    'usetime': {'type': 'integer', 'default': None, 'nullable': True, 'min': -1},
                                    'server': {'type': 'uuid', 'default': None, 'nullable': True},
                                    'flags': {'type': 'string', 'default': None, 'nullable': True, 'regex': r'[A-N]+'},
                                    'members': {'type': 'list', 'default': [], 'schema': {'type': 'uuid'}}},
                     'permission': ['core.change_servergroup']},
            'DELETE': {'parameters': {},
                       'permission': ['core.delete_servergroup']}
        }
    },
    'server': {
        'list': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s},
                                   'ip': {'type': 'ip', 'nullable': True, 'default': None, 'coerce': codes.l_to_s},
                                   'port': {'type': 'integer', 'nullable': True, 'default': None, 'min': 0, 'max': 65535, 'coerce': codes.l_to_i}},
                    'permission': ['core.view_server']},
            'PUT': {'parameters': {'name': {'type': 'string', 'required': True},
                                   'ip': {'type': 'ip', 'required': True},
                                   'verify': {'type': 'boolean', 'default': True},
                                   'port': {'type': 'integer', 'required': True, 'min': 0, 'max': 65535},
                                   'password': {'type': 'string', 'required': True},
                                   'game': {'type': 'string', 'required': True},
                                   'mode': {'type': 'string', 'required': False}},
                    'permission': ['core.add_server']}
        },
        'detailed': {
            'GET': {'parameters': {},
                    'permission': ['core.view_server']},
            'POST': {'parameters': {'name': {'type': 'string', 'nullable': True, 'default': None},
                                    'verify': {'type': 'boolean', 'default': True},
                                    'ip': {'type': 'ip', 'nullable': True, 'default': None},
                                    'port': {'type': 'integer', 'nullable': True, 'default': None, 'min': 0, 'max': 65535},
                                    'password': {'type': 'string', 'nullable': True, 'default': None},
                                    'game': {'type': 'string', 'nullable': True, 'default': None},
                                    'gamemode': {'type': 'string', 'nullable': True, 'default': None}},
                     'permission': ['core.change_server']},
            'DELETE': {'parameters': {},
                       'permission': ['core.delete_server']}
        },
        'action': {
            'PUT': {'parameters': {'command': {'type': 'string', 'required': True}},
                    'permission': ['core.execute_server']}
        }
    },
    'system': {
        'log': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s},
                                   'descend': {'type': 'boolean', 'default': True, 'coerce': codes.l_to_b}},
                    'permission': ['core.view_log']},
            'PUT': {'parameters': {'action': {'type': 'string', 'required': True},
                                   'user': {'type': 'uuid', 'required': True}},
                    'permission': ['core.add_log']}
        },
        'chat': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s}},
                    'permission': ['core.view_chat']},
            'PUT': {'parameters': {'user': {'type': 'uuid', 'required': True},
                                   'server': {'type': 'uuid', 'required': True},
                                   'ip': {'type': 'ip', 'required': True},
                                   'message': {'type': 'string', 'required': True},
                                   'command': {'type': 'boolean', 'default': None, 'nullable': True}},
                    'permission': ['core.add_chat']}
        },
        'token': {}
    },
    'steam': {
        'search': {
            'GET': {'parameters': {'scope': {'type': 'string', 'allowed': ['user'], 'default': 'user', 'coerce': codes.l_to_s},
                                   'query': {'type': 'string', 'required': True, 'coerce': codes.l_to_s},
                                   'mode': {'type': 'string', 'allowed': ['best-guess'], 'default': 'best-guess', 'coerce': codes.l_to_s},
                                   '_ts': {'type': 'integer', 'required': False, 'coerce': codes.l_to_i}},
                    'permission': []}
        }
    },
    'capabilities': {
        'games': {
            'GET': {'parameters': {},
                    'permission': ['view_capabilities']}
        }
    }
}
