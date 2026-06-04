from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path("admin/", admin.site.urls),
    # API
    path("api/", include("providers.urls")),
    path("api/", include("emails.urls")),
    path("api/", include("customers.urls")),
    path("api/", include("accounts.urls")),
    path("api/", include("screens.urls")),
    path("api/", include("customer_accounts.urls")),
    path("api/", include("orders.urls")),
    path("api/dashboard/", include("dashboard.urls")),
    # Docs
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="docs"),
]
