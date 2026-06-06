from rest_framework import serializers
from .models import CustomerAccount


class CustomerAccountSerializer(serializers.ModelSerializer):
    account_info = serializers.CharField(source="account.__str__", read_only=True)
    customer_name = serializers.CharField(source="customer.name", read_only=True)

    class Meta:
        model = CustomerAccount
        fields = "__all__"


class CustomerAccountStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=CustomerAccount.Status.choices)


class BulkCustomerAccountStatusSerializer(serializers.Serializer):
    ids = serializers.ListField(child=serializers.IntegerField(min_value=1))
    status = serializers.ChoiceField(choices=CustomerAccount.Status.choices)
