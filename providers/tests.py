"""
tests_providers.py — Tests para la app providers.
Cubre: modelos Platform y Provider, serializers, views.
"""
import pytest

pytestmark = pytest.mark.django_db


class TestPlatformModel:
    """Tests del modelo Platform."""

    def test_str_es_el_nombre(self, platform):
        """__str__ debe retornar el nombre de la plataforma."""
        from providers.models import Platform
        p = Platform.objects.get(pk=platform)
        assert str(p) == "Netflix"

    def test_nombre_unico(self, platform, db):
        """No se pueden crear dos plataformas con el mismo nombre."""
        from providers.models import Platform
        from django.db import connection
        with connection.cursor() as cur:
            with pytest.raises(Exception):  # IntegrityError
                cur.execute("INSERT INTO platforms (name) VALUES ('Netflix')")

    def test_ordenamiento_alfabetico(self, db):
        """Las plataformas deben estar ordenadas por nombre."""
        from providers.models import Platform
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute("INSERT INTO platforms (name) VALUES ('Disney+')")
            cur.execute("INSERT INTO platforms (name) VALUES ('HBO Max')")
            cur.execute("INSERT INTO platforms (name) VALUES ('Prime Video')")
        qs = Platform.objects.all()
        names = [p.name for p in qs]
        assert names == sorted(names)


class TestProviderModel:
    """Tests del modelo Provider."""

    def test_str_es_el_nombre(self, provider):
        """__str__ debe retornar el nombre del proveedor."""
        from providers.models import Provider
        p = Provider.objects.get(pk=provider)
        assert str(p) == "Proveedor Test"

    def test_campos_opcionales(self, db):
        """Contact, phone y notes deben ser opcionales."""
        from providers.models import Provider
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute("INSERT INTO providers (name) VALUES ('Minimal Provider')")
        p = Provider.objects.get(name="Minimal Provider")
        assert p.contact is None
        assert p.phone is None
        assert p.notes is None

    def test_ordenamiento_por_nombre(self, db):
        """Los proveedores deben estar ordenados por nombre."""
        from providers.models import Provider
        from django.db import connection
        with connection.cursor() as cur:
            cur.execute("INSERT INTO providers (name) VALUES ('Zulu Corp')")
            cur.execute("INSERT INTO providers (name) VALUES ('Alpha SAS')")
        qs = list(Provider.objects.all())
        names = [p.name for p in qs]
        assert "Alpha SAS" in names
        assert "Zulu Corp" in names


class TestPlatformSerializer:
    """Tests del serializer PlatformSerializer."""

    def test_serializer_campos_basicos(self, platform):
        """Serializer debe incluir id y name."""
        from providers.serializers import PlatformSerializer
        from providers.models import Platform
        p = Platform.objects.get(pk=platform)
        data = PlatformSerializer(p).data
        assert data["id"] == platform
        assert data["name"] == "Netflix"


class TestProviderSerializer:
    """Tests del serializer ProviderSerializer."""

    def test_serializer_campos_completos(self, provider):
        """Serializer debe incluir todos los campos del modelo."""
        from providers.serializers import ProviderSerializer
        from providers.models import Provider
        p = Provider.objects.get(pk=provider)
        data = ProviderSerializer(p).data
        assert data["name"] == "Proveedor Test"
        assert data["contact"] == "test@email.com"
        assert data["phone"] == "3001234567"


class TestProviderViewSet:
    """Tests del ViewSet de Provider."""

    def test_list_providers(self, provider, api_client):
        """GET /api/providers/ debe devolver lista."""
        response = api_client.get("/api/providers/")
        assert response.status_code == 200

    def test_retrieve_provider(self, provider, api_client):
        """GET /api/providers/:id/ debe devolver detalle."""
        response = api_client.get(f"/api/providers/{provider}/")
        assert response.status_code == 200

    def test_create_provider(self, api_client):
        """POST /api/providers/ debe crear proveedor."""
        data = {"name": "Nuevo Proveedor", "phone": "3009876543", "notes": "Test"}
        response = api_client.post("/api/providers/", data, format="json")
        assert response.status_code == 201

    def test_search_by_name(self, provider, api_client):
        """Búsqueda por nombre debe funcionar."""
        response = api_client.get("/api/providers/", {"search": "Proveedor"})
        assert response.status_code == 200


class TestPlatformViewSet:
    """Tests del ViewSet de Platform."""

    def test_list_platforms(self, platform, api_client):
        """GET /api/platforms/ debe devolver lista."""
        response = api_client.get("/api/platforms/")
        assert response.status_code == 200

    def test_create_platform(self, api_client):
        """POST /api/platforms/ debe crear plataforma."""
        data = {"name": "Paramount+"}
        response = api_client.post("/api/platforms/", data, format="json")
        assert response.status_code == 201
        assert response.data["name"] == "Paramount+"