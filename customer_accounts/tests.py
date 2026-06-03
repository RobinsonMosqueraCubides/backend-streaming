"""
tests_customer_accounts.py — Tests para la app customer_accounts.
Cubre: modelo CustomerAccount (fecha_cobro, fecha_corte), serializers, views.
"""
import pytest
from datetime import date, timedelta

pytestmark = pytest.mark.django_db


class TestCustomerAccountModel:
    """Tests del modelo CustomerAccount."""

    def test_fecha_cobro_29_dias(self, customer_account):
        """fecha_cobro debe ser fecha_inicio + 29 días."""
        from customer_accounts.models import CustomerAccount
        ca = CustomerAccount.objects.get(pk=customer_account)
        assert ca.fecha_cobro == date(2026, 5, 1) + timedelta(days=29)

    def test_fecha_corte_30_dias(self, customer_account):
        """fecha_corte debe ser fecha_inicio + 30 días."""
        from customer_accounts.models import CustomerAccount
        ca = CustomerAccount.objects.get(pk=customer_account)
        assert ca.fecha_corte == date(2026, 5, 1) + timedelta(days=30)

    def test_fechas_none_sin_fecha_inicio(self, account, customer, db):
        """Sin fecha_inicio, fecha_cobro y fecha_corte son None."""
        from customer_accounts.models import CustomerAccount
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute(
                "INSERT INTO customer_accounts (account_id, customer_id, contraseña) "
                "VALUES (%s, %s, 'nopass')",
                [account, customer],
            )
        ca = CustomerAccount.objects.latest("id")
        assert ca.fecha_cobro is None
        assert ca.fecha_corte is None

    def test_str_incluye_cuenta_y_cliente(self, customer_account, account, customer):
        """__str__ debe incluir account y cliente."""
        from customer_accounts.models import CustomerAccount
        ca = CustomerAccount.objects.get(pk=customer_account)
        s = str(ca)
        assert "Cuenta" in s or str(account) in s

    def test_status_choices(self):
        """Los 4 statuses deben estar definidos."""
        from customer_accounts.models import CustomerAccount
        choices = [c[0] for c in CustomerAccount.Status.choices]
        assert "activo" in choices
        assert "por_vencer" in choices
        assert "vencida" in choices
        assert "caida" in choices

    def test_activo_por_defecto(self, account, customer, db):
        """Status por defecto debe ser 'activo'."""
        from customer_accounts.models import CustomerAccount
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute(
                "INSERT INTO customer_accounts (account_id, customer_id, contraseña) "
                "VALUES (%s, %s, 'newpass')",
                [account, customer],
            )
        ca = CustomerAccount.objects.latest("id")
        assert ca.status == "activo"


class TestCustomerAccountSerializer:
    """Tests del serializer CustomerAccountSerializer."""

    def test_fecha_cobro_en_response(self, customer_account):
        """Serializer debe incluir fecha_cobro."""
        from customer_accounts.serializers import CustomerAccountSerializer
        from customer_accounts.models import CustomerAccount
        ca = CustomerAccount.objects.get(pk=customer_account)
        data = CustomerAccountSerializer(ca).data
        assert "fecha_cobro" in data
        assert data["fecha_cobro"] is not None

    def test_fecha_corte_en_response(self, customer_account):
        """Serializer debe incluir fecha_corte."""
        from customer_accounts.serializers import CustomerAccountSerializer
        from customer_accounts.models import CustomerAccount
        ca = CustomerAccount.objects.get(pk=customer_account)
        data = CustomerAccountSerializer(ca).data
        assert "fecha_corte" in data

    def test_customer_name_presente(self, customer_account, customer):
        """Serializer debe incluir nombre del cliente."""
        from customer_accounts.serializers import CustomerAccountSerializer
        from customer_accounts.models import CustomerAccount
        ca = CustomerAccount.objects.get(pk=customer_account)
        data = CustomerAccountSerializer(ca).data
        assert "customer_name" in data
        assert data["customer_name"] == "Cliente Test"


class TestCustomerAccountViewSet:
    """Tests del ViewSet de CustomerAccount — ruta: /api/customer-accounts/."""

    def test_list_customer_accounts(self, customer_account, api_client):
        """GET /api/customer-accounts/ debe devolver lista."""
        response = api_client.get("/api/customer-accounts/")
        assert response.status_code == 200

    def test_retrieve_customer_account(self, customer_account, api_client):
        """GET /api/customer-accounts/:id/ debe devolver detalle."""
        response = api_client.get(f"/api/customer-accounts/{customer_account}/")
        assert response.status_code == 200

    def test_create_customer_account(self, account, customer, api_client):
        """POST /api/customer-accounts/ debe crear cuenta."""
        data = {
            "account": account,
            "customer": customer,
            "contraseña": "newsecret",
            "profile_name": "Nuevo Perfil",
            "status": "activo",
            "fecha_inicio": "2026-05-01",
        }
        response = api_client.post("/api/customer-accounts/", data, format="json")
        assert response.status_code == 201

    def test_filter_by_status(self, customer_account, api_client):
        """Filtro por status debe funcionar."""
        response = api_client.get("/api/customer-accounts/", {"status": "activo"})
        assert response.status_code == 200

    def test_filter_by_account(self, account, customer_account, api_client):
        """Filtro por account debe funcionar."""
        response = api_client.get("/api/customer-accounts/", {"account": account})
        assert response.status_code == 200

    def test_filter_by_customer(self, customer, customer_account, api_client):
        """Filtro por customer debe funcionar."""
        response = api_client.get("/api/customer-accounts/", {"customer": customer})
        assert response.status_code == 200

    def test_change_status(self, customer_account, api_client):
        """PATCH /api/customer-accounts/:id/change_status/ debe cambiar estado."""
        response = api_client.patch(
            f"/api/customer-accounts/{customer_account}/change_status/",
            {"status": "vencida"},
            format="json",
        )
        assert response.status_code == 200
        assert response.data["status"] == "vencida"

    def test_search_by_profile_name(self, customer_account, api_client):
        """Búsqueda por profile_name debe funcionar."""
        response = api_client.get("/api/customer-accounts/", {"search": "Principal"})
        assert response.status_code == 200