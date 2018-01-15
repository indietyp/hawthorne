LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s'
        },
        'request': {
            'format': '%(levelname)s %(asctime)s [%(user)s] [%(ip)s] [%(method)s]: %(message)s'
        },
        'moderation': {
            'format': '%(levelname)s %(asctime)s [%(user)s] [%(model)s] [%(action)s]: %(message)s'
        },
        'simple': {
            'format': '%(levelname)s %(message)s'
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/var/log/boompanel/debug.log',
            'formatter': 'verbose'
        },
        'interface': {
            'level': 'DEBUG',
            'class': 'logging.FileHandler',
            'filename': '/var/log/boompanel/interface.log',
            'formatter': 'request'
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
        'interface': {
            'handlers': ['interface'],
            'level': 'INFO',
            'propagate': True,
        }
    },
}

STATIC_PRECOMPILER_COMPILERS = (
    ('static_precompiler.compilers.CoffeeScript', {"executable": "/usr/local/bin/coffee"}),
    ('static_precompiler.compilers.SASS', {
        "sourcemap_enabled": True,
        "compass_enabled": True,
        "precision": 8,
        "output_style": "compressed",
    }),
)

DEBUG = False
REDISCACHE = 'localhost:6379'
SOCIAL_AUTH_STEAM_API_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

# generate me baby
SECRET_KEY = '##t_85)kd%hca+xfp6fhk06mx&r+yw%%u@8c5bfkuc@yg-7^vt'
