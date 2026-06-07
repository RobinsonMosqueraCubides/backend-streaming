from rest_framework import serializers
from .models import CobroEstado


class CobroEstadoSerializer(serializers.ModelSerializer):
    class Meta:
        model = CobroEstado
        fields = "__all__"


class CobroMarcarSerializer(serializers.Serializer):
    order_id = serializers.IntegerField()
    accion = serializers.ChoiceField(choices=["aviso", "notificacion", "corte"])
