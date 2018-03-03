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
    path('users/<uuid:u>/ban', user.ban, name='user.ban'),                  # POST, GET, PUT, DELETE - DONE
    path('users/<uuid:u>/kick', user.kick, name='user.kick'),               # PUT - DONE
    path('users/<uuid:u>/mutegag', user.mutegag, name='user.mutegag'),      # POST, GET, PUT, DELETE - DONE

    # groups
    path('groups', group.list, name='group.list'),                          # PUT, GET - DONE
    path('groups/<int:g>', group.detailed, name='group.detailed'),          # POST, GET, DELETE - DONE

    # game server roles
    path('roles', role.list, name='role.list'),                             # PUT, GET - DONE
    path('roles/<uuid:r>', role.detailed, name='role.detailed'),            # POST, GET, DELETE - DONE

    # servers
    path('servers', server.list, name='server.list'),                       # PUT, GET
    path('servers/<uuid:s>', server.detailed, name='server.detailed'),      # POST, GET, DELETE
    path('servers/<uuid:s>/execute', server.action, name='server.action'),  # POST

    # system
    path('system/log', system.log, name='system.log'),                      # GET, PUT
    path('system/chat', system.chat, name='system.chat'),                   # GET, PUT

    # steam
    path('steam/search', steam.search, name='steam.search'),                # GET
    path('steam/search/<int:i>', steam.search, name='steam.search'),        # GET
]
