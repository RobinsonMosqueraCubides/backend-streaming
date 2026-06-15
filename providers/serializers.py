from rest_framework import serializers
from .models import Platform, Provider, ProviderWarrantyClaim


class PlatformSerializer(serializers.ModelSerializer):
    class Meta:
        model = Platform
        fields = "__all__"


class ProviderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Provider
        fields = "__all__"


class ProviderWarrantyClaimSerializer(serializers.ModelSerializer):
    provider_name = serializers.CharField(source="provider.name", read_only=True)
    platform_name = serializers.CharField(source="account.platform.name", read_only=True)
    original_email = serializers.CharField(source="account.email.email", read_only=True)
    replacement_email = serializers.CharField(source="replacement_account.email.email", read_only=True)

    class Meta:
        model = ProviderWarrantyClaim
        fields = "__all__"


class ApplyProviderWarrantySerializer(serializers.Serializer):
    account_id = serializers.IntegerField()
    claim_type = serializers.ChoiceField(choices=ProviderWarrantyClaim.ClaimType.choices)
    fecha_reclamo = serializers.DateField(required=False, allow_null=True)
    new_credentials = serializers.CharField(required=False, allow_null=True, allow_blank=True)
    new_email_password = serializers.CharField(required=False, allow_null=True, allow_blank=True)
    new_email_address = serializers.CharField(required=False, allow_null=True, allow_blank=True)
    replacement_duration_days = serializers.IntegerField(required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_null=True, allow_blank=True)

