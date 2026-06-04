from datetime import timedelta
from django.db import models
from django.core.exceptions import ValidationError
from providers.models import Platform
from emails.models import Email


class Account(models.Model):
    """Cuenta de streaming en inventario (comprada a proveedor)."""

    class Status(models.TextChoices):
        ACTIVO = "activo", "Activo"
        POR_VENCER = "por_vencer", "Por vencer"
        VENCIDA = "vencida", "Vencida"
        CAIDA = "caida", "Caída"

    email = models.ForeignKey(
        Email,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        verbose_name="correo",
        related_name="accounts",
    )
    platform = models.ForeignKey(
        Platform,
        on_delete=models.CASCADE,
        verbose_name="plataforma",
        related_name="accounts",
    )
    max_screens = models.PositiveSmallIntegerField(
        "capacidad pantallas", default=1
    )
    credentials = models.CharField(
        "credenciales", max_length=255, blank=True, null=True
    )
    status = models.CharField(
        "estado",
        max_length=10,
        choices=Status.choices,
        default=Status.ACTIVO,
    )
    purchase_price = models.DecimalField(
        "precio compra", max_digits=10, decimal_places=2, blank=True, null=True
    )
    fecha_compra = models.DateField("fecha compra", blank=True, null=True)
    fecha_pago = models.DateField("fecha pago", blank=True, null=True)
    fecha_corte = models.DateField("fecha corte", blank=True, null=True)
    observaciones = models.TextField("observaciones", blank=True, null=True)
    notes = models.TextField("notas", blank=True, null=True)
    is_active = models.BooleanField("activo", default=True)
    created_at = models.DateTimeField("creado", auto_now_add=True)
    updated_at = models.DateTimeField("actualizado", auto_now=True)

    class Meta:
        managed = False
        db_table = "accounts"
        verbose_name = "cuenta"
        verbose_name_plural = "cuentas"
        ordering = ["-created_at"]

    def __str__(self):
        plat = self.platform.name if self.platform else "?"
        return f"{plat} #{self.id} — {self.get_status_display()}"

    def save(self, *args, **kwargs):
        """Auto-calcula fecha_pago si no está definida."""
        if self.fecha_compra and not self.fecha_pago:
            self.fecha_pago = self.fecha_compra + timedelta(days=28)
        if self.fecha_compra and not self.fecha_corte:
            self.fecha_corte = self.fecha_compra + timedelta(days=30)
        super().save(*args, **kwargs)

    @property
    def screens_count(self):
        """Cantidad de pantallas asociadas."""
        return self.screens.count()

    @property
    def available_screens(self):
        """Pantallas disponibles para vender."""
        return self.screens.filter(status="disponible").count()

    @property
    def sold_screens(self):
        """Pantallas vendidas."""
        return self.screens.exclude(status="disponible").count()

    def clean(self):
        if self.max_screens < 1 or self.max_screens > 5:
            raise ValidationError({"max_screens": "La capacidad debe ser entre 1 y 5 pantallas."})
