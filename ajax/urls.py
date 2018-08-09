from django.urls import path
from ajax.views import *


urlpatterns = [
  path('admins/servers/admins', admin.servers_admins),
  path('admins/servers/admins/<int:page>', admin.servers_admins_entries),
  path('admins/servers/roles', admin.servers_roles),
  path('admins/servers/roles/<int:page>', admin.servers_roles_entries),

  path('admins/web/admins', admin.web_admins),
  path('admins/web/admins/<int:page>', admin.web_admins_entries),
  path('admins/web/groups', admin.web_groups),
  path('admins/web/groups/<int:page>', admin.web_groups_entries),

  path('chat/log/<int:page>', chat.log),

  path('player/user/<int:page>', player.user),

  path('punishments/bans', punishment.list, name="ajax[punishment][ban]"),
  path('punishments/bans/<int:page>', punishment.entries, name="ajax[punishment][ban]"),

  path('punishments/mutes', punishment.list, name="ajax[punishment][mute]"),
  path('punishments/mutes/<int:page>', punishment.entries, name="ajax[punishment][mute]"),

  path('punishments/gags', punishment.list, name="ajax[punishment][gag]"),
  path('punishments/gags/<int:page>', punishment.entries, name="ajax[punishment][gag]"),

  path('servers/<int:page>', server.list),
  path('servers/<slug:s>/overview', server.overview),
  path('servers/<slug:s>/log', server.log),
  path('servers/<slug:s>/rcon', server.rcon),

  path('setting/user/<int:page>', setting.user),
  path('setting/group/<int:page>', setting.group),
  path('setting/token/<int:page>', setting.token),
]
