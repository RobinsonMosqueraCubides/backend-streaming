from rest_framework import viewsets
from .models import Platform, Provider
from .serializers import PlatformSerializer, ProviderSerializer


class PlatformViewSet(viewsets.ModelViewSet):
    queryset = Platform.objects.all()
    serializer_class = PlatformSerializer
    search_fields = ["name"]


class ProviderViewSet(viewsets.ModelViewSet):
    queryset = Provider.objects.all()
    serializer_class = ProviderSerializer
    search_fields = ["name", "contact", "phone"]
