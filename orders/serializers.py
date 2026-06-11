from rest_framework import serializers

from .models import Order, WarrantyClaim


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


class SaleItemSerializer(serializers.Serializer):
    type = serializers.ChoiceField(choices=["screen", "customer_account"])
    account_id = serializers.IntegerField(min_value=1)
    pin = serializers.RegexField(r"^\d{4}$", required=False)
    contrasena = serializers.CharField(required=False, allow_blank=False)
    precio_venta = serializers.DecimalField(max_digits=10, decimal_places=2)
    profile_name = serializers.CharField(required=False, allow_blank=True)
    observaciones = serializers.CharField(required=False, allow_blank=True)
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        if "contraseña" in self.initial_data and "contrasena" not in attrs:
            attrs["contrasena"] = self.initial_data["contraseña"]
        if attrs["type"] == "screen" and not attrs.get("pin"):
            raise serializers.ValidationError({"pin": "El PIN es requerido para vender una pantalla."})
        if attrs["type"] == "customer_account" and not attrs.get("contrasena"):
            raise serializers.ValidationError({"contrasena": "La contrasena es requerida para vender una cuenta completa."})
        return attrs


class SellOrderSerializer(serializers.Serializer):
    customer_id = serializers.IntegerField(min_value=1)
    fecha_inicio = serializers.DateField()
    observaciones = serializers.CharField(required=False, allow_blank=True)
    items = SaleItemSerializer(many=True)


class WarrantySerializer(serializers.ModelSerializer):
    class Meta:
        model = WarrantyClaim
        fields = "__all__"


class ApplyWarrantySerializer(serializers.Serializer):
    order_id = serializers.IntegerField(min_value=1)
    original_type = serializers.ChoiceField(choices=["screen", "customer_account"])
    original_id = serializers.IntegerField(min_value=1)
    reason = serializers.CharField(required=False, allow_blank=True)
    replacement_item = SaleItemSerializer(required=False)
