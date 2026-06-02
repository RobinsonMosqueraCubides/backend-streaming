from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r"emails", views.EmailViewSet)

urlpatterns = [
    path("", include(router.urls)),
]
