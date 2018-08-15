from core.models import Server
from django.template.defaulttags import register


@register.filter
def get_server_name(value):
  return Server.objects.get(id=value).name
