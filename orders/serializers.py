from rest_framework import serializers
from .models import Order


class OrderSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source="customer.name", read_only=True)
    items_count = serializers.IntegerField(read_only=True)
    screens_detail = serializers.SerializerMethodField()
    customer_accounts_detail = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = "__all__"

    def get_screens_detail(self, obj):
        return [
            {
                "id": s.id,
                "pin": s.pin,
                "precio_venta": str(s.precio_venta) if s.precio_venta else None,
                "status": s.status,
                "platform": s.account.platform.name if s.account and s.account.platform else None,
            }
            for s in obj.screens.all()
        ]

    def get_customer_accounts_detail(self, obj):
        return [
            {
                "id": ca.id,
                "precio_venta": str(ca.precio_venta) if ca.precio_venta else None,
                "status": ca.status,
                "platform": ca.account.platform.name if ca.account and ca.account.platform else None,
            }
            for ca in obj.customer_accounts.all()
        ]
