"""
Tests para la app dashboard.
Cubre endpoints reales definidos en dashboard/urls.py.
"""
import pytest

pytestmark = pytest.mark.django_db


class TestDashboardResumen:
    def test_retorna_totales_financieros(self, account, screen, customer_account, api_client):
        response = api_client.get("/api/dashboard/resumen/")
        assert response.status_code == 200
        assert "ingresos" in response.data
        assert "egresos" in response.data
        assert "balance" in response.data
        assert "conteos" in response.data

    def test_incluye_conteos_operativos(self, account, screen, api_client):
        response = api_client.get("/api/dashboard/resumen/")
        assert response.status_code == 200
        conteos = response.data["conteos"]
        assert "cuentas_activas" in conteos
        assert "pantallas_vendidas" in conteos
        assert "pantallas_disponibles" in conteos
        assert "ordenes_activas" in conteos


class TestDashboardInventario:
    def test_retorna_resumen_por_plataforma(self, account, api_client):
        response = api_client.get("/api/dashboard/inventario/")
        assert response.status_code == 200
        assert "cuentas" in response.data
        assert "totales" in response.data
        assert isinstance(response.data["cuentas"], list)

    def test_incluye_capacidad_y_disponibilidad(self, account, api_client):
        response = api_client.get("/api/dashboard/inventario/")
        assert response.status_code == 200
        item = response.data["cuentas"][0]
        assert "capacidad_pantallas" in item
        assert "pantallas_vendidas" in item
        assert "pantallas_disponibles" in item


class TestDashboardIngresos:
    def test_ingresos_por_plataforma_responde(self, screen, customer_account, api_client):
        response = api_client.get("/api/dashboard/ingresos/plataforma/")
        assert response.status_code == 200
        assert isinstance(response.data, list)

    def test_ingresos_por_cliente_responde(self, screen, customer_account, api_client):
        response = api_client.get("/api/dashboard/ingresos/cliente/")
        assert response.status_code == 200
        assert isinstance(response.data, list)
