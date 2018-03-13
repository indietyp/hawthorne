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
            'PUT': {'validation': {'steamid': {'type': 'integer', 'min': 76561197960265729, 'max': 76561202255233023, 'coerce': codes.s_to_i, 'dependencies': {'id': None}, 'nullable': True, 'default': None},
                                   'id': {'type': 'uuid', 'dependencies': {'steamid': None}, 'nullable': True, 'default': None},
                                   'username': {'type': 'string', 'required': False},
                                   'country': {'type': 'string', 'nullable': True, 'default': None},
                                   'ip': {'type': 'ip', 'nullable': True, 'default': None},
                                   'connected': {'type': 'boolean', 'dependencies': ['server'], 'nullable': True, 'default': None},
                                   'server': {'type': 'uuid'}},
                    'permission': ['core.add_user']}
        },
        'detailed': {
            'GET': {'validation': {'server': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False, 'coerce': codes.l_to_s}},
                    'permission': ['core.view_user']},
            'POST': {'validation': {'promotion': {'type': 'boolean', 'default': False},
                                    'force': {'type': 'boolean', 'default': False},
                                    'role': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False},
                                    'group': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False}},
                     'permission': ['core.change_user']},
            'DELETE': {'validation': {'purge': {'type': 'boolean', 'default': False, 'required': False},
                                      'reset': {'type': 'boolean', 'default': True, 'required': False},
                                      'role': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False}},
                       'permission': ['core.delete_user']}
        },
        'ban': {
            'GET': {'validation': {'server': {'type': 'uuid', 'nullable': True, 'default': None, 'coerce': codes.l_to_s},
                                   'resolved': {'type': 'boolean', 'nullable': True, 'default': None, 'coerce': codes.l_to_b}},
                    'permission': ['core.view_ban']},
            'POST': {'validation': {'server': {'type': 'uuid', 'required': True},
                                    'resolved': {'type': 'boolean', 'nullable': True, 'default': None},
                                    'reason': {'type': 'string', 'nullable': True, 'default': None},
                                    'length': {'type': 'integer', 'nullable': True, 'default': None}},
                     'permission': ['core.change_ban']},
            'PUT': {'validation': {'server': {'type': 'uuid', 'required': False},
                                   'reason': {'type': 'string', 'required': True},
                                   'length': {'type': 'integer', 'required': True},
                                   'issuer': {'type': 'integer', 'default': None, 'nullable': True, 'required': False}},
                    'permission': ['core.add_ban']},
            'DELETE': {'validation': {'server': {'type': 'uuid', 'required': True}},
                       'permission': ['core.delete_ban']},
        },
        'kick': {
            'PUT': {'validation': {'server': {'type': 'uuid', 'required': True}},
                    'permission': ['kick_user']},
        },
        'mutegag': {
            'GET': {'validation': {'server': {'type': 'uuid', 'nullable': True, 'default': None, 'coerce': codes.l_to_s},
                                   'resolved': {'type': 'boolean', 'nullable': True, 'default': None, 'coerce': codes.l_to_b}},
                    'permission': ['core.view_mutegag']},
            'POST': {'validation': {'server': {'type': 'uuid', 'required': False},
                                    'resolved': {'type': 'boolean', 'nullable': True, 'default': None},
                                    'type': {'type': 'string', 'allowed': ['mute', 'gag', 'both'], 'default': 'both', 'coerce': codes.lower},
                                    'reason': {'type': 'string', 'nullable': True, 'default': None},
                                    'length': {'type': 'integer', 'nullable': True, 'default': None}},
                     'permission': ['core.change_mutegag']},
            'PUT': {'validation': {'server': {'type': 'uuid', 'required': False},
                                   'reason': {'type': 'string', 'required': True},
                                   'type': {'type': 'string', 'allowed': ['mute', 'gag', 'both'], 'default': 'both', 'coerce': codes.lower},
                                   'length': {'type': 'integer', 'required': True}},
                    'permission': ['core.add_mutegag']},
            'DELETE': {'validation': {'server': {'type': 'uuid', 'required': True}},
                       'permission': ['core.delete_mutegag']},
        }
    },
    'group': {
        'list': {
            'GET': {'validation': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s}},
                    'permission': ['core.view_group']},
            'PUT': {'validation': {'name': {'type': 'string', 'required': True},
                                   'permissions': {'type': 'list', 'default': [], 'schema': {'regex': '\w+\.\w+\_\w+'}},
                                   'members': {'type': 'list', 'default': [], 'schema': {'type': 'uuid'}}},
                    'permission': ['auth.add_group']}
        },
        'detailed': {
            'GET': {'validation': {},
                    'permission': ['core.view_group']},
            'POST': {'validation': {'name': {'type': 'string', 'default': None, 'nullable': True},
                                    'permissions': {'type': 'list', 'default': [], 'schema': {'regex': '\w+\.\w+\_\w+'}},
                                    'members': {'type': 'list', 'default': [], 'schema': {'type': 'uuid'}}},
                     'permission': ['auth.change_group']},
            'DELETE': {'validation': {},
                       'permission': ['auth.delete_group']}
        }
    },
    'role': {
        'list': {
            'GET': {'validation': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s}},
                    'permission': ['core.view_servergroup']},
            'PUT': {'validation': {'name': {'type': 'string', 'required': True},
                                   'immunity': {'type': 'integer', 'required': True, 'min': 0, 'max': 100},
                                   'server': {'type': 'uuid', 'default': None, 'nullable': True},
                                   'usetime': {'type': 'integer', 'default': None, 'nullable': True, 'min': 0},
                                   'flags': {'type': 'string', 'default': None, 'nullable': True, 'regex': r'[A-N]+'},
                                   'members': {'type': 'list', 'default': [], 'schema': {'type': 'uuid'}}},
                    'permission': ['core.add_servergroup']}
        },
        'detailed': {
            'GET': {'validation': {},
                    'permission': ['core.view_servergroup']},
            'POST': {'validation': {'name': {'type': 'string', 'default': None, 'nullable': True},
                                    'immunity': {'type': 'integer', 'default': None, 'nullable': True, 'min': 0, 'max': 100},
                                    'usetime': {'type': 'integer', 'default': None, 'nullable': True, 'min': -1},
                                    'server': {'type': 'uuid', 'default': None, 'nullable': True},
                                    'flags': {'type': 'string', 'default': None, 'nullable': True, 'regex': r'[A-N]+'},
                                    'members': {'type': 'list', 'default': [], 'schema': {'type': 'uuid'}}},
                     'permission': ['core.change_servergroup']},
            'DELETE': {'validation': {},
                       'permission': ['core.delete_servergroup']}
        }
    },
    'server': {
        'list': {
            'GET': {'validation': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s},
                                   'ip': {'type': 'ip', 'nullable': True, 'default': None, 'coerce': codes.l_to_s},
                                   'port': {'type': 'integer', 'nullable': True, 'default': None, 'min': 0, 'max': 65535, 'coerce': codes.l_to_i}},
                    'permission': ['core.view_server']},
            'PUT': {'validation': {'name': {'type': 'string', 'required': True},
                                   'ip': {'type': 'ip', 'required': True},
                                   'verify': {'type': 'boolean', 'default': True},
                                   'port': {'type': 'integer', 'required': True, 'min': 0, 'max': 65535},
                                   'password': {'type': 'string', 'required': True},
                                   'game': {'type': 'string', 'required': True},
                                   'mode': {'type': 'string', 'required': False}},
                    'permission': ['core.add_server']}
        },
        'detailed': {
            'GET': {'validation': {},
                    'permission': ['core.view_server']},
            'POST': {'validation': {'name': {'type': 'string', 'nullable': True, 'default': None},
                                    'verify': {'type': 'boolean', 'default': True},
                                    'ip': {'type': 'ip', 'nullable': True, 'default': None},
                                    'port': {'type': 'integer', 'nullable': True, 'default': None, 'min': 0, 'max': 65535},
                                    'password': {'type': 'string', 'nullable': True, 'default': None},
                                    'game': {'type': 'string', 'nullable': True, 'default': None},
                                    'gamemode': {'type': 'string', 'nullable': True, 'default': None}},
                     'permission': ['core.change_server']},
            'DELETE': {'validation': {},
                       'permission': ['core.delete_server']}
        },
        'action': {
            'PUT': {'validation': {'command': {'type': 'string', 'required': True}},
                    'permission': ['core.execute_server']}
        }
    },
    'system': {
        'log': {
            'GET': {'validation': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s},
                                   'descend': {'type': 'boolean', 'default': True, 'coerce': codes.l_to_b}},
                    'permission': ['core.view_log']},
            'PUT': {'validation': {'action': {'type': 'string', 'required': True},
                                   'user': {'type': 'uuid', 'required': True}},
                    'permission': ['core.add_log']}
        },
        'chat': {
            'GET': {'validation': {'offset': {'type': 'integer', 'min': 0, 'default': 0, 'coerce': codes.l_to_i},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1, 'coerce': codes.l_to_i},
                                   'match': {'type': 'string', 'default': '', 'coerce': codes.l_to_s}},
                    'permission': ['core.view_chat']},
            'PUT': {'validation': {'user': {'type': 'uuid', 'required': True},
                                   'server': {'type': 'uuid', 'required': True},
                                   'ip': {'type': 'ip', 'required': True},
                                   'message': {'type': 'string', 'required': True},
                                   'command': {'type': 'boolean', 'default': None, 'nullable': True}},
                    'permission': ['core.add_chat']}
        },
    },
    'steam': {
        'search': {
            'GET': {'validation': {'scope': {'type': 'string', 'allowed': ['user'], 'default': 'user', 'coerce': codes.l_to_s},
                                   'query': {'type': 'string', 'required': True, 'coerce': codes.l_to_s},
                                   'mode': {'type': 'string', 'allowed': ['best-guess'], 'default': 'best-guess', 'coerce': codes.l_to_s},
                                   '_ts': {'type': 'integer', 'required': False, 'coerce': codes.l_to_i}},
                    'permission': []}
        }
    }
}
