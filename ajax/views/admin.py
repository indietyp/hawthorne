from django.contrib.auth.decorators import login_required, permission_required
from django.db.models import F, Count, Value, CharField, IntegerField
from django.views.decorators.http import require_http_methods
from django.conf import settings

from ajax.views import renderer
from core.models import User, Role
from log.models import ServerChat


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def user(request, page, *args, **kwargs):
  # superuser = root
  obj = User.objects.annotate(rct=Count('roles')) \
    .filter(rct__gt=0) \
    .annotate(server=F('roles__server__name')) \
    .annotate(role=F('roles__name')) \
    .annotate(role_id=F('roles__id')) \
    .annotate(location=F('country__code'))

  ext = User.objects.filter(is_superuser=True) \
    .annotate(server=Value(None, CharField(null=True))) \
    .annotate(role=Value(settings.ROOT, CharField())) \
    .annotate(role_id=Value(0, IntegerField())) \
    .annotate(location=F('country__code'))
  return renderer(request, 'partials/admin/user.pug', obj, page, extra=ext)


@login_required(login_url='/login')
@permission_required('core.view_chat')
@require_http_methods(['POST'])
def log(request, page, *args, **kwargs):
  obj = ServerChat.objects.filter(command=True)
  return renderer(request, 'partials/admin/log.pug', obj, page)


@login_required(login_url='/login')
@permission_required('core.view_role')
@require_http_methods(['POST'])
def group(request, page, *args, **kwargs):
  obj = Role.objects.all().order_by('immunity')
  return renderer(request, 'partials/admin/group.pug', obj, page)
