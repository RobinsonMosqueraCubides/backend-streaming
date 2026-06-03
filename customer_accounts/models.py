from datetime import timedelta
from django.db import models


class CustomerAccount(models.Model):
    """Cuenta completa vendida a un cliente (en vez de pantalla individual)."""

    class Status(models.TextChoices):
        ACTIVO = "activo", "Activo"
        POR_VENCER = "por_vencer", "Por vencer"
        VENCIDA = "vencida", "Vencida"
        CAIDA = "caida", "Caída"

    account = models.ForeignKey(
        "accounts.Account",
        on_delete=models.CASCADE,
        verbose_name="cuenta",
        related_name="customer_accounts",
    )
    customer = models.ForeignKey(
        "customers.Customer",
        on_delete=models.CASCADE,
        verbose_name="cliente",
        related_name="customer_accounts",
    )
    contraseña = models.CharField("contraseña", max_length=255)
    precio_venta = models.DecimalField(
        "precio venta", max_digits=10, decimal_places=2, blank=True, null=True
    )
    profile_name = models.CharField(
        "nombre perfil", max_length=255, blank=True, null=True
    )
    status = models.CharField(
        "estado",
        max_length=10,
        choices=Status.choices,
        default=Status.ACTIVO,
    )
    fecha_inicio = models.DateField("fecha inicio", blank=True, null=True)
    fecha_cobro = models.DateField("fecha cobro", blank=True, null=True)
    fecha_corte = models.DateField("fecha corte", blank=True, null=True)
    observaciones = models.TextField("observaciones", blank=True, null=True)
    created_at = models.DateTimeField("creado", auto_now_add=True)
    updated_at = models.DateTimeField("actualizado", auto_now=True)

    class Meta:
        managed = False
        db_table = "customer_accounts"
        verbose_name = "cuenta de cliente"
        verbose_name_plural = "cuentas de clientes"
        ordering = ["-created_at"]

    def save(self, *args, **kwargs):
        """Auto-calcula fecha_cobro y fecha_corte si no están definidas."""
        if self.fecha_inicio:
            if not self.fecha_cobro:
                self.fecha_cobro = self.fecha_inicio + timedelta(days=29)
            if not self.fecha_corte:
                self.fecha_corte = self.fecha_inicio + timedelta(days=30)
        super().save(*args, **kwargs)

    def __str__(self):
        acc = self.account_id or "?"
        cli = self.customer.name if self.customer else "?"
        return f"Cuenta #{acc} → {cli} ({self.get_status_display()})"
