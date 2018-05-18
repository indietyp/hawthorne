from api import utils

validation = {
    'user': {
        'list': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1},
                                   'match': {'type': 'string', 'default': ''},
                                   'has_panel_access': {'type': 'boolean', 'default': None, 'nullable': True},
                                   'role': {'type': 'uuid', 'default': None, 'nullable': True}},
                    'permission': ['core.view_user']},
            'PUT': {'parameters': {'steamid': {'type': 'integer', 'min': 76561197960265729, 'max': 76561202255233023, 'excludes': ['id']},
                                   'id': {'type': 'uuid', 'excludes': ['steamid']},

                                   'username': {'type': 'string', 'required': False},
                                   'ip': {'type': 'ip', 'nullable': True, 'default': None},
                                   'country': {'type': 'string', 'nullable': True, 'default': None},

                                   'server': {'type': 'uuid'},
                                   'connected': {'type': 'boolean', 'dependencies': ['server'], 'nullable': True},

                                   'internal': {'type': 'boolean', 'default': False},
                                   'permissions': {'type': 'list', 'schema': {'regex': '\w+\.\w+\_\w+'},
                                                   'dependencies': {'internal': True}},
                                   'groups': {'type': 'list', 'nullable': True, 'dependencies': {'internal': True}, 'schema': {'type': 'integer'}},

                                   'local': {'type': 'boolean', 'dependencies': {'internal': True}},
                                   'email': {'type': 'email', 'dependencies': {'local': True}}},
                    'permission': ['core.add_user']}
        },
        'detailed': {
            'GET': {'parameters': {'server': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False}},
                    'permission': ['core.view_user']},
            'POST': {'parameters': {'promotion': {'type': 'boolean', 'default': False},
                                    'force': {'type': 'boolean', 'default': False},
                                    'role': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False},
                                    'group': {'type': 'integer', 'default': None, 'nullable': True, 'required': False},

                                    'roles': {'type': 'list', 'default': None, 'nullable': True, 'schema': {'type': 'uuid'}},
                                    'groups': {'type': 'list', 'default': None, 'nullable': True, 'schema': {'type': 'integer'}},
                                    'permissions': {'type': 'list', 'schema': {'regex': '\w+\.\w+\_\w+'}, 'nullable': True, 'default': None}},
                     'permission': ['core.change_user']},
            'DELETE': {'parameters': {'purge': {'type': 'boolean', 'default': False, 'required': False},
                                      'reset': {'type': 'boolean', 'default': True, 'required': False},
                                      'role': {'type': 'uuid', 'default': None, 'nullable': True, 'required': False}},
                       'permission': ['core.delete_user']}
        },
        'ban': {
            'GET': {'parameters': {'server': {'type': 'uuid', 'nullable': True, 'default': None},
                                   'resolved': {'type': 'boolean', 'nullable': True, 'default': None}},
                    'permission': ['core.view_ban']},
            'POST': {'parameters': {'server': {'type': 'uuid', 'required': True},
                                    'resolved': {'type': 'boolean', 'nullable': True, 'default': None},
                                    'reason': {'type': 'string', 'nullable': True, 'default': None},
                                    'length': {'type': 'integer', 'nullable': True, 'default': None}},
                     'permission': ['core.change_ban']},
            'PUT': {'parameters': {'server': {'type': 'uuid', 'required': False},
                                   'reason': {'type': 'string', 'required': True},
                                   'length': {'type': 'integer', 'required': True},
                                   'issuer': {'type': 'integer', 'default': None, 'nullable': True, 'required': False},
                                   'plugin': {'type': 'boolean', 'default': True}},
                    'permission': ['core.add_ban']},
            'DELETE': {'parameters': {'server': {'type': 'uuid', 'nullable': True, 'default': None}},
                       'permission': ['core.delete_ban']},
        },
        'kick': {
            'PUT': {'parameters': {'server': {'type': 'uuid', 'required': True}},
                    'permission': ['core.kick_user']},
        },
        'auth': {
            'GET': {'parameters': {'password': {'type': 'string', 'required': True}},
                    'permission': ['core.view_user']},
        },
        'mutegag': {
            'GET': {'parameters': {'server': {'type': 'uuid', 'nullable': True, 'default': None},
                                   'resolved': {'type': 'boolean', 'nullable': True, 'default': None}},
                    'permission': ['core.view_mutegag']},
            'POST': {'parameters': {'server': {'type': 'uuid', 'required': False},
                                    'resolved': {'type': 'boolean', 'nullable': True, 'default': None},
                                    'type': {'type': 'string', 'allowed': ['mute', 'gag', 'both'], 'default': 'both',
                                             'coerce': utils.lower},
                                    'reason': {'type': 'string', 'nullable': True, 'default': None},
                                    'length': {'type': 'integer', 'nullable': True, 'default': None}},
                     'permission': ['core.change_mutegag']},
            'PUT': {'parameters': {'server': {'type': 'uuid', 'required': False},
                                   'reason': {'type': 'string', 'required': True},
                                   'type': {'type': 'string', 'allowed': ['mute', 'gag', 'both'], 'default': 'both',
                                            'coerce': utils.lower},
                                   'length': {'type': 'integer', 'required': True},
                                   'plugin': {'type': 'boolean', 'default': True}},
                  'permission': ['core.add_mutegag']},
            'DELETE': {'parameters': {'server': {'type': 'uuid', 'nullable': True, 'default': None},
                                      'plugin': {'type': 'boolean', 'default': True}},
                       'permission': ['core.delete_mutegag']},
        }
    },
    'group': {
        'list': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1},
                                   'match': {'type': 'string', 'default': ''}},
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
                                    'permissions': {'type': 'list', 'default': [],
                                                    'schema': {'regex': '\w+\.\w+\_\w+'}},
                                    'members': {'type': 'list', 'default': [], 'schema': {'type': 'uuid'}}},
                     'permission': ['auth.change_group']},
            'DELETE': {'parameters': {},
                       'permission': ['auth.delete_group']}
        }
    },
    'role': {
        'list': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1},
                                   'match': {'type': 'string', 'default': ''}},
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
                                    'immunity': {'type': 'integer', 'default': None, 'nullable': True, 'min': 0,
                                                 'max': 100},
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
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1},
                                   'match': {'type': 'string', 'default': ''},
                                   'ip': {'type': 'ip', 'nullable': True, 'default': None},
                                   'port': {'type': 'integer', 'nullable': True, 'default': None, 'min': 0,
                                            'max': 65535}},
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
                                    'port': {'type': 'integer', 'nullable': True, 'default': None, 'min': 0,
                                             'max': 65535},
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
        'chat': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1},
                                   'match': {'type': 'string', 'default': ''}},
                    'permission': ['log.view_chat']},
            'PUT': {'parameters': {'user': {'type': 'uuid', 'required': True},
                                   'server': {'type': 'uuid', 'required': True},
                                   'ip': {'type': 'ip', 'required': True},
                                   'message': {'type': 'string', 'required': True},
                                   'command': {'type': 'boolean', 'default': None, 'nullable': True}},
                    'permission': ['log.add_serverchat']}
        },
        'token': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1},
                                   'active': {'type': 'boolean', 'default': True, 'nullable': True}},
                    'permission': ['core.view_token']},
            'PUT': {'parameters': {'permissions': {'type': 'list', 'schema': {'regex': '\w+\.\w+\_\w+'}, 'required': True},
                                   'due': {'type': 'integer', 'default': None, 'nullable': True},
                                   'active': {'type': 'boolean', 'default': True}},
                    'permission': ['core.add_token']},
        },
        'token[detailed]': {
            'GET': {'parameters': {},
                    'permission': ['core.view_token']},
            'DELETE': {'parameters': {},
                       'permission': ['core.delete_token']},
        }
    },
    'steam': {
        'search': {
            'GET': {'parameters': {'scope': {'type': 'string', 'allowed': ['user'], 'default': 'user'},
                                   'query': {'type': 'string', 'required': True},
                                   'mode': {'type': 'string', 'allowed': ['best-guess'], 'default': 'best-guess'},
                                   '_ts': {'type': 'integer', 'required': False}},
                    'permission': []}
        }
    },
    'capabilities': {
        'games': {
            'GET': {'parameters': {},
                    'permission': ['core.view_capabilities']}
        }
    },
    'mainframe': {
        'connect': {
            'GET': {'parameters': {'offset': {'type': 'integer', 'min': 0, 'default': 0},
                                   'limit': {'type': 'integer', 'min': -1, 'default': -1},
                                   'match': {'type': 'string', 'default': ''}},
                    'permission': ['core.view_mainframe']},
            'PUT': {'parameters': {'mainframe': {'type': 'string', 'default': None, 'nullable': True}},
                    'permission': ['core.add_mainframe']},
        }
    }
}
