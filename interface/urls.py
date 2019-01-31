from django.contrib.auth import views as auth_views
from django.urls import path

from interface import views


urlpatterns = [
    path('', views.home),

    path('servers', views.server),
    path('servers/<slug:s>', views.server_detailed),

    path('admins/servers', views.admins_servers),
    path('admins/web', views.admins_web),

    path('punishments/bans', views.punishments, name="interface[punishments][ban]"),
    path('punishments/mutes', views.punishments, name="interface[punishments][mutes]"),
    path('punishments/gags', views.punishments, name="interface[punishments][gags]"),

    path('players', views.player),
    path('players/<uuid:u>', views.player_detailed),

    # path('announcements', views.announcement),
    path('settings', views.settings),

    path('logout', auth_views.LogoutView.as_view(next_page='/'), name='logout'),
    path('login', auth_views.LoginView.as_view(template_name='skeleton/login.pug', redirect_authenticated_user=True), name='login'),
]
