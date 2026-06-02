from django.contrib import admin
from .models import Platform, Provider


@admin.register(Platform)
class PlatformAdmin(admin.ModelAdmin):
    list_display = ["id", "name"]
    search_fields = ["name"]


@admin.register(Provider)
class ProviderAdmin(admin.ModelAdmin):
    list_display = ["id", "name", "contact", "phone"]
    search_fields = ["name", "contact"]
