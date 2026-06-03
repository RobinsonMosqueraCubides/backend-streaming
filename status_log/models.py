from django.db import models


class StatusLog(models.Model):
    """Registro de cambios de estado en cuentas, pantallas y cuentas_cliente."""

    model_name = models.CharField("modelo", max_length=50)
    object_id = models.IntegerField("ID objeto")
    old_status = models.CharField("estado anterior", max_length=20, blank=True, null=True)
    new_status = models.CharField("estado nuevo", max_length=20)
    changed_at = models.DateTimeField("cambiado", auto_now_add=True)

    class Meta:
        managed = False
        db_table = "status_log"
        verbose_name = "registro de cambio"
        verbose_name_plural = "registros de cambios"
        ordering = ["-changed_at"]

    def __str__(self):
        return f"{self.model_name}#{self.object_id}: {self.old_status} → {self.new_status}"
