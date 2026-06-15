from datetime import timedelta
from decimal import Decimal
from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone

from accounts.models import Account
from emails.models import Email
from screens.models import Screen
from customer_accounts.models import CustomerAccount
from .models import ProviderWarrantyClaim


@transaction.atomic
def apply_provider_warranty(
    *,
    account_id,
    claim_type,
    fecha_reclamo=None,
    new_credentials=None,
    new_email_password=None,
    new_email_address=None,
    replacement_duration_days=None,
    notes=None,
):
    """
    Registra una reclamación de garantía ante el proveedor por una cuenta fallida.
    """
    # 1. Obtener la cuenta y el proveedor
    account = Account.objects.select_for_update().get(pk=account_id)
    if not account.email or not account.email.provider:
        raise ValidationError("La cuenta seleccionada no está asociada a ningún proveedor.")
    
    provider = account.email.provider

    if not fecha_reclamo:
        fecha_reclamo = timezone.now().date()
    elif isinstance(fecha_reclamo, str):
        fecha_reclamo = timezone.datetime.strptime(fecha_reclamo, "%Y-%m-%d").date()

    # 2. Calcular días restantes y saldo a favor proporcional
    purchase_price = account.purchase_price or Decimal("0.00")
    fecha_corte = account.fecha_corte or (account.fecha_compra + timedelta(days=30) if account.fecha_compra else fecha_reclamo)

    total_days = 30  # Asumimos ciclo estándar de 30 días
    remaining_days = (fecha_corte - fecha_reclamo).days
    
    if remaining_days < 0:
        remaining_days = 0
    elif remaining_days > total_days:
        remaining_days = total_days

    calculated_credit = Decimal("0.00")
    if remaining_days > 0 and purchase_price > 0:
        calculated_credit = (purchase_price / Decimal(str(total_days))) * Decimal(remaining_days)
        # Redondear a 2 decimales
        calculated_credit = calculated_credit.quantize(Decimal("0.01"))

    claim = ProviderWarrantyClaim(
        account=account,
        provider=provider,
        claim_type=claim_type,
        fecha_reclamo=fecha_reclamo,
        purchase_price=purchase_price,
        fecha_corte=fecha_corte,
        remaining_days=remaining_days,
        notes=notes,
    )

    # 3. Ejecutar acciones según el tipo de reclamo
    if claim_type == "password_change":
        if not new_credentials:
            raise ValidationError("Debe proporcionar la nueva contraseña de la cuenta.")
        
        # Actualizar credenciales de la cuenta
        account.credentials = new_credentials
        account.status = Account.Status.DISPONIBLE
        account.save(update_fields=["credentials", "status", "updated_at"])

        # Si se pasa nueva contraseña del correo, actualizar el modelo Email
        if new_email_password:
            email_obj = account.email
            email_obj.password = new_email_password
            email_obj.save(update_fields=["password", "updated_at"])

        claim.new_credentials = new_credentials

    elif claim_type == "account_replacement":
        if not new_credentials:
            raise ValidationError("Debe proporcionar las credenciales de la cuenta de reemplazo.")
        if not new_email_address:
            raise ValidationError("Debe proporcionar el correo de la cuenta de reemplazo.")

        # Marcar la cuenta original como caída/vencida
        account.status = Account.Status.NO_DISPONIBLE
        account.is_active = False
        account.save(update_fields=["status", "is_active", "updated_at"])

        # Crear nuevo Email
        new_email_obj = Email.objects.create(
            email=new_email_address,
            password=new_email_password or "Reemplazo",
            provider=provider,
            is_active=True,
        )

        # Determinar fechas para la nueva cuenta
        new_fecha_compra = fecha_reclamo
        if replacement_duration_days is not None:
            new_fecha_corte = fecha_reclamo + timedelta(days=int(replacement_duration_days))
        else:
            new_fecha_corte = fecha_reclamo + timedelta(days=remaining_days)
        
        new_fecha_pago = new_fecha_corte - timedelta(days=2)

        # Crear nueva Account
        new_account = Account.objects.create(
            email=new_email_obj,
            platform=account.platform,
            max_screens=account.max_screens,
            credentials=new_credentials,
            status=Account.Status.DISPONIBLE,
            purchase_price=Decimal("0.00"),  # Costo 0 porque es un reemplazo de garantía
            fecha_compra=new_fecha_compra,
            fecha_pago=new_fecha_pago,
            fecha_corte=new_fecha_corte,
            observaciones=f"Reemplazo de cuenta #{account.id}. Reclamo #{claim.id if claim.id else ''}",
            is_active=True,
        )

        # Migrar pantallas y cuentas de cliente activas
        Screen.objects.filter(account=account, status__in=["activo", "por_vencer"]).update(account=new_account)
        CustomerAccount.objects.filter(account=account, status__in=["activo", "por_vencer"]).update(account=new_account)

        claim.replacement_account = new_account
        claim.new_credentials = new_credentials

    elif claim_type == "store_credit":
        # Marcar la cuenta original como caída/vencida
        account.status = Account.Status.NO_DISPONIBLE
        account.is_active = False
        account.save(update_fields=["status", "is_active", "updated_at"])
        claim.calculated_credit = calculated_credit

    else:
        raise ValidationError(f"Tipo de reclamo no válido: {claim_type}")

    claim.save()
    return claim
