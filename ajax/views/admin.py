import math

from django.contrib.auth.decorators import login_required, permission_required
from django.db.models import F, Count, Value, CharField, IntegerField
from django.shortcuts import render
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from django.conf import settings
from core.models import User, ServerGroup, Membership
from log.models import ServerChat


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def servers_admins(request):
  current = request.POST.get("page", 1)

  pages = math.ceil(Membership.objects.all().count() / settings.PAGE_SIZE)
  return render(request, 'components/admins/servers/admins/wrapper.pug', {'pages': pages,
                                                                          'current': current})


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def servers_admins_entries(request, page):
  superusers = []
  for superuser in User.objects.filter(is_superuser=True, is_steam=True):
    m = Membership()
    m.user = superuser
    superusers.append(m)

  memberships = Membership.objects.all()
  return renderer(request, 'components/admins/servers/admins/entry.pug', memberships, page, extra=superusers)


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
    .annotate(role=Value('root', CharField())) \
    .annotate(role_id=Value(0, IntegerField())) \
    .annotate(location=F('country__code'))
  return renderer(request, 'components/admin/user.pug', obj, page, extra=ext)


@login_required(login_url='/login')
@permission_required('core.view_chat')
@require_http_methods(['POST'])
def log(request, page, *args, **kwargs):
  obj = ServerChat.objects.filter(command=True)
  return renderer(request, 'components/admin/log.pug', obj, page)


@login_required(login_url='/login')
@permission_required('core.view_servergroup')
@require_http_methods(['POST'])
def group(request, page, *args, **kwargs):
  obj = ServerGroup.objects.all().order_by('immunity')
  return renderer(request, 'components/admin/group.pug', obj, page)
