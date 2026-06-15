from django.db import models
from django.core.validators import RegexValidator


class Platform(models.Model):
    """Catálogo de plataformas de streaming."""

    name = models.CharField("nombre", max_length=50, unique=True)

    class Meta:
        managed = False
        db_table = "platforms"
        verbose_name = "plataforma"
        verbose_name_plural = "plataformas"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Provider(models.Model):
    """Proveedor que vende cuentas de streaming."""

    name = models.CharField("nombre", max_length=255)
    contact = models.CharField("contacto", max_length=255, blank=True, null=True)
    phone = models.CharField("teléfono", max_length=30, blank=True, null=True)
    notes = models.TextField("notas", blank=True, null=True)
    observaciones = models.TextField("observaciones", blank=True, null=True)
    created_at = models.DateTimeField("creado", auto_now_add=True)

    class Meta:
        managed = False
        db_table = "providers"
        verbose_name = "proveedor"
        verbose_name_plural = "proveedores"
        ordering = ["name"]

    def __str__(self):
        return self.name


class ProviderWarrantyClaim(models.Model):
    """Reclamación de garantía a un proveedor por una cuenta fallida."""

    class ClaimType(models.TextChoices):
        PASSWORD_CHANGE = "password_change", "Cambio de contraseña"
        ACCOUNT_REPLACEMENT = "account_replacement", "Reemplazo de cuenta"
        STORE_CREDIT = "store_credit", "Saldo a favor"

    account = models.ForeignKey(
        "accounts.Account",
        on_delete=models.CASCADE,
        related_name="provider_warranties",
        verbose_name="cuenta original",
    )
    provider = models.ForeignKey(
        Provider,
        on_delete=models.CASCADE,
        related_name="warranty_claims",
        verbose_name="proveedor",
    )
    claim_type = models.CharField(
        "tipo de reclamo",
        max_length=20,
        choices=ClaimType.choices,
    )
    fecha_reclamo = models.DateField("fecha de reclamo")
    purchase_price = models.DecimalField(
        "precio compra original", max_digits=10, decimal_places=2
    )
    fecha_corte = models.DateField("fecha corte original")
    remaining_days = models.IntegerField("días restantes")
    calculated_credit = models.DecimalField(
        "saldo a favor calculado", max_digits=10, decimal_places=2, default=0.00
    )
    new_credentials = models.CharField(
        "nuevas credenciales/contraseña", max_length=255, blank=True, null=True
    )
    replacement_account = models.ForeignKey(
        "accounts.Account",
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name="warranty_replacements",
        verbose_name="cuenta de reemplazo",
    )
    notes = models.TextField("notas", blank=True, null=True)
    created_at = models.DateTimeField("creado", auto_now_add=True)

    class Meta:
        managed = False
        db_table = "provider_warranty_claims"
        verbose_name = "garantía de proveedor"
        verbose_name_plural = "garantías de proveedores"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Garantía Proveedor #{self.id} — {self.provider.name} ({self.get_claim_type_display()})"

