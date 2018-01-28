from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Token

admin.site.register(User, UserAdmin)


@admin.register(Token)
class TokenAdmin(admin.ModelAdmin):
  pass
