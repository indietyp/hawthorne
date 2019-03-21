from django.urls import path, register_converter

from api.converters import SteamIDConverter
from api.views import *
from api.views import documentation

register_converter(SteamIDConverter, 'steamid')

urlpatterns = [
    # documentation
    path('', documentation),

    # users
    path('users', user.list, name='user.list'),
    path('users/<uuid:u>', user.detailed, name='user.detailed'),
    path('users/<steamid:s>', user.detailed, name='user.detailed'),
    path('users/<uuid:u>/punishments', user.punishment, name='user.punishment'),
    path('users/<uuid:u>/punishments/<uuid:p>', user.punishment_detailed, name='user.punishment[detailed]'),

    # groups
    path('groups', group.list, name='group.list'),
    path('groups/<int:g>', group.detailed, name='group.detailed'),

    # game server roles
    path('roles', role.list, name='role.list'),
    path('roles/<uuid:r>', role.detailed, name='role.detailed'),

    # servers
    path('servers', server.list, name='server.list'),
    path('servers/<uuid:s>', server.detailed, name='server.detailed'),
    path('servers/<uuid:s>/execute', server.action, name='server.action'),
    path('servers/<uuid:s>/message', server.message, name='server.message'),

    # system
    path('system/chat', system.chat, name='system.chat'),
    path('system/tokens', system.token, name='system.token'),
    path('system/tokens/<uuid:t>', system.token_detailed, name='system.token[detailed]'),  # GET, DELETE
    path('system/authentication', system.authentication, name='system.authentication'),
    path('system/messages', system.chat, name='system.chat'),
    path('system/logs', system.chat, name='system.chat'),
    path('system/sourcemod/verification', system.sourcemod_verification, name='system.sourcemod[verification]'),

    # steam
    path('steam/search', steam.search, name='steam.search'),
    path('steam/search/<int:i>', steam.search, name='steam.search'),

    # different current capabilities of the system
    path('capabilities/games', capabilities.games, name='capabilities.games'),
    path('capabilities/permissions', capabilities.permissions, name='capabilities.permissions'),

    # mainframe connection
    path('mainframe/connect', mainframe.connect, name='mainframe.connect'),
]
