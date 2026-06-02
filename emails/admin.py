from django.contrib import admin
from .models import Email


@admin.register(Email)
class EmailAdmin(admin.ModelAdmin):
    list_display = ["id", "email", "owner_name", "phone_number", "is_active", "provider"]
    list_filter = ["is_active", "provider", "requires_validation"]
    search_fields = ["email", "owner_name", "phone_number"]
