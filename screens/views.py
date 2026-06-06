from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import FilterSet
from .models import Screen
from .serializers import ScreenSerializer, ScreenStatusSerializer, BulkScreenStatusSerializer


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

    @action(detail=False, methods=["patch"])
    def bulk_change_status(self, request):
        serializer = BulkScreenStatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        ids = serializer.validated_data["ids"]
        new_status = serializer.validated_data["status"]

        screens = Screen.objects.filter(id__in=ids)
        updated = screens.update(status=new_status)
        found_ids = set(screens.values_list("id", flat=True))
        errors = [id_ for id_ in ids if id_ not in found_ids]

        return Response({"updated": updated, "errors": errors})
