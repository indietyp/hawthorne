from django.urls import path
from . import steam, views

urlpatterns = [
    path('', views.documentation),
    path('steam/search', steam.search),
]
