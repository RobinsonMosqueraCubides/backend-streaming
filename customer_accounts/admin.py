from django.contrib import admin
from .models import CustomerAccount


@admin.register(CustomerAccount)
class CustomerAccountAdmin(admin.ModelAdmin):
    list_display = ["id", "account", "customer", "status", "fecha_inicio"]
    list_filter = ["status"]
    search_fields = ["contraseña", "profile_name"]
    raw_id_fields = ["account", "customer"]
