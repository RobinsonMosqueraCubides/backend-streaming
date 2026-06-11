from rest_framework import viewsets, filters
from .models import Email
from .serializers import EmailSerializer


class EmailViewSet(viewsets.ModelViewSet):
    queryset = Email.objects.all()
    serializer_class = EmailSerializer
    search_fields = ["email", "owner_name"]
    filterset_fields = ["is_active", "provider", "requires_validation"]
