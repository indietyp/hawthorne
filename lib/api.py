from django.contrib.auth.models import Permission
from django.db.models import F


class InsufficientPrivileges(Exception):
  pass


class PermissionUtils:

  @classmethod
  def assign(cls, request, permissions):
    base = Permission.objects.all()\
                             .annotate(encoded=(F('content_type__app_label') +
                                                '.' +
                                                F('codename')))\
                             .filter(encoded__in=request.user.get_all_permissions())

    exceptions = []
    perms = []
    for permission in permissions:
      permission = permission.split('.')
      p = base.filter(content_type__app_label=permission[0], codename=permission[1])

      if not p:
        exceptions.append('.'.join(permission))

      perms.extend(p)

    if exceptions:
      raise InsufficientPrivileges(('Requested user does not have permissions {} and '
                                    'cannot assign them.').format(','.join(exceptions)))

    return perms
