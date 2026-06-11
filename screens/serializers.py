from rest_framework import serializers
from .models import Screen


class ScreenSerializer(serializers.ModelSerializer):
    account_info = serializers.SerializerMethodField()
    customer_name = serializers.CharField(source="customer.name", read_only=True, allow_null=True)

    class Meta:
        model = Screen
        fields = "__all__"

    def get_account_info(self, obj):
        return str(obj.account) if obj.account else None


class ScreenStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Screen.Status.choices)


class BulkScreenStatusSerializer(serializers.Serializer):
    ids = serializers.ListField(child=serializers.IntegerField(min_value=1))
    status = serializers.ChoiceField(choices=Screen.Status.choices)
