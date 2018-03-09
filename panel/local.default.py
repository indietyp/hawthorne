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
        'interface': {
            'level': 'DEBUG',
            'class': 'logging.FileHandler',
            'filename': '/var/log/hawthorne/interface.log',
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
    ('static_precompiler.compilers.CoffeeScript', {"executable": "/usr/bin/coffee"}),
    ('static_precompiler.compilers.SASS', {
        "sourcemap_enabled": True,
        "compass_enabled": True,
        "precision": 8,
        "output_style": "compressed",
    }),
)

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',

        'NAME': 'hawthorne',
        'USER': 'root',
        'PASSWORD': '',

        'HOST': 'localhost',
        'PORT': '3306',
        'OPTIONS': {
            'sql_mode': 'STRICT_ALL_TABLES'
        }
    }
}

DEBUG = False
STATIC_PRECOMPILER_DISABLE_AUTO_COMPILE = not DEBUG
REDISCACHE = 'localhost:6379'
SOCIAL_AUTH_STEAM_API_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
STATIC_ROOT = '/local/static'
ALLOWED_HOSTS = ['*']

# generate me baby
SECRET_KEY = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
