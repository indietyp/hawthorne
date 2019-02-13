import os

from configparser import ConfigParser

CONFIG_DIR = os.path.dirname(os.path.abspath(__file__))

config = ConfigParser()
config.read(CONFIG_DIR + '/local.ini')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',

        'NAME': config['database']['name'],
        'USER': config['database']['user'],
        'PASSWORD': config['database']['password'],

        'HOST': config['database']['host'],
        'PORT': config['database']['port'],
        'OPTIONS': {
            'sql_mode': 'STRICT_ALL_TABLES',
            'charset': 'utf8mb4',
        }
    }
}

DEBUG = False
DEMO = True if config['system']['demo'] == 'true' else False
STATIC_PRECOMPILER_DISABLE_AUTO_COMPILE = not DEBUG

REDISCACHE = 'localhost:6379'
SOCIAL_AUTH_STEAM_API_KEY = config['system']['steamapi']
STATIC_ROOT = '/local/static'

ALLOWED_HOSTS = config['system']['hosts'].split(',')
ROOT = config['system']['root']

# generate me baby
SECRET_KEY = config['system']['secret']
