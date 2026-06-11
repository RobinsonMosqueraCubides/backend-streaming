from rest_framework import serializers
from .models import CustomerAccount


class CustomerAccountSerializer(serializers.ModelSerializer):
    account_info = serializers.SerializerMethodField()
    customer_name = serializers.CharField(source="customer.name", read_only=True)

    class Meta:
        model = CustomerAccount
        fields = "__all__"

    def get_account_info(self, obj):
        return str(obj.account) if obj.account else None


class CustomerAccountStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=CustomerAccount.Status.choices)


class BulkCustomerAccountStatusSerializer(serializers.Serializer):
    ids = serializers.ListField(child=serializers.IntegerField(min_value=1))
    status = serializers.ChoiceField(choices=CustomerAccount.Status.choices)
