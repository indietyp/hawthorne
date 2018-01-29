from api import codes
import re
from cerberus import Validator


class Validator(Validator):
    def _validate_type_uuid(self, value):
        re_uuid = re.compile(r'[0-9a-f]{8}(?:(?:-)?[0-9a-f]{4}){3}(?:-)?[0-9a-f]{12}', re.I)
        if re_uuid.match(value):
            return True
            # self._error("Value for field '%s' must be valid UUID" % field)

    def _validate_type_steamid(self, value):
        re_steamid = re.compile(r'(765611979602657[3-8][0-9]|7656119796026579[0-9]|76561197960265[89][0-9]{2}|7656119796026[6-9][0-9]{3}|765611979602[7-9][0-9]{4}|76561197960[3-9][0-9]{5}|7656119796[1-9][0-9]{6}|765611979[7-9][0-9]{7}|7656119[89][0-9]{9}|7656120[01][0-9]{9}|76561202[01][0-9]{8}|765612022[0-4][0-9]{7}|7656120225[0-4][0-9]{6}|76561202255[01][0-9]{5}|765612022552[0-2][0-9]{4}|7656120225523[0-2][0-9]{3}|765612022552330[01][0-9]|76561202255233020)', re.I)
        if re_steamid.match(value):
            return True
            # self._error("Value for field '%s' must be valid steamid" % field)

    def _validate_type_ip(self, value):
        re_ip = re.compile(r'(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])', re.I)
        if re_ip.match(value):
            return True


validation = {
    'user': {
        'list': {
            'GET': {'validation': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s},
                                   'has_panel_access': {'type': 'boolean', 'default': None, 'nullable': True, 'coerce': codes.l_to_b},
                                   'role': {'type': 'uuid', 'default': None, 'nullable': True, 'coerce': codes.l_to_s}},
                    'permission': ['core.view_user']},
            'PUT': {'validation': {'steamid': {'type': 'integer', 'required': True, 'min': 76561197960265729, 'max': 76561202255233023},
                                   'username': {'type': 'string', 'required': True},
                                   'country': {'type': 'string', 'required': False},
                                   'ip': {'type': 'ip', 'required': False},
                                   'connect': {'type': 'boolean', 'required': False}},
                    'permission': ['core.add_user']}
        },
        'detailed': {
            'GET': {'validation': {'server': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False, 'coerce': codes.l_to_s}},
                    'permission': ['core.view_user']},
            'POST': {'validation': {'promotion': {'type': 'boolean', 'default': False},
                                    'role': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False, 'dependencies': ['server']},
                                    'server': {'type': 'uuid', 'required': False},
                                    'group': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False}},
                     'permission': ['core.modify_user']},
            'DELETE': {'validation': {'purge': {'type': 'boolean', 'default': False, 'required': False},
                                      'reset': {'type': 'boolean', 'default': True, 'required': False}},
                       'permission': ['core.delete_user']}
        }
    },
    'steam': {
        'search': {
            'GET': {'validation': {'scope': {'type': 'string', 'allowed': ['user'], 'default': 'user', 'coerce': codes.l_to_s},
                                   'query': {'type': 'string', 'required': True, 'coerce': codes.l_to_s},
                                   'mode': {'type': 'string', 'allowed': ['best-guess'], 'default': 'best-guess', 'coerce': codes.l_to_s}},
                    'permission': []}
        }
    }
}
