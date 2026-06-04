from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import FilterSet
from .models import Account
from .serializers import AccountSerializer, AccountStatusSerializer
from screens.serializers import ScreenSerializer


class AccountFilter(FilterSet):
    class Meta:
        model = Account
        fields = {
            "status": ["exact"],
            "platform": ["exact"],
            "is_active": ["exact"],
            "fecha_compra": ["exact", "gte", "lte"],
        }


class AccountViewSet(viewsets.ModelViewSet):
    queryset = Account.objects.select_related("platform", "email").all()
    serializer_class = AccountSerializer
    filterset_class = AccountFilter
    search_fields = ["credentials", "observaciones", "notes"]

    @action(detail=True, methods=["patch"])
    def change_status(self, request, pk=None):
        account = self.get_object()
        serializer = AccountStatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        account.status = serializer.validated_data["status"]
        account.save(update_fields=["status", "updated_at"])
        return Response(AccountSerializer(account).data)

    @action(detail=True, methods=["get"])
    def screens(self, request, pk=None):
        account = self.get_object()
        screens = account.screens.all()
        return Response(ScreenSerializer(screens, many=True).data)
