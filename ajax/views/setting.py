import math

from django.conf import settings
from django.contrib.auth.decorators import login_required, permission_required
from django.contrib.auth.models import Permission
from django.contrib.contenttypes.models import ContentType
from django.db.models import F
from django.shortcuts import render
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from core.models import Token


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
@permission_required('core.view_token')
@require_http_methods(['POST'])
def tokens(request, *args, **kwargs):
  current = request.POST.get("page", 1)
  pages = math.ceil(Token.objects.filter(is_active=True).count() / settings.PAGE_SIZE)

  return render(request, 'components/settings/tokens/wrapper.pug', {'pages': pages,
                                                                    'current': current})


@login_required(login_url='/login')
@permission_required('core.view_token')
@require_http_methods(['POST'])
def tokens_entries(request, page, *args, **kwargs):
  tokens = Token.objects.filter(is_active=True).order_by('created_at')
  return renderer(request, 'components/settings/tokens/entry.pug', tokens, page)
