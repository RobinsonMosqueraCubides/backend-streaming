from django.db import models


class CobroEstado(models.Model):
    """Estado de envío de mensajes de WhatsApp por orden."""

    order = models.OneToOneField(
        "orders.Order",
        on_delete=models.CASCADE,
        verbose_name="orden",
        related_name="cobro_estado",
    )
    aviso_enviado = models.BooleanField("aviso enviado", default=False)
    notificacion_enviada = models.BooleanField("notificación enviada", default=False)
    corte_enviado = models.BooleanField("corte enviado", default=False)
    created_at = models.DateTimeField("creado", auto_now_add=True)
    updated_at = models.DateTimeField("actualizado", auto_now=True)

    class Meta:
        managed = False
        db_table = "cobro_estado"
        verbose_name = "estado de cobro"
        verbose_name_plural = "estados de cobro"

    def __str__(self):
        return f"Cobro Orden#{self.order_id}"

    @property
    def siguiente_accion(self):
        """Retorna la siguiente acción permitida o None si ya se enviaron todas."""
        if not self.aviso_enviado:
            return "aviso"
        if not self.notificacion_enviada:
            return "notificacion"
        if not self.corte_enviado:
            return "corte"
        return None
