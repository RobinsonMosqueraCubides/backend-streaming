"""
tests_emails.py — Tests para la app emails.
Cubre: modelo Email, serializer, views.
"""
import pytest

pytestmark = pytest.mark.django_db


class TestEmailModel:
    """Tests del modelo Email."""

    def test_str_es_el_email(self, email_obj):
        """__str__ debe retornar la dirección de correo."""
        from emails.models import Email
        e = Email.objects.get(pk=email_obj)
        assert str(e) == "test@gmail.com"

    def test_email_unico(self, email_obj, db):
        """No se puede duplicar la dirección de email."""
        from emails.models import Email
        from django.db import connection
        with connection.cursor() as cur:
            with pytest.raises(Exception):  # IntegrityError
                cur.execute("INSERT INTO emails (email, is_active) VALUES ('test@gmail.com', 1)")

    def test_activo_por_defecto(self, provider, db):
        """is_active debe ser True por defecto."""
        from emails.models import Email
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute("INSERT INTO emails (email, provider_id) VALUES ('nuevo@email.com', %s)", [provider])
        e = Email.objects.get(email="nuevo@email.com")
        assert e.is_active is True

    def test_proveedor_opcional(self, db):
        """Email puede no tener proveedor asociado."""
        from emails.models import Email
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute("INSERT INTO emails (email) VALUES ('sinprov@email.com')")
        e = Email.objects.get(email="sinprov@email.com")
        assert e.provider_id is None

    def test_ordenamiento_por_email(self, db, provider):
        """Los emails deben estar ordenados alfabéticamente."""
        from emails.models import Email
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute("INSERT INTO emails (email, provider_id) VALUES ('zulu@email.com', %s)", [provider])
            cur.execute("INSERT INTO emails (email, provider_id) VALUES ('alfa@email.com', %s)", [provider])
        qs = list(Email.objects.all())
        # Por defecto ordering = ["email"]
        assert qs[0].email == "alfa@email.com"


class TestEmailSerializer:
    """Tests del serializer EmailSerializer."""

    def test_incluye_provider_name(self, email_obj, provider):
        """Serializer debe incluir el nombre del proveedor."""
        from emails.serializers import EmailSerializer
        from emails.models import Email
        e = Email.objects.get(pk=email_obj)
        data = EmailSerializer(e).data
        assert "provider_name" in data

    def test_todos_los_campos_presentes(self, email_obj):
        """Serializer debe incluir todos los campos del modelo."""
        from emails.serializers import EmailSerializer
        from emails.models import Email
        e = Email.objects.get(pk=email_obj)
        data = EmailSerializer(e).data
        assert data["email"] == "test@gmail.com"
        assert data["is_active"] is True


class TestEmailViewSet:
    """Tests del ViewSet de Email."""

    def test_list_emails(self, email_obj, api_client):
        """GET /api/emails/ debe devolver lista."""
        response = api_client.get("/api/emails/")
        assert response.status_code == 200

    def test_retrieve_email(self, email_obj, api_client):
        """GET /api/emails/:id/ debe devolver detalle."""
        response = api_client.get(f"/api/emails/{email_obj}/")
        assert response.status_code == 200

    def test_create_email(self, provider, api_client):
        """POST /api/emails/ debe crear email."""
        data = {
            "email": "nuevo@gmail.com",
            "password": "secret456",
            "provider": provider,
            "is_active": True,
        }
        response = api_client.post("/api/emails/", data, format="json")
        assert response.status_code == 201

    def test_filter_by_is_active(self, email_obj, api_client):
        """Filtro por is_active debe funcionar."""
        response = api_client.get("/api/emails/", {"is_active": "true"})
        assert response.status_code == 200

    def test_filter_by_provider(self, email_obj, provider, api_client):
        """Filtro por provider debe funcionar."""
        response = api_client.get("/api/emails/", {"provider": provider})
        assert response.status_code == 200

    def test_search_by_email(self, email_obj, api_client):
        """Búsqueda por dirección de email debe funcionar."""
        response = api_client.get("/api/emails/", {"search": "test"})
        assert response.status_code == 200