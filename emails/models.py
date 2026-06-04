from django.db import models
from providers.models import Provider


class Email(models.Model):
    """Correo Gmail que el negocio controla."""

    email = models.EmailField(max_length=255)
    password = models.CharField("contraseña", max_length=255, blank=True, null=True)
    verification_email = models.EmailField(
        "correo verificación", max_length=255, blank=True, null=True
    )
    last_login = models.DateField("último ingreso", blank=True, null=True)
    requires_validation = models.BooleanField(
        "pide validación", blank=True, null=True
    )
    owner_name = models.CharField("nombre titular", max_length=255, blank=True, null=True)
    birth_date = models.DateField("fecha nacimiento", blank=True, null=True)
    gender = models.CharField("sexo", max_length=20, blank=True, null=True)
    provider = models.ForeignKey(
        Provider,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        verbose_name="proveedor",
        related_name="emails",
    )
    notes = models.TextField("notas", blank=True, null=True)
    is_active = models.BooleanField("activo", default=True)
    created_at = models.DateTimeField("creado", auto_now_add=True)
    updated_at = models.DateTimeField("actualizado", auto_now=True)

    class Meta:
        managed = False
        db_table = "emails"
        verbose_name = "correo"
        verbose_name_plural = "correos"
        ordering = ["email"]

    def __str__(self):
        return self.email
