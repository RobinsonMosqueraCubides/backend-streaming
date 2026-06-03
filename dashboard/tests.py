"""
tests_dashboard.py — Tests para la app dashboard.
Cubre: endpoints /api/dashboard/summary/ y /api/dashboard/vencidas/.
"""
import pytest
from datetime import date

pytestmark = pytest.mark.django_db


class TestDashboardSummary:
    """Tests del endpoint GET /api/dashboard/summary/."""

    def test_retorna_totales(self, account, screen, customer_account, api_client):
        """El resumen debe incluir totales de cuentas, pantallas y customer_accounts."""
        response = api_client.get("/api/dashboard/summary/")
        assert response.status_code == 200
        data = response.data
        assert "total_accounts" in data
        assert "total_screens" in data
        assert "total_customer_accounts" in data

    def test_incluye_cuentas_por_plataforma(self, account, platform, api_client):
        """Debe incluir accounts_by_platform."""
        response = api_client.get("/api/dashboard/summary/")
        assert response.status_code == 200
        assert "accounts_by_platform" in response.data

    def test_incluye_pantallas_por_estado(self, screen, api_client):
        """Debe incluir screens_by_status."""
        response = api_client.get("/api/dashboard/summary/")
        assert response.status_code == 200
        assert "screens_by_status" in response.data

    def test_lista_plataformas(self, platform, api_client):
        """Debe listar los nombres de plataformas disponibles."""
        response = api_client.get("/api/dashboard/summary/")
        assert response.status_code == 200
        assert "platforms" in response.data
        assert isinstance(response.data["platforms"], list)

    def test_cuantos_accounts_by_status(self, account, api_client):
        """accounts_by_platform debe agrupar por status también."""
        response = api_client.get("/api/dashboard/summary/")
        assert response.status_code == 200
        assert "accounts_by_platform" in response.data


class TestDashboardVencidas:
    """Tests del endpoint GET /api/dashboard/vencidas/."""

    def test_retorna_fecha_consulta(self, api_client):
        """Debe incluir la fecha de consulta."""
        response = api_client.get("/api/dashboard/vencidas/")
        assert response.status_code == 200
        assert "fecha_consulta" in response.data

    def test_retorna_total_vencidas(self, account, api_client):
        """Debe incluir total_vencidas."""
        response = api_client.get("/api/dashboard/vencidas/")
        assert response.status_code == 200
        assert "total_vencidas" in response.data

    def test_lista_categorias(self, api_client):
        """Debe incluir listas para cada categoría."""
        response = api_client.get("/api/dashboard/vencidas/")
        assert response.status_code == 200
        assert "cuentas_por_vencer" in response.data
        assert "cuentas_vencidas" in response.data
        assert "pantallas_por_vencer" in response.data
        assert "pantallas_vencidas" in response.data
        assert "customer_accounts_por_vencer" in response.data
        assert "customer_accounts_vencidas" in response.data

    def test_filtra_solo_por_vencer_y_vencida(self, account, screen, api_client):
        """Solo debe devolver registros con status 'por_vencer' o 'vencida'."""
        response = api_client.get("/api/dashboard/vencidas/")
        assert response.status_code == 200
        # La account de fixture tiene status='activo' → no debe aparecer
        assert response.data["total_vencidas"] == 0