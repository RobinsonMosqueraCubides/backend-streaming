from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.core.exceptions import ValidationError, ObjectDoesNotExist
from .models import Platform, Provider, ProviderWarrantyClaim
from .serializers import (
    PlatformSerializer,
    ProviderSerializer,
    ProviderWarrantyClaimSerializer,
    ApplyProviderWarrantySerializer,
)
from .services import apply_provider_warranty


class PlatformViewSet(viewsets.ModelViewSet):
    queryset = Platform.objects.all()
    serializer_class = PlatformSerializer
    search_fields = ["name"]


class ProviderViewSet(viewsets.ModelViewSet):
    queryset = Provider.objects.all()
    serializer_class = ProviderSerializer
    search_fields = ["name", "contact", "phone"]


class ProviderWarrantyClaimViewSet(viewsets.ModelViewSet):
    queryset = ProviderWarrantyClaim.objects.select_related(
        "account__platform",
        "account__email",
        "provider",
        "replacement_account__email",
    ).all()
    serializer_class = ProviderWarrantyClaimSerializer
    search_fields = ["notes", "new_credentials"]
    filterset_fields = ["claim_type", "provider", "account"]

    def create(self, request, *args, **kwargs):
        serializer = ApplyProviderWarrantySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            claim = apply_provider_warranty(**serializer.validated_data)
        except (ValidationError, ObjectDoesNotExist) as exc:
            message = exc.message if hasattr(exc, "message") else str(exc)
            return Response({"error": message}, status=status.HTTP_400_BAD_REQUEST)

        return Response(
            ProviderWarrantyClaimSerializer(claim).data,
            status=status.HTTP_201_CREATED,
        )

