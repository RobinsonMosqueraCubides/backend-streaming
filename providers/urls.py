from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r"platforms", views.PlatformViewSet)
router.register(r"providers", views.ProviderViewSet)

urlpatterns = [
    path("", include(router.urls)),
]
