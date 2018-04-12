from django.urls import path
from django.contrib.auth import views as auth_views
from . import views

urlpatterns = [
    path('', views.home),
    path('mail', views.mail),
    path('dashboard', views.dashboard),

    path('dashboard/login', views.login),
    path('dashboard/logout', auth_views.LogoutView.as_view(next_page='/'), name='logout')
]
