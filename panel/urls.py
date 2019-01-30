"""hawthorne URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.11/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.conf.urls import url, include
    2. Add a URL to urlpatterns:  url(r'^blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import include, path
from interface.views import page_not_found

urlpatterns = [
  path('admin/', admin.site.urls),
  path('api/v1/', include('api.urls')),
  path('ajax/v1/', include('ajax.urls')),
  path('', include('interface.urls')),
  path('external/', include('social_django.urls', namespace='social')),
  path('404', page_not_found)
]

handler404 = 'interface.views.page_not_found'
handler500 = 'interface.views.internal_server_error'
