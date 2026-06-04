from datetime import timedelta
from django.db import models
from django.core.validators import RegexValidator
from django.core.exceptions import ValidationError


class Screen(models.Model):
    """Pantalla/perfil vendido a un cliente."""

    class Status(models.TextChoices):
        DISPONIBLE = "disponible", "Disponible"
        ACTIVO = "activo", "Activo"
        POR_VENCER = "por_vencer", "Por vencer"
        VENCIDA = "vencida", "Vencida"
        CAIDA = "caida", "Caída"

    account = models.ForeignKey(
        "accounts.Account",
        on_delete=models.CASCADE,
        verbose_name="cuenta",
        related_name="screens",
    )
    customer = models.ForeignKey(
        "customers.Customer",
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        verbose_name="cliente",
        related_name="screens",
    )
    order = models.ForeignKey(
        "orders.Order",
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        verbose_name="orden",
        related_name="screens",
    )
    pin = models.CharField(
        "PIN",
        max_length=4,
        validators=[RegexValidator(r"^\d{4}$", "El PIN debe tener exactamente 4 dígitos.")],
    )
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
        default=Status.DISPONIBLE,
    )
    fecha_inicio = models.DateField("fecha inicio", blank=True, null=True)
    fecha_cobro = models.DateField("fecha cobro", blank=True, null=True)
    fecha_corte = models.DateField("fecha corte", blank=True, null=True)
    observaciones = models.TextField("observaciones", blank=True, null=True)
    notes = models.TextField("notas", blank=True, null=True)
    created_at = models.DateTimeField("creado", auto_now_add=True)
    updated_at = models.DateTimeField("actualizado", auto_now=True)

    class Meta:
        managed = False
        db_table = "screens"
        verbose_name = "pantalla"
        verbose_name_plural = "pantallas"
        ordering = ["-created_at"]

    def clean(self):
        """Valida que no se exceda la capacidad de la cuenta."""
        if self.account_id and not self.pk:
            used = self.account.screens.count()
            if used >= self.account.max_screens:
                raise ValidationError(
                    f"La cuenta ya tiene {used} pantallas (máx: {self.account.max_screens})."
                )

    def save(self, *args, **kwargs):
        """Auto-calcula fechas y valida capacidad."""
        self.clean()
        if self.fecha_inicio:
            if not self.fecha_cobro:
                self.fecha_cobro = self.fecha_inicio + timedelta(days=29)
            if not self.fecha_corte:
                self.fecha_corte = self.fecha_inicio + timedelta(days=30)
        super().save(*args, **kwargs)

    def __str__(self):
        acc = self.account_id or "?"
        return f"Pantalla #{self.id} (Cuenta #{acc}) — {self.get_status_display()}"
