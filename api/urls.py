from django.urls import register_converter, path
from api.views import *
from api.views import documentation
from api.converters import SteamIDConverter

register_converter(SteamIDConverter, 'steamid')

urlpatterns = [
    # documentation
    path('', documentation),

    # users
    path('users', user.list, name='user.list'),
    path('users/<uuid:u>', user.detailed, name='user.detailed'),
    path('users/<steamid:s>', user.detailed, name='user.detailed'),
    path('users/<uuid:u>/ban', user.ban, name='user.ban'),
    path('users/<uuid:u>/kick', user.kick, name='user.kick'),
    path('users/<uuid:u>/mutegag', user.mutegag, name='user.mutegag'),

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

    # system
    path('system/chat', system.chat, name='system.chat'),
    path('system/token', system.token, name='system.token'),  # TODO: PUT, POST, GET (only masked)

    # steam
    path('steam/search', steam.search, name='steam.search'),
    path('steam/search/<int:i>', steam.search, name='steam.search'),

    # different current capabilities of the system
    path('capabilities/games', capabilities.games, name='capabilities.games')
]
