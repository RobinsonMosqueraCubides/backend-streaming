from django.contrib import admin
from .models import Screen


@admin.register(Screen)
class ScreenAdmin(admin.ModelAdmin):
    list_display = ["id", "account", "customer", "pin", "status", "fecha_inicio"]
    list_filter = ["status"]
    search_fields = ["pin", "profile_name"]
    raw_id_fields = ["account", "customer"]
