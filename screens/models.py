from django.db import models
from django.core.validators import RegexValidator
from django.core.exceptions import ValidationError
from datetime import timedelta


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
    pin = models.CharField(
        "PIN",
        max_length=4,
        validators=[RegexValidator(r"^\d{4}$", "El PIN debe tener exactamente 4 dígitos.")],
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

    def __str__(self):
        acc = self.account_id or "?"
        return f"Pantalla #{self.id} (Cuenta #{acc}) — {self.get_status_display()}"

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
