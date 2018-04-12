from django.contrib.auth.decorators import login_required, permission_required
from django.views.decorators.http import require_http_methods

from django.db.models import Count
from django.contrib.auth.models import Permission, Group
from ajax.views import renderer
from core.models import User, Token


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def user(request, page, *args, **kwargs):
  perms = Permission.objects.all().count()
  obj = User.objects.filter(is_active=True)\
                    .annotate(perms=(Count('user_permissions') / perms) * 100)\
                    .order_by('perms')
  return renderer(request, 'partials/setting/user.pug', obj, page)


@login_required(login_url='/login')
@permission_required('core.view_group')
@require_http_methods(['POST'])
def group(request, page, *args, **kwargs):
  perms = Permission.objects.all().count()
  obj = Group.objects.all()\
                     .annotate(perms=(Count('permissions') / perms) * 100)\
                     .order_by('perms')
  return renderer(request, 'partials/setting/group.pug', obj, page)


@login_required(login_url='/login')
@permission_required('core.view_token')
@require_http_methods(['POST'])
def token(request, page, *args, **kwargs):
  perms = Permission.objects.all().count()
  obj = Token.objects.all()\
                     .annotate(perms=(Count('permissions') / perms) * 100)\
                     .order_by('perms')

  return renderer(request, 'partials/setting/token.pug', obj, page)
