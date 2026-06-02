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
    created_at = models.DateTimeField("creado", auto_now_add=True)

    class Meta:
        managed = False
        db_table = "providers"
        verbose_name = "proveedor"
        verbose_name_plural = "proveedores"
        ordering = ["name"]

    def __str__(self):
        return self.name
