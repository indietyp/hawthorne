from django.urls import path
from ajax.views import *


urlpatterns = [
  path('admins/servers/admins', admin.servers_admins),
  path('admins/servers/admins/<int:page>', admin.servers_admins_entries),
  path('chat/log/<int:page>', chat.log),

  path('ban/user/<int:page>', ban.user),

  path('mutegag/user/<int:page>', mutegag.user),

  path('player/user/<int:page>', player.user),

  path('servers/<int:page>', server.list),
  path('servers/<slug:s>/overview', server.overview),
  path('servers/<slug:s>/log', server.log),
  path('servers/<slug:s>/rcon', server.rcon),

  path('setting/user/<int:page>', setting.user),
  path('setting/group/<int:page>', setting.group),
  path('setting/token/<int:page>', setting.token),
]
