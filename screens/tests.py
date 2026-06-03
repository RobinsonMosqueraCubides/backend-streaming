"""
tests_screens.py — Tests para la app screens.
Cubre: modelos (fecha_cobro, fecha_corte, validación PIN), serializers, views.
"""
import pytest
from datetime import date, timedelta
from django.core.exceptions import ValidationError

pytestmark = pytest.mark.django_db


class TestScreenModel:
    """Tests del modelo Screen."""

    def test_fecha_cobro_29_dias_despues(self, screen):
        """fecha_cobro debe ser fecha_inicio + 29 días."""
        from screens.models import Screen
        s = Screen.objects.get(pk=screen)
        assert s.fecha_cobro == date(2026, 5, 1) + timedelta(days=29)

    def test_fecha_corte_30_dias_despues(self, screen):
        """fecha_corte debe ser fecha_inicio + 30 días."""
        from screens.models import Screen
        s = Screen.objects.get(pk=screen)
        assert s.fecha_corte == date(2026, 5, 1) + timedelta(days=30)

    def test_fechas_none_sin_fecha_inicio(self, account, db):
        """Sin fecha_inicio, las propiedades retornan None."""
        from screens.models import Screen
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute(
                "INSERT INTO screens (account_id, pin, status) VALUES (%s, '9999', 'disponible')",
                [account],
            )
        s = Screen.objects.latest("id")
        assert s.fecha_cobro is None
        assert s.fecha_corte is None

    def test_str_incluye_account_y_status(self, screen, account):
        """__str__ debe mencionar account y status."""
        from screens.models import Screen
        s = Screen.objects.get(pk=screen)
        string = str(s)
        assert str(account) in string or "Cuenta" in string

    def test_status_choices_completos(self):
        """Los 5 statuses deben estar definidos."""
        from screens.models import Screen
        choices = [c[0] for c in Screen.Status.choices]
        assert "disponible" in choices
        assert "activo" in choices
        assert "por_vencer" in choices
        assert "vencida" in choices
        assert "caida" in choices


class TestScreenValidation:
    """Tests de validación del modelo Screen."""

    def test_pin_4_digitos_valido(self, account, db):
        """PIN con 4 dígitos debe pasar validación."""
        from screens.models import Screen
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute(
                "INSERT INTO screens (account_id, pin, status) VALUES (%s, '1234', 'disponible')",
                [account],
            )
        s = Screen.objects.latest("id")
        s.full_clean()  # No debe lanzar

    def test_pin_invalido_menos_digitos(self, account, db):
        """PIN con menos de 4 dígitos debe fallar."""
        from screens.models import Screen
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute(
                "INSERT INTO screens (account_id, pin, status) VALUES (%s, '123', 'disponible')",
                [account],
            )
        s = Screen.objects.latest("id")
        with pytest.raises(ValidationError):
            s.full_clean()

    def test_pin_invalido_letras(self, account, db):
        """PIN con letras debe fallar."""
        from screens.models import Screen
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute(
                "INSERT INTO screens (account_id, pin, status) VALUES (%s, '12ab', 'disponible')",
                [account],
            )
        s = Screen.objects.latest("id")
        with pytest.raises(ValidationError):
            s.full_clean()


class TestScreenSerializer:
    """Tests del serializer ScreenSerializer."""

    def test_fecha_cobro_en_response(self, screen):
        """Serializer debe incluir fecha_cobro."""
        from screens.serializers import ScreenSerializer
        from screens.models import Screen
        s = Screen.objects.get(pk=screen)
        data = ScreenSerializer(s).data
        assert "fecha_cobro" in data
        assert data["fecha_cobro"] is not None

    def test_fecha_corte_en_response(self, screen):
        """Serializer debe incluir fecha_corte."""
        from screens.serializers import ScreenSerializer
        from screens.models import Screen
        s = Screen.objects.get(pk=screen)
        data = ScreenSerializer(s).data
        assert "fecha_corte" in data

    def test_account_info_no_nulo(self, screen, account):
        """account_info debe devolver string con info de la cuenta."""
        from screens.serializers import ScreenSerializer
        from screens.models import Screen
        s = Screen.objects.get(pk=screen)
        data = ScreenSerializer(s).data
        assert "account_info" in data
        assert data["account_info"] is not None


class TestScreenViewSet:
    """Tests del ViewSet de Screen."""

    def test_list_screens(self, screen, api_client):
        """GET /api/screens/ debe devolver lista."""
        response = api_client.get("/api/screens/")
        assert response.status_code == 200

    def test_retrieve_screen(self, screen, api_client):
        """GET /api/screens/:id/ debe devolver detalle."""
        response = api_client.get(f"/api/screens/{screen}/")
        assert response.status_code == 200

    def test_create_screen(self, account, customer, api_client):
        """POST /api/screens/ debe crear pantalla."""
        data = {
            "account": account,
            "customer": customer,
            "pin": "5555",
            "profile_name": "Test Perfil",
            "status": "disponible",
        }
        response = api_client.post("/api/screens/", data, format="json")
        assert response.status_code == 201

    def test_filter_by_status_disponible(self, screen, api_client):
        """Filtro por status disponible debe funcionar."""
        response = api_client.get("/api/screens/", {"status": "disponible"})
        assert response.status_code == 200

    def test_filter_by_account(self, account, screen, api_client):
        """Filtro por account debe funcionar."""
        response = api_client.get("/api/screens/", {"account": account})
        assert response.status_code == 200

    def test_filter_by_customer(self, customer, screen, api_client):
        """Filtro por customer debe funcionar."""
        response = api_client.get("/api/screens/", {"customer": customer})
        assert response.status_code == 200

    def test_change_status(self, screen, api_client):
        """PATCH /api/screens/:id/change_status/ debe cambiar estado."""
        response = api_client.patch(
            f"/api/screens/{screen}/change_status/",
            {"status": "caida"},
            format="json",
        )
        assert response.status_code == 200
        assert response.data["status"] == "caida"

    def test_search_by_pin(self, screen, api_client):
        """Búsqueda por PIN debe funcionar."""
        response = api_client.get("/api/screens/", {"search": "1234"})
        assert response.status_code == 200