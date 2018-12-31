from core.models import Server
from django.template.defaulttags import register


@register.filter
def get_server_name(value):
  return Server.objects.get(id=value).name


@register.filter
def get_groups_name(value):
  return value.groups.all()[0].name


@register.filter
def get_groups_id(value):
  if value.is_superuser or not value.groups.all():
    return ""

  return value.groups.all()[0].id
