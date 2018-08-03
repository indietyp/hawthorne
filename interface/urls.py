from django.contrib.auth import views as auth_views
from django.urls import path

from . import views

urlpatterns = [
    path('', views.home),

    path('servers', views.server),
    path('servers/<slug:s>', views.server_detailed),

    path('admins/servers', views.admins_servers),

    path('punishments/bans', views.punishments, name="interface[punishments][ban]"),
    path('punishments/mutes', views.punishments, name="interface[punishments][mutes]"),
    path('punishments/gags', views.punishments, name="interface[punishments][gags]"),

    path('players', views.player),
    # path('bans', views.ban),
    # path('mutegags', views.mutegag),
    # path('announcements', views.announcement),
    path('settings', views.settings),

    path('setup/<uuid:u>', views.setup),
    path('login', views.login),
    path('logout', auth_views.LogoutView.as_view(next_page='/'), name='logout'),
]
