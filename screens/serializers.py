from rest_framework import serializers
from .models import Screen


class ScreenSerializer(serializers.ModelSerializer):
    account_info = serializers.CharField(source="account.__str__", read_only=True)
    customer_name = serializers.CharField(source="customer.name", read_only=True, allow_null=True)
    fecha_cobro = serializers.SerializerMethodField()
    fecha_corte = serializers.SerializerMethodField()

    class Meta:
        model = Screen
        fields = "__all__"

    def get_fecha_cobro(self, obj):
        return obj.fecha_cobro

    def get_fecha_corte(self, obj):
        return obj.fecha_corte


class ScreenStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Screen.Status.choices)
