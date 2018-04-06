from django.contrib.auth.models import Permission

for perm in Permission.objects.all():
  perm.delete()
