from django.db import models


class Order(models.Model):
    """Orden de compra — agrupa pantallas y/o cuentas vendidas a un cliente."""

    class Status(models.TextChoices):
        ACTIVO = "activo", "Activo"
        POR_COBRAR = "por_cobrar", "Por cobrar"
        POR_VENCER = "por_vencer", "Por vencer"
        POR_CORTAR = "por_cortar", "Por cortar"
        VENCIDA = "vencida", "Vencida"
        CAIDA = "caida", "Caída"

    customer = models.ForeignKey(
        "customers.Customer",
        on_delete=models.CASCADE,
        verbose_name="cliente",
        related_name="orders",
    )
    total = models.DecimalField(
        "total", max_digits=10, decimal_places=2, blank=True, null=True
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
        db_table = "orders"
        verbose_name = "orden"
        verbose_name_plural = "órdenes"
        ordering = ["-created_at"]

    def __str__(self):
        cli = self.customer.name if self.customer else "?"
        return f"Orden #{self.id} → {cli} ({self.get_status_display()})"

    @property
    def items_count(self):
        """Cantidad de items (screens + customer_accounts) en la orden."""
        return self.screens.count() + self.customer_accounts.count()

    @property
    def total_calculado(self):
        """Suma real de los items."""
        scr_total = self.screens.aggregate(s=models.Sum("precio_venta"))["s"] or 0
        ca_total = self.customer_accounts.aggregate(s=models.Sum("precio_venta"))["s"] or 0
        return scr_total + ca_total


class WarrantyClaim(models.Model):
    """Garantia o reemplazo aplicado sobre un item vendido."""

    class Status(models.TextChoices):
        ABIERTA = "abierta", "Abierta"
        RESUELTA = "resuelta", "Resuelta"
        RECHAZADA = "rechazada", "Rechazada"

    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        verbose_name="orden",
        related_name="warranty_claims",
    )
    original_screen = models.ForeignKey(
        "screens.Screen",
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        verbose_name="pantalla original",
        related_name="warranty_claims_original",
    )
    original_customer_account = models.ForeignKey(
        "customer_accounts.CustomerAccount",
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        verbose_name="cuenta cliente original",
        related_name="warranty_claims_original",
    )
    replacement_screen = models.ForeignKey(
        "screens.Screen",
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        verbose_name="pantalla reemplazo",
        related_name="warranty_claims_replacement",
    )
    replacement_customer_account = models.ForeignKey(
        "customer_accounts.CustomerAccount",
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        verbose_name="cuenta cliente reemplazo",
        related_name="warranty_claims_replacement",
    )
    reason = models.TextField("motivo", blank=True, null=True)
    status = models.CharField(
        "estado",
        max_length=10,
        choices=Status.choices,
        default=Status.ABIERTA,
    )
    created_at = models.DateTimeField("creado", auto_now_add=True)
    resolved_at = models.DateTimeField("resuelto", blank=True, null=True)

    class Meta:
        managed = False
        db_table = "warranty_claims"
        verbose_name = "garantia"
        verbose_name_plural = "garantias"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Garantia #{self.id} - Orden #{self.order_id}"
