from django.contrib import admin
from .models import Order


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ["id", "customer", "total", "status", "fecha_inicio", "fecha_corte", "created_at"]
    list_filter = ["status", "fecha_inicio"]
    search_fields = ["customer__name", "observaciones"]
    date_hierarchy = "created_at"
