from rest_framework import serializers
from .models import Account


class AccountSerializer(serializers.ModelSerializer):
    platform_name = serializers.CharField(source="platform.name", read_only=True)
    email_address = serializers.EmailField(source="email.email", read_only=True)
    provider_name = serializers.CharField(source="email.provider.name", read_only=True, allow_null=True)
    screens_count = serializers.SerializerMethodField()
    available_screens = serializers.SerializerMethodField()

    class Meta:
        model = Account
        fields = "__all__"

    def validate_max_screens(self, value):
        if value < 1 or value > 5:
            raise serializers.ValidationError("La capacidad debe ser entre 1 y 5 pantallas.")
        return value

    def get_screens_count(self, obj):
        return obj.screens_count

    def get_available_screens(self, obj):
        return obj.available_screens


class AccountStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Account.Status.choices)
