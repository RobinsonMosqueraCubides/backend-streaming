from datetime import date
from decimal import Decimal

import pytest
from django.core.exceptions import ValidationError

pytestmark = pytest.mark.django_db


class TestSellOrderFlow:
    def test_sell_screen_creates_order_and_item(self, account, customer):
        from orders.services import sell_order
        from screens.models import Screen

        order, created = sell_order(
            customer_id=customer,
            fecha_inicio=date(2026, 6, 1),
            items=[
                {
                    "type": "screen",
                    "account_id": account,
                    "pin": "4321",
                    "precio_venta": Decimal("12000.00"),
                }
            ],
        )

        assert order.total == Decimal("12000.00")
        assert order.fecha_cobro == date(2026, 6, 30)
        assert order.fecha_corte == date(2026, 7, 1)
        assert len(created["screens"]) == 1
        assert Screen.objects.filter(order=order, pin="4321", status="activo").exists()

    def test_rejects_screen_when_capacity_is_full(self, account, customer):
        from orders.services import sell_order
        from screens.models import Screen

        for pin in ["1111", "2222", "3333", "4444"]:
            Screen.objects.create(
                account_id=account,
                customer_id=customer,
                pin=pin,
                status="activo",
                fecha_inicio=date(2026, 6, 1),
            )

        with pytest.raises(ValidationError, match="pantallas disponibles"):
            sell_order(
                customer_id=customer,
                fecha_inicio=date(2026, 6, 1),
                items=[
                    {
                        "type": "screen",
                        "account_id": account,
                        "pin": "5555",
                        "precio_venta": Decimal("12000.00"),
                    }
                ],
            )

    def test_rejects_full_account_with_active_screen(self, account, customer, screen):
        from orders.services import sell_order

        with pytest.raises(ValidationError, match="pantallas activas"):
            sell_order(
                customer_id=customer,
                fecha_inicio=date(2026, 6, 1),
                items=[
                    {
                        "type": "customer_account",
                        "account_id": account,
                        "contrasena": "secret123",
                        "precio_venta": Decimal("30000.00"),
                    }
                ],
            )


class TestWarrantyFlow:
    def test_warranty_marks_original_as_caida(self, screen):
        from orders.models import Order
        from orders.services import apply_warranty
        from screens.models import Screen

        original = Screen.objects.get(pk=screen)
        order = Order.objects.create(
            customer=original.customer,
            total=original.precio_venta or 0,
            status="activo",
            fecha_inicio=original.fecha_inicio,
            fecha_cobro=original.fecha_cobro,
            fecha_corte=original.fecha_corte,
        )
        original.order = order
        original.save(update_fields=["order"])

        claim = apply_warranty(
            order_id=order.id,
            original_type="screen",
            original_id=original.id,
            reason="No funciona",
        )

        original.refresh_from_db()
        assert original.status == "caida"
        assert claim.original_screen_id == original.id
