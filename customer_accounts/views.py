from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import FilterSet
from .models import CustomerAccount
from .serializers import CustomerAccountSerializer, CustomerAccountStatusSerializer


class CustomerAccountFilter(FilterSet):
    class Meta:
        model = CustomerAccount
        fields = {
            "status": ["exact"],
            "account": ["exact"],
            "customer": ["exact"],
            "fecha_inicio": ["exact", "gte", "lte"],
        }


class CustomerAccountViewSet(viewsets.ModelViewSet):
    queryset = CustomerAccount.objects.select_related("account", "customer").all()
    serializer_class = CustomerAccountSerializer
    filterset_class = CustomerAccountFilter
    search_fields = ["contraseña", "profile_name", "observaciones"]

    @action(detail=True, methods=["patch"])
    def change_status(self, request, pk=None):
        obj = self.get_object()
        serializer = CustomerAccountStatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        obj.status = serializer.validated_data["status"]
        obj.save(update_fields=["status", "updated_at"])
        return Response(CustomerAccountSerializer(obj).data)
