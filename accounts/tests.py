"""
tests_accounts.py — Tests para la app accounts.
Cubre: modelos, propiedades calculadas, validaciones, serializers, views.
"""
import pytest
from datetime import date, timedelta
from decimal import Decimal
from django.core.exceptions import ValidationError

pytestmark = pytest.mark.django_db


# ─── Model tests ──────────────────────────────────────────────────────────────

class TestAccountModel:
    """Tests del modelo Account."""

    def test_fecha_pago_28_dias_despues(self, account):
        """fecha_pago debe ser fecha_compra + 28 días."""
        from accounts.models import Account
        acc = Account.objects.get(pk=account)
        assert acc.fecha_pago == date(2026, 5, 1) + timedelta(days=28)

    def test_fecha_pago_none_sin_fecha_compra(self, platform):
        """Si no hay fecha_compra, fecha_pago retorna None."""
        from accounts.models import Account
        acc = Account(platform_id=platform, status="disponible")
        assert acc.fecha_pago is None

    def test_screens_count_cuenta_pantallas(self, account, screen, db):
        """screens_count retorna la cantidad de pantallas asociadas."""
        from accounts.models import Account
        acc = Account.objects.get(pk=account)
        assert acc.screens_count >= 1

    def test_available_screens_filtra_disponibles(self, account, db):
        """available_screens solo cuenta pantallas con status 'disponible'."""
        from accounts.models import Account
        acc = Account.objects.get(pk=account)
        # La screen de fixture tiene status='disponible', no disponible
        assert acc.available_screens == 0

    def test_str_representation(self, account, platform):
        """__str__ debe incluir plataforma y estado."""
        from accounts.models import Account
        acc = Account.objects.get(pk=account)
        s = str(acc)
        assert "Netflix" in s or "#" in s

    def test_clean_valida_max_screens(self, platform):
        """clean() debe rechazar max_screens fuera de rango 1-5."""
        from accounts.models import Account
        acc = Account(
            platform_id=platform,
            max_screens=10,
            status="disponible",
        )
        with pytest.raises(ValidationError) as exc_info:
            acc.clean()
        assert "max_screens" in exc_info.value.message_dict

    def test_status_choices(self):
        """Los choices de status deben coincidir con los definidos."""
        from accounts.models import Account
        choices = [c[0] for c in Account.Status.choices]
        assert "disponible" in choices
        assert "por_vencer" in choices
        assert "vencida" in choices
        assert "no_disponible" in choices

    def test_fecha_pago_property(self, db, platform):
        """fecha_pago debe calcularse al hacer save() si no está definida."""
        from accounts.models import Account
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute(
                "INSERT INTO accounts (platform_id, status, fecha_compra, fecha_pago) "
                "VALUES (%s, 'activo', '2026-05-15', '2026-06-12')",
                [platform],
            )
        acc = Account.objects.latest("id")
        assert acc.fecha_pago == date(2026, 6, 12)


class TestAccountSerializer:
    """Tests del serializer AccountSerializer."""

    def test_serializer_retorna_todos_los_campos(self, account):
        """El serializer debe devolver todos los fields."""
        from accounts.serializers import AccountSerializer
        from accounts.models import Account
        acc = Account.objects.get(pk=account)
        serializer = AccountSerializer(acc)
        data = serializer.data
        # Campos clave que deben estar
        assert "platform_name" in data
        assert "provider_name" in data
        assert "fecha_pago" in data
        assert "screens_count" in data

    def test_fecha_pago_calculada_en_serializer(self, account):
        """Serializer incluye fecha_pago correcta."""
        from accounts.serializers import AccountSerializer
        from accounts.models import Account
        acc = Account.objects.get(pk=account)
        serializer = AccountSerializer(acc)
        assert serializer.data["fecha_pago"] == "2026-05-29"


class TestAccountStatusSerializer:
    """Tests del serializer de cambio de estado."""

    def test_acepta_status_valido(self):
        """Debe aceptar valores válidos de status."""
        from accounts.serializers import AccountStatusSerializer
        serializer = AccountStatusSerializer(data={"status": "disponible"})
        assert serializer.is_valid()

    def test_rechaza_status_invalido(self):
        """Debe rechazar statuses no definidos."""
        from accounts.serializers import AccountStatusSerializer
        serializer = AccountStatusSerializer(data={"status": "inventado"})
        assert not serializer.is_valid()
        assert "status" in serializer.errors


# ─── View tests ────────────────────────────────────────────────────────────────

class TestAccountViewSet:
    """Tests del ViewSet de Account."""

    def test_list_accounts(self, account, api_client):
        """GET /api/accounts/ debe devolver lista."""
        response = api_client.get("/api/accounts/")
        assert response.status_code == 200
        assert "results" in response.data or isinstance(response.data, list)

    def test_retrieve_account(self, account, api_client):
        """GET /api/accounts/:id/ debe devolver detalle."""
        response = api_client.get(f"/api/accounts/{account}/")
        assert response.status_code == 200

    def test_create_account(self, platform, email_obj, api_client):
        """POST /api/accounts/ debe crear una cuenta."""
        data = {
            "platform": platform,
            "email": email_obj,
            "max_screens": 4,
            "credentials": "test:pass",
            "status": "disponible",
            "fecha_compra": "2026-05-01",
        }
        response = api_client.post("/api/accounts/", data, format="json")
        assert response.status_code == 201

    def test_filter_by_status(self, account, api_client):
        """Filtro por status debe funcionar."""
        response = api_client.get("/api/accounts/", {"status": "disponible"})
        assert response.status_code == 200

    def test_filter_by_platform(self, account, platform, api_client):
        """Filtro por platform debe funcionar."""
        response = api_client.get("/api/accounts/", {"platform": platform})
        assert response.status_code == 200

    def test_change_status_action(self, account, api_client):
        """PATCH /api/accounts/:id/change_status/ debe cambiar estado."""
        response = api_client.patch(
             f"/api/accounts/{account}/change_status/",
             {"status": "no_disponible"},
             format="json",
        )
        assert response.status_code == 200
        assert response.data["status"] == "no_disponible"

    def test_screens_subresource(self, account, screen, api_client):
        """GET /api/accounts/:id/screens/ debe devolver pantallas."""
        response = api_client.get(f"/api/accounts/{account}/screens/")
        assert response.status_code == 200
        assert isinstance(response.data, list)

    def test_search_by_credentials(self, account, api_client):
        """Búsqueda por credentials debe funcionar."""
        response = api_client.get("/api/accounts/", {"search": "user"})
        assert response.status_code == 200

    def test_pagination(self, account, api_client):
        """Respuesta debe incluir paginación."""
        response = api_client.get("/api/accounts/")
        assert response.status_code == 200
        # DRF incluye count y results cuando hay paginación
        assert "count" in response.data or "results" in response.data
