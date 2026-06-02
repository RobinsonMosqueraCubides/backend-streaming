from rest_framework import serializers
from .models import Email


class EmailSerializer(serializers.ModelSerializer):
    provider_name = serializers.CharField(source="provider.name", read_only=True)

    class Meta:
        model = Email
        fields = "__all__"
