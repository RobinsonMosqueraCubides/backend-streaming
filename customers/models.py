from django.db import models


class Customer(models.Model):
    """Cliente que compra pantallas o cuentas."""

    name = models.CharField("nombre", max_length=255)
    phone = models.CharField("teléfono", max_length=30)
    notes = models.TextField("notas", blank=True, null=True)
    created_at = models.DateTimeField("creado", auto_now_add=True)
    updated_at = models.DateTimeField("actualizado", auto_now=True)

    class Meta:
        managed = False
        db_table = "customers"
        verbose_name = "cliente"
        verbose_name_plural = "clientes"
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} — {self.phone}"
