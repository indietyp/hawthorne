from django.urls import path
from views import *

urlpatterns = [
    # path('', views.documentation),
    path('admin/log/<int:page>', admin.log),
    path('admin/user/<int:page>', admin.user),
    path('admin/group/<int:page>', admin.group),
]
