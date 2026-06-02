from django.db import models
from datetime import timedelta


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
    observaciones = models.TextField("observaciones", blank=True, null=True)
    created_at = models.DateTimeField("creado", auto_now_add=True)
    updated_at = models.DateTimeField("actualizado", auto_now=True)

    class Meta:
        managed = False
        db_table = "customer_accounts"
        verbose_name = "cuenta de cliente"
        verbose_name_plural = "cuentas de clientes"
        ordering = ["-created_at"]

    def __str__(self):
        acc = self.account_id or "?"
        cli = self.customer.name if self.customer else "?"
        return f"Cuenta #{acc} → {cli} ({self.get_status_display()})"

    @property
    def fecha_cobro(self):
        """Fecha de cobro: 29 días después del inicio."""
        if self.fecha_inicio:
            return self.fecha_inicio + timedelta(days=29)
        return None

    @property
    def fecha_corte(self):
        """Fecha de corte: 30 días después del inicio."""
        if self.fecha_inicio:
            return self.fecha_inicio + timedelta(days=30)
        return None
