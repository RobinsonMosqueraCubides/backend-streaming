from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import FilterSet
from .models import Screen
from .serializers import ScreenSerializer, ScreenStatusSerializer


class ScreenFilter(FilterSet):
    class Meta:
        model = Screen
        fields = {
            "status": ["exact"],
            "account": ["exact"],
            "customer": ["exact"],
            "fecha_inicio": ["exact", "gte", "lte"],
        }


class ScreenViewSet(viewsets.ModelViewSet):
    queryset = Screen.objects.select_related("account", "customer").all()
    serializer_class = ScreenSerializer
    filterset_class = ScreenFilter
    search_fields = ["pin", "profile_name", "observaciones"]

    @action(detail=True, methods=["patch"])
    def change_status(self, request, pk=None):
        screen = self.get_object()
        serializer = ScreenStatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        screen.status = serializer.validated_data["status"]
        screen.save(update_fields=["status", "updated_at"])
        return Response(ScreenSerializer(screen).data)
