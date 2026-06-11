from datetime import timedelta
from decimal import Decimal

from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone

from accounts.models import Account
from customer_accounts.models import CustomerAccount
from screens.models import Screen

from .models import Order, WarrantyClaim


ACTIVE_ITEM_STATUSES = ["activo", "por_vencer"]


def _money(value):
    return Decimal(str(value or 0))


def _dates(fecha_inicio):
    if not fecha_inicio:
        return None, None
    return fecha_inicio + timedelta(days=29), fecha_inicio + timedelta(days=30)


def _validate_screen_capacity(account):
    active_screens = Screen.objects.filter(
        account=account,
        status__in=ACTIVE_ITEM_STATUSES,
    ).count()
    sold_full_account = CustomerAccount.objects.filter(
        account=account,
        status__in=ACTIVE_ITEM_STATUSES,
    ).exists()

    if sold_full_account:
        raise ValidationError("No se puede vender una pantalla de una cuenta vendida completa.")
    if active_screens >= account.max_screens:
        raise ValidationError("La cuenta no tiene pantallas disponibles.")


def _validate_full_account_available(account):
    active_screens = Screen.objects.filter(
        account=account,
        status__in=ACTIVE_ITEM_STATUSES,
    ).exists()
    active_customer_account = CustomerAccount.objects.filter(
        account=account,
        status__in=ACTIVE_ITEM_STATUSES,
    ).exists()

    if active_screens:
        raise ValidationError("No se puede vender completa una cuenta con pantallas activas.")
    if active_customer_account:
        raise ValidationError("La cuenta ya fue vendida completa.")


def _create_screen(order, customer_id, item, fecha_inicio, fecha_cobro, fecha_corte):
    account = Account.objects.select_for_update().get(pk=item["account_id"])
    _validate_screen_capacity(account)

    return Screen.objects.create(
        account=account,
        customer_id=customer_id,
        order=order,
        pin=item["pin"],
        precio_venta=item.get("precio_venta"),
        profile_name=item.get("profile_name"),
        status="activo",
        fecha_inicio=fecha_inicio,
        fecha_cobro=fecha_cobro,
        fecha_corte=fecha_corte,
        observaciones=item.get("observaciones"),
        notes=item.get("notes"),
    )


def _create_customer_account(order, customer_id, item, fecha_inicio, fecha_cobro, fecha_corte):
    account = Account.objects.select_for_update().get(pk=item["account_id"])
    _validate_full_account_available(account)

    return CustomerAccount.objects.create(
        account=account,
        customer_id=customer_id,
        order=order,
        contrasena=item["contrasena"],
        precio_venta=item.get("precio_venta"),
        profile_name=item.get("profile_name"),
        status="activo",
        fecha_inicio=fecha_inicio,
        fecha_cobro=fecha_cobro,
        fecha_corte=fecha_corte,
        observaciones=item.get("observaciones"),
    )


@transaction.atomic
def sell_order(*, customer_id, fecha_inicio, items, observaciones=None):
    if not items:
        raise ValidationError("La venta debe tener al menos un item.")

    fecha_cobro, fecha_corte = _dates(fecha_inicio)
    total = sum(_money(item.get("precio_venta")) for item in items)

    order = Order.objects.create(
        customer_id=customer_id,
        total=total,
        status="activo",
        fecha_inicio=fecha_inicio,
        fecha_cobro=fecha_cobro,
        fecha_corte=fecha_corte,
        observaciones=observaciones,
    )

    created = {"screens": [], "customer_accounts": []}
    for item in items:
        if item["type"] == "screen":
            created["screens"].append(
                _create_screen(order, customer_id, item, fecha_inicio, fecha_cobro, fecha_corte)
            )
        elif item["type"] == "customer_account":
            created["customer_accounts"].append(
                _create_customer_account(order, customer_id, item, fecha_inicio, fecha_cobro, fecha_corte)
            )
        else:
            raise ValidationError(f"Tipo de item no soportado: {item['type']}")

    return order, created


@transaction.atomic
def apply_warranty(
    *,
    order_id,
    original_type,
    original_id,
    reason=None,
    replacement_item=None,
):
    order = Order.objects.select_for_update().get(pk=order_id)

    claim = WarrantyClaim(order=order, reason=reason)
    if original_type == "screen":
        original = Screen.objects.select_for_update().get(pk=original_id, order=order)
        original.status = "caida"
        original.save(update_fields=["status", "updated_at"])
        claim.original_screen = original
    elif original_type == "customer_account":
        original = CustomerAccount.objects.select_for_update().get(pk=original_id, order=order)
        original.status = "caida"
        original.save(update_fields=["status", "updated_at"])
        claim.original_customer_account = original
    else:
        raise ValidationError("original_type debe ser screen o customer_account.")

    if replacement_item:
        fecha_inicio = order.fecha_inicio or timezone.now().date()
        fecha_cobro = order.fecha_cobro
        fecha_corte = order.fecha_corte
        if replacement_item["type"] == "screen":
            claim.replacement_screen = _create_screen(
                order,
                order.customer_id,
                replacement_item,
                fecha_inicio,
                fecha_cobro,
                fecha_corte,
            )
        elif replacement_item["type"] == "customer_account":
            claim.replacement_customer_account = _create_customer_account(
                order,
                order.customer_id,
                replacement_item,
                fecha_inicio,
                fecha_cobro,
                fecha_corte,
            )
        else:
            raise ValidationError("El reemplazo debe ser screen o customer_account.")
        claim.status = "resuelta"
        claim.resolved_at = timezone.now()

    claim.save()
    return claim
