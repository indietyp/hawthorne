from django.contrib import admin
from core import models


class CountryAdmin(admin.ModelAdmin):

    list_display = ('code', 'name', 'created_at', 'updated_at')
    list_filter = ('created_at', 'updated_at')
    search_fields = ('name',)
    date_hierarchy = 'created_at'


class UserAdmin(admin.ModelAdmin):

    list_display = (
        'username',
        'ingame',
        'steam',
        'first_name',
        'last_name',
        'is_superuser',
        'is_staff',
        'is_active',
        'ip',
        'country',
    )
    list_filter = (
        'is_superuser',
        'is_staff',
        'is_active',
        'steam',
    )


class TokenAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'created_at',
        'updated_at',
        'owner',
        'is_active',
        'is_anonymous',
        'is_superuser',
    )
    list_filter = (
        'created_at',
        'updated_at',
        'owner',
        'is_active',
        'is_anonymous',
        'is_superuser',
    )
    date_hierarchy = 'created_at'


class UserLogIPAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'created_at',
        'updated_at',
        'user',
        'ip',
        'connections',
        'active',
        'last_used',
    )
    list_filter = ('created_at', 'updated_at', 'user', 'active', 'last_used')
    date_hierarchy = 'created_at'


class UserLogTimeAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'created_at',
        'updated_at',
        'user',
        'server',
        'connected',
        'disconnected',
    )
    list_filter = (
        'created_at',
        'updated_at',
        'user',
        'server',
        'connected',
        'disconnected',
    )
    date_hierarchy = 'created_at'


class UserLogUsernameAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'created_at',
        'updated_at',
        'user',
        'username',
        'connections',
        'last_used',
    )
    list_filter = ('created_at', 'updated_at', 'user', 'last_used')
    date_hierarchy = 'created_at'


class ServerPermissionAdmin(admin.ModelAdmin):

    list_display = (
        'can_reservation',
        'can_generic',
        'can_kick',
        'can_ban',
        'can_slay',
        'can_map',
        'can_config',
        'can_cvar',
        'can_chat',
        'can_vote',
        'can_password',
        'can_rcon',
        'can_cheat',
    )
    list_filter = (
        'created_at',
        'updated_at',
        'can_reservation',
        'can_generic',
        'can_kick',
        'can_ban',
        'can_slay',
        'can_map',
        'can_config',
        'can_cvar',
        'can_chat',
        'can_vote',
        'can_password',
        'can_rcon',
        'can_cheat',
    )
    date_hierarchy = 'created_at'


class ServerGroupAdmin(admin.ModelAdmin):

    list_display = (
        'name',
        'flags',
        'immunity',
        'usetime',
        'is_admin',
    )
    list_filter = ('created_at', 'updated_at', 'flags', 'is_admin')
    search_fields = ('name',)
    date_hierarchy = 'created_at'


class ServerAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'created_at',
        'updated_at',
        'name',
        'ip',
        'port',
        'password',
    )
    list_filter = ('created_at', 'updated_at')
    search_fields = ('name',)
    date_hierarchy = 'created_at'


class BanAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'created_at',
        'updated_at',
        'user',
        'server',
        'issuer',
        'reason',
        'length',
        'resolved',
    )
    list_filter = (
        'created_at',
        'updated_at',
        'user',
        'server',
        'issuer',
        'resolved',
    )
    date_hierarchy = 'created_at'


class ChatAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'created_at',
        'updated_at',
        'user',
        'ip',
        'server',
        'message',
        'command',
    )
    list_filter = ('created_at', 'updated_at', 'user', 'server', 'command')
    date_hierarchy = 'created_at'


class MutegagAdmin(admin.ModelAdmin):

    list_display = (
        'id',
        'created_at',
        'updated_at',
        'user',
        'server',
        'issuer',
        'type',
        'reason',
        'length',
        'resolved',
    )
    list_filter = (
        'created_at',
        'updated_at',
        'user',
        'server',
        'issuer',
        'resolved',
    )
    date_hierarchy = 'created_at'


class LogAdmin(admin.ModelAdmin):

    list_display = ('id', 'created_at', 'updated_at', 'action', 'user')
    list_filter = ('created_at', 'updated_at', 'user')
    date_hierarchy = 'created_at'


def _register(model, admin_class):
    admin.site.register(model, admin_class)


_register(models.Country, CountryAdmin)
_register(models.User, UserAdmin)
_register(models.Token, TokenAdmin)
_register(models.UserLogIP, UserLogIPAdmin)
_register(models.UserLogTime, UserLogTimeAdmin)
_register(models.UserLogUsername, UserLogUsernameAdmin)
_register(models.ServerPermission, ServerPermissionAdmin)
_register(models.ServerGroup, ServerGroupAdmin)
_register(models.Server, ServerAdmin)
_register(models.Ban, BanAdmin)
_register(models.Chat, ChatAdmin)
_register(models.Mutegag, MutegagAdmin)
_register(models.Log, LogAdmin)
