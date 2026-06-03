from django.apps import AppConfig


class StatusLogConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "status_log"
    verbose_name = "Historial de cambios"

    def ready(self):
        import status_log.signals  # noqa
