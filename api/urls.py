from django.urls import register_converter, path
from api.views import *
from api.views import documentation
from api.converters import SteamIDConverter

register_converter(SteamIDConverter, 'steamid')

urlpatterns = [
    # documentation
    path('', documentation),

    # users
    path('users', user.list),                         # PUT, GET - DONE
    path('users/<uuid:u>', user.detailed),            # POST, GET, DELETE
    path('users/<steamid:s>', user.detailed),         # POST, GET, DELETE
    path('users/<uuid:u>/ban', user.ban),             # POST, GET
    path('users/<uuid:u>/kick', user.kick),           # POST
    path('users/<uuid:u>/mutegag', user.mutegag),     # POST, GET
    path('users/<uuid:u>/<uuid:s>/permissions', user.serverpermission),     # GET

    # groups
    path('groups', group.list),                       # PUT, GET
    path('groups/<uuid:g>', group.detailed),          # POST, GET, DELETE

    # servers
    path('servers', server.list),                     # PUT, GET
    path('servers/<uuid:s>', server.detailed),        # POST, GET, DELETE
    path('servers/<uuid:s>/execute', server.action),  # POST

    # system
    path('sytem/log', system.log),                    # GET, PUT
    path('sytem/chat', system.chat),                  # GET, PUT

    # steam
    path('steam/search', steam.search),               # GET
]
