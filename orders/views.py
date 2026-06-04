from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import FilterSet
from .models import Order
from .serializers import OrderSerializer


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
