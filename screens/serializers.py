from rest_framework import serializers
from .models import Screen


class ScreenSerializer(serializers.ModelSerializer):
    account_info = serializers.CharField(source="account.__str__", read_only=True)
    customer_name = serializers.CharField(source="customer.name", read_only=True, allow_null=True)

    class Meta:
        model = Screen
        fields = "__all__"


class ScreenStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Screen.Status.choices)


class BulkScreenStatusSerializer(serializers.Serializer):
    ids = serializers.ListField(child=serializers.IntegerField(min_value=1))
    status = serializers.ChoiceField(choices=Screen.Status.choices)
