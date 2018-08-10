from django.contrib.auth import views as auth_views
from django.urls import path

from . import views

urlpatterns = [
    path('', views.home),

    path('servers', views.server),
    path('servers/<slug:s>', views.server_detailed),

    path('admins/servers', views.admins_servers),
    path('admins/web', views.admins_web),
    path('admins/web/groups/<int:i>', views.admins_web_group),

    path('punishments/bans', views.punishments, name="interface[punishments][ban]"),
    path('punishments/mutes', views.punishments, name="interface[punishments][mutes]"),
    path('punishments/gags', views.punishments, name="interface[punishments][gags]"),

    path('players', views.player),
    # path('announcements', views.announcement),
    path('settings', views.settings),

    path('setup/<uuid:u>', views.setup),
    path('login', views.login),
    path('logout', auth_views.LogoutView.as_view(next_page='/'), name='logout'),
]
