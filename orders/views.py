from django.core.exceptions import ObjectDoesNotExist, ValidationError
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import FilterSet
from .models import Order, WarrantyClaim
from .serializers import (
    ApplyWarrantySerializer,
    OrderSerializer,
    SellOrderSerializer,
    WarrantySerializer,
)
from .services import apply_warranty, sell_order


class OrderFilter(FilterSet):
    class Meta:
        model = Order
        fields = {
            "status": ["exact"],
            "customer": ["exact"],
            "fecha_inicio": ["exact", "gte", "lte"],
        }


class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.select_related("customer").prefetch_related(
        "screens__account__platform",
        "customer_accounts__account__platform",
    ).all()
    serializer_class = OrderSerializer
    filterset_class = OrderFilter
    search_fields = ["observaciones"]

    @action(detail=False, methods=["post"])
    def sell(self, request):
        serializer = SellOrderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            order, _ = sell_order(**serializer.validated_data)
        except (ObjectDoesNotExist, ValidationError) as exc:
            message = exc.message if hasattr(exc, "message") else str(exc)
            return Response({"error": message}, status=status.HTTP_400_BAD_REQUEST)
        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=["post"], url_path="warranty")
    def warranty(self, request):
        serializer = ApplyWarrantySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            claim = apply_warranty(**serializer.validated_data)
        except (ObjectDoesNotExist, ValidationError) as exc:
            message = exc.message if hasattr(exc, "message") else str(exc)
            return Response({"error": message}, status=status.HTTP_400_BAD_REQUEST)
        return Response(WarrantySerializer(claim).data, status=status.HTTP_201_CREATED)
