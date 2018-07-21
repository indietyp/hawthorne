from django.contrib.auth import views as auth_views
from django.urls import path

from . import views

urlpatterns = [
    path('', views.home),
    path('bans', views.ban),

    path('servers', views.server),
    path('servers/<slug:s>', views.server_detailed),

    path('admins/servers', views.admins_servers),

    path('players', views.player),
    path('mutegags', views.mutegag),
    path('settings', views.settings),
    path('announcements', views.announcement),

    path('setup/<uuid:u>', views.setup),
    path('login', views.login),
    path('logout', auth_views.LogoutView.as_view(next_page='/'), name='logout'),
]
