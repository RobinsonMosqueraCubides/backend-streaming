from rest_framework import serializers
from .models import CustomerAccount


class CustomerAccountSerializer(serializers.ModelSerializer):
    account_info = serializers.CharField(source="account.__str__", read_only=True)
    customer_name = serializers.CharField(source="customer.name", read_only=True)
    fecha_cobro = serializers.SerializerMethodField()
    fecha_corte = serializers.SerializerMethodField()

    class Meta:
        model = CustomerAccount
        fields = "__all__"

    def get_fecha_cobro(self, obj):
        return obj.fecha_cobro

    def get_fecha_corte(self, obj):
        return obj.fecha_corte


class CustomerAccountStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=CustomerAccount.Status.choices)
