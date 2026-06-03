"""
tests_customers.py — Tests para la app customers.
Cubre: modelo, serializers, views, purchases subresource.
"""
import pytest

pytestmark = pytest.mark.django_db


class TestCustomerModel:
    """Tests del modelo Customer."""

    def test_str_incluye_nombre_y_telefono(self, customer):
        """__str__ debe incluir name y phone."""
        from customers.models import Customer
        c = Customer.objects.get(pk=customer)
        string = str(c)
        assert "Cliente Test" in string
        assert "3112223344" in string

    def test_ordenamiento_por_nombre(self, db):
        """Los clientes deben estar ordenados alfabéticamente por nombre."""
        from customers.models import Customer
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute("INSERT INTO customers (name, phone) VALUES ('Zara', '3000000001')")
            cur.execute("INSERT INTO customers (name, phone) VALUES ('Ana', '3000000002')")
        qs = Customer.objects.all()
        assert qs[0].name == "Ana"
        assert qs[1].name == "Zara"


class TestCustomerSerializer:
    """Tests del serializer CustomerSerializer."""

    def test_retorna_todos_los_campos(self, customer):
        """Serializer debe incluir todos los fields del modelo."""
        from customers.serializers import CustomerSerializer
        from customers.models import Customer
        c = Customer.objects.get(pk=customer)
        data = CustomerSerializer(c).data
        assert "name" in data
        assert "phone" in data
        assert "notes" in data


class TestCustomerViewSet:
    """Tests del ViewSet de Customer."""

    def test_list_customers(self, customer, api_client):
        """GET /api/customers/ debe devolver lista."""
        response = api_client.get("/api/customers/")
        assert response.status_code == 200

    def test_retrieve_customer(self, customer, api_client):
        """GET /api/customers/:id/ debe devolver detalle."""
        response = api_client.get(f"/api/customers/{customer}/")
        assert response.status_code == 200

    def test_create_customer(self, api_client):
        """POST /api/customers/ debe crear cliente."""
        data = {"name": "Nuevo Cliente", "phone": "3109998888", "notes": "Test"}
        response = api_client.post("/api/customers/", data, format="json")
        assert response.status_code == 201

    def test_update_customer(self, customer, api_client):
        """PUT /api/customers/:id/ debe actualizar cliente."""
        data = {"name": "Cliente Actualizado", "phone": "3101112222"}
        response = api_client.put(f"/api/customers/{customer}/", data, format="json")
        assert response.status_code == 200
        assert response.data["name"] == "Cliente Actualizado"

    def test_delete_customer(self, customer, api_client):
        """DELETE /api/customers/:id/ debe eliminar cliente."""
        response = api_client.delete(f"/api/customers/{customer}/")
        assert response.status_code == 204

    def test_search_by_name(self, customer, api_client):
        """Búsqueda por nombre debe funcionar."""
        response = api_client.get("/api/customers/", {"search": "Cliente"})
        assert response.status_code == 200

    def test_purchases_subresource(self, customer, screen, api_client):
        """GET /api/customers/:id/purchases/ debe devolver pantallas y cuentas."""
        response = api_client.get(f"/api/customers/{customer}/purchases/")
        assert response.status_code == 200
        assert "customer" in response.data
        assert "screens" in response.data
        assert "accounts" in response.data