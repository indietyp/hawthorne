from ajax.views import *
from django.urls import path


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

  path('players', player.list),
  path('players/<int:page>', player.list_entries),
  path('players/<uuid:u>/overview', player.detailed_overview),
  path('players/<uuid:u>/logs', player.detailed_log),
  path('players/<uuid:u>/logs/<int:date>', player.detailed_log_date),
  path('players/<uuid:u>/logs/<int:date>/<int:page>', player.detailed_log_entries),
  path('players/<uuid:u>/actions', player.detailed_actions),
  path('players/<uuid:u>/actions/<int:page>', player.detailed_actions_entries),
  path('players/<uuid:u>/punishments', player.detailed_punishments),
  path('players/<uuid:u>/punishments/<int:page>', player.detailed_punishments_entries),

  path('punishments/bans', punishment.list, name="ajax[punishment][ban]"),
  path('punishments/bans/<int:page>', punishment.entries, name="ajax[punishment][ban]"),

  path('punishments/mutes', punishment.list, name="ajax[punishment][mute]"),
  path('punishments/mutes/<int:page>', punishment.entries, name="ajax[punishment][mute]"),

  path('punishments/gags', punishment.list, name="ajax[punishment][gag]"),
  path('punishments/gags/<int:page>', punishment.entries, name="ajax[punishment][gag]"),

  path('servers/<int:page>', server.list),
  path('servers/<slug:s>/overview', server.overview),
  path('servers/<slug:s>/logs', server.log),
  path('servers/<slug:s>/logs/<int:page>', server.log_entries),
  path('servers/<slug:s>/rcon', server.rcon),

  path('settings/tokens', setting.tokens),
  path('settings/tokens/<int:page>', setting.tokens_entries),
  # path('setting/group/<int:page>', setting.group),
  # path('setting/token/<int:page>', setting.token),

  path('system/update', system.update),
]
