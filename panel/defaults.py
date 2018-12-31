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
            'filename': '/var/log/hawthorne/debug.log',
            'formatter': 'verbose'
        },
        'auto': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': '/var/log/hawthorne/auto.log',
            'formatter': 'verbose'
        },
        'database': {
            'level': 'INFO',
            'class': 'automated_logging.handlers.DatabaseHandler'
        },
    },
    'loggers': {
        'django.request': {
            'handlers': ['file'],
            'level': 'WARNING',
            'propagate': False,
        },
        'django.server': {
            'handlers': ['file'],
            'level': 'WARNING',
            'propagate': False,
        },
        'django': {
            'handlers': ['file', 'database'],
            'level': 'INFO',
            'propagate': True,
        },
        'automated_logging': {
            'handlers': ['auto', 'database'],
            'level': 'INFO',
            'propagate': True,
        }
    },
}

STATIC_PRECOMPILER_COMPILERS = (
    ('interface.compilers.CoyoteCompiler', {'compress': True}),
    ('static_precompiler.compilers.Stylus', {"sourcemap_enabled": True}),
)

DEMO = False
ROOT = "root"
LOGIN_REDIRECT_URL = '/'
RCON_TIMEOUT = 0.5
PAGE_SIZE = 16
