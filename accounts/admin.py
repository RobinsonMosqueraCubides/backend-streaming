from django.contrib import admin
from .models import Account
from screens.models import Screen


class ScreenInline(admin.TabularInline):
    model = Screen
    extra = 0
    fields = ["pin", "profile_name", "status", "fecha_inicio"]
    readonly_fields = ["fecha_cobro", "fecha_corte"]
    show_change_link = True


@admin.register(Account)
class AccountAdmin(admin.ModelAdmin):
    list_display = [
        "id", "platform", "email", "status", "max_screens", "is_active"
    ]
    list_filter = ["status", "platform", "provider", "is_active"]
    search_fields = ["credentials", "observaciones"]
    inlines = [ScreenInline]

    def get_queryset(self, request):
        return super().get_queryset(request).select_related("platform", "email")
