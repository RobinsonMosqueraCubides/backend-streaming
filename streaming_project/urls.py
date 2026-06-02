from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    # API
    path("api/", include("providers.urls")),
    path("api/", include("emails.urls")),
    path("api/", include("customers.urls")),
    path("api/", include("accounts.urls")),
    path("api/", include("screens.urls")),
    path("api/", include("customer_accounts.urls")),
    path("api/dashboard/", include("dashboard.urls")),
]
