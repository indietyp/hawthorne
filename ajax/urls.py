from django.urls import path
from ajax.views import *

urlpatterns = [
    path('admin/log/<int:page>', admin.log),
    path('admin/user/<int:page>', admin.user),
    path('admin/group/<int:page>', admin.group),

    path('chat/log/<int:page>', chat.log),

    path('ban/user/<int:page>', ban.user),

    path('mutegag/user/<int:page>', mutegag.user),

    path('player/user/<int:page>', player.user),

    path('server/server/<int:page>', server.server),
]
