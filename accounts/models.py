from datetime import timedelta
from django.db import models
from django.core.exceptions import ValidationError
from providers.models import Platform
from emails.models import Email


class Account(models.Model):
    """Cuenta de streaming en inventario (comprada a proveedor)."""

    class Status(models.TextChoices):
        DISPONIBLE = "disponible", "Disponible"
        NO_DISPONIBLE = "no_disponible", "No disponible"
        POR_VENCER = "por_vencer", "Por vencer"
        VENCIDA = "vencida", "Vencida"

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
        max_length=20,
        choices=Status.choices,
        default=Status.DISPONIBLE,
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

    def recalculate_status(self):
        from django.utils import timezone
        from datetime import datetime, date

        def _to_date(val):
            if not val:
                return None
            if isinstance(val, str):
                try:
                    return datetime.strptime(val, "%Y-%m-%d").date()
                except ValueError:
                    return None
            return val

        hoy = timezone.now().date()
        corte = _to_date(self.fecha_corte)
        pago = _to_date(self.fecha_pago)

        # Si la cuenta está inactiva
        if hasattr(self, "is_active") and not self.is_active:
            return self.Status.NO_DISPONIBLE

        # 1. Si la fecha de corte es hoy o ya pasó
        if corte and hoy >= corte:
            return self.Status.VENCIDA

        # 2. Si la fecha de cobro es hoy (o ya estamos en esa fecha, pero antes de la de corte)
        if pago and pago <= hoy and (not corte or hoy < corte):
            return self.Status.POR_VENCER

        # Si no se ha guardado (no tiene pk), no podemos consultar relaciones
        if not self.pk:
            return self.Status.DISPONIBLE

        # 3. Si se vendió completa
        if self.customer_accounts.exclude(status__in=["vencida", "caida"]).exists():
            return self.Status.NO_DISPONIBLE

        # 4. Si se vendieron todas las pantallas
        active_screens_count = self.screens.filter(status__in=["activo", "por_vencer"]).count()
        if active_screens_count >= self.max_screens:
            return self.Status.NO_DISPONIBLE

        return self.Status.DISPONIBLE

    def save(self, *args, **kwargs):
        """Auto-calcula fechas y estado."""
        if self.fecha_compra and not self.fecha_pago:
            self.fecha_pago = self.fecha_compra + timedelta(days=28)
        if self.fecha_compra and not self.fecha_corte:
            self.fecha_corte = self.fecha_compra + timedelta(days=30)
        
        # Asignar estado calculado dinámicamente antes de guardar
        self.status = self.recalculate_status()
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
