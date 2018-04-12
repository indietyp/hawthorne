from django.urls import register_converter, path
from api.views import *
from api.views import documentation
from api.converters import SteamIDConverter

register_converter(SteamIDConverter, 'steamid')

urlpatterns = [
    # documentation
    path('', documentation),

    # instance
    path('instance', instance.list, name='instance.list'),
    path('instance/<uuid:i>/report', instance.report, name='instance.report'),
    path('instance/<uuid:i>/invite', instance.invite, name='instance.invite')
]
