from django.urls import register_converter, path
from api.views import *
from api.views import documentation
from api.converters import SteamIDConverter

register_converter(SteamIDConverter, 'steamid')

urlpatterns = [
    # documentation
    path('', documentation),

    # users
    path('users', user.list, name='user.list'),                             # PUT, GET - DONE
    path('users/<uuid:u>', user.detailed, name='user.detailed'),            # POST, GET, DELETE - DONE
    path('users/<steamid:s>', user.detailed, name='user.detailed'),         # POST, GET, DELETE - DONE
    path('users/<uuid:u>/ban', user.ban, name='user.ban'),                  # POST, GET
    path('users/<uuid:u>/kick', user.kick, name='user.kick'),               # POST
    path('users/<uuid:u>/mutegag', user.mutegag, name='user.mutegag'),      # POST, GET

    # groups
    path('groups', group.list, name='group.list'),                          # PUT, GET
    path('groups/<uuid:g>', group.detailed, name='group.detailed'),         # POST, GET, DELETE

    # game server roles
    path('roles', role.list, name='role.list'),                             # PUT, GET
    path('roles/<uuid:r>', role.detailed, name='role.detailed'),            # POST, GET, DELETE

    # servers
    path('servers', server.list, name='server.list'),                       # PUT, GET
    path('servers/<uuid:s>', server.detailed, name='server.list'),          # POST, GET, DELETE
    path('servers/<uuid:s>/execute', server.action, name='server.action'),  # POST

    # system
    path('sytem/log', system.log, name='system.log'),                       # GET, PUT
    path('sytem/chat', system.chat, name='system.chat'),                    # GET, PUT

    # steam
    path('steam/search', steam.search, name='steam.search'),                # GET
]
