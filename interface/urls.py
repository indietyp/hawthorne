from django.urls import path
from django.contrib.auth import views as auth_views
from . import views

urlpatterns = [
    path('', views.home),
    path('bans', views.ban),
    path('chat', views.chat),
    path('admins', views.admin),
    path('servers', views.server),
    path('players', views.player),
    path('mutegags', views.mutegag),
    path('settings', views.settings),
    path('announcements', views.announcement),

    path('login', views.login),
    path('logout', auth_views.LogoutView.as_view(next_page='/'), name='logout')
    # path('articles/2003/', views.special_case_2003),
    # path('articles/<int:year>/', views.year_archive),
    # path('articles/<int:year>/<int:month>/', views.month_archive),
    # path('articles/<int:year>/<int:month>/<slug:slug>/', views.article_detail),
]
