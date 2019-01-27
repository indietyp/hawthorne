import math

from django.conf import settings
from django.contrib.auth.decorators import login_required, permission_required
from django.contrib.auth.models import Group, Permission
from django.shortcuts import render
from django.views.decorators.http import require_http_methods

from ajax.views import renderer
from core.models import Membership, Role, Server, User


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def servers_admins(request):
  current = request.POST.get("page", 1)

  pages = math.ceil(Membership.objects.all().count() / settings.PAGE_SIZE)
  if pages == 0 and User.objects.filter(is_superuser=True).count() != 0:
    pages = 1

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
    m.is_superuser = True
    superusers.append(m)

  memberships = Membership.objects.all()
  return renderer(request, 'components/admins/servers/admins/entry.pug', memberships, page, extra=superusers)


@login_required(login_url='/login')
@permission_required('core.view_role')
@require_http_methods(['POST'])
def servers_roles(request):
  return render(request, 'components/admins/servers/roles/wrapper.pug')


@login_required(login_url='/login')
@permission_required('core.view_role')
@require_http_methods(['POST'])
def servers_roles_entries(request, page):
  obj = Role.objects.all()
  return renderer(request, 'components/admins/servers/roles/entry.pug', obj, page,
                  size=4, overwrite=True, payload={'servers': Server.objects.all()})


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def web_admins(request):
  current = request.POST.get("page", 1)

  pages = math.ceil(User.objects.filter(is_active=True).count() / settings.PAGE_SIZE)
  return render(request, 'components/admins/web/admins/wrapper.pug', {'pages': pages,
                                                                      'current': current})


@login_required(login_url='/login')
@permission_required('core.view_user')
@require_http_methods(['POST'])
def web_admins_entries(request, page):
  users = User.objects.filter(is_active=True)

  return renderer(request, 'components/admins/web/admins/entry.pug', users, page)


@login_required(login_url='/login')
@permission_required('auth.view_group')
@require_http_methods(['POST'])
def web_groups(request):
  return render(request, 'components/admins/web/groups/wrapper.pug')


@login_required(login_url='/login')
@permission_required('auth.view_group')
@require_http_methods(['POST'])
def web_groups_entries(request, page):
  obj = Group.objects.all()
  permissions = Permission.objects.all()

  return renderer(request, 'components/admins/web/groups/entry.pug', obj, page, size=4,
                  overwrite=True, payload={'permissions': permissions,
                                           'excluded': ['core', 'log', 'auth']})
