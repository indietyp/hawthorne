from django.contrib.auth.decorators import login_required, permission_required
from django.contrib.contenttypes.models import ContentType
from django.views.decorators.http import require_http_methods

from django.db.models import Count, F
from django.contrib.auth.models import Permission, Group
from ajax.views import renderer
from core.models import User, Token


def get_perms(o, user, *args, **kwargs):
  modules = [c for c in ContentType.objects.filter(app_label__in=['core', 'log']) if
             Permission.objects.filter(content_type=c).count() > 0]

  perms = Permission.objects.all()\
                            .annotate(encoded=F('content_type__model') + '.' + F('codename'))\
                            .filter(encoded__in=user.get_all_permissions())\
                            .order_by('content_type__model')

  used = o.permissions if 'permissions' in [f.name for f in o._meta.get_fields()] else o.user_permissions

  return {'advanced': perms, 'base': modules, 'used': used.all()}


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def user(request, page, *args, **kwargs):
  perms = Permission.objects.all().count()
  obj = User.objects.filter(is_active=True)\
                    .annotate(perms=(Count('user_permissions') / perms) * 100)\
                    .order_by('perms')
  return renderer(request, 'components/setting/user.pug', obj, page, execute=get_perms)


@login_required(login_url='/login')
@permission_required('core.view_group')
@require_http_methods(['POST'])
def group(request, page, *args, **kwargs):
  perms = Permission.objects.all().count()
  obj = Group.objects.all()\
                     .annotate(perms=(Count('permissions') / perms) * 100)\
                     .order_by('perms')
  return renderer(request, 'components/setting/group.pug', obj, page, execute=get_perms)


@login_required(login_url='/login')
@permission_required('core.view_token')
@require_http_methods(['POST'])
def token(request, page, *args, **kwargs):
  perms = Permission.objects.all().count()
  obj = Token.objects.all()\
                     .annotate(perms=(Count('permissions') / perms) * 100)\
                     .order_by('perms')

  return renderer(request, 'components/setting/token.pug', obj, page)
