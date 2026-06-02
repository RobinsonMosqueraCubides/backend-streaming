from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Customer
from .serializers import CustomerSerializer
from screens.serializers import ScreenSerializer
from customer_accounts.serializers import CustomerAccountSerializer


class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer
    search_fields = ["name", "phone"]

    @action(detail=True, methods=["get"])
    def purchases(self, request, pk=None):
        """Devuelve todas las compras del cliente (pantallas + cuentas)."""
        customer = self.get_object()
        screens = customer.screens.all()
        accounts = customer.customer_accounts.all()
        return Response({
            "customer": CustomerSerializer(customer).data,
            "screens": ScreenSerializer(screens, many=True).data,
            "accounts": CustomerAccountSerializer(accounts, many=True).data,
        })
