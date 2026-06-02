from django.db.models import Count
from rest_framework.decorators import api_view
from rest_framework.response import Response


@api_view(["GET"])
def dashboard_summary(request):
    """Resumen general del negocio."""
    from accounts.models import Account
    from screens.models import Screen
    from customer_accounts.models import CustomerAccount
    from providers.models import Platform

    # Cuentas agrupadas por plataforma y estado
    accounts_by_platform = (
        Account.objects.values("platform__name", "status")
        .annotate(total=Count("id"))
        .order_by("platform__name", "status")
    )

    # Pantallas agrupadas por estado
    screens_by_status = (
        Screen.objects.values("status")
        .annotate(total=Count("id"))
        .order_by("status")
    )

    # Cuentas de clientes agrupadas por estado
    customer_accounts_by_status = (
        CustomerAccount.objects.values("status")
        .annotate(total=Count("id"))
        .order_by("status")
    )

    platforms = Platform.objects.values_list("name", flat=True)

    return Response({
        "total_accounts": Account.objects.count(),
        "total_screens": Screen.objects.count(),
        "total_customer_accounts": CustomerAccount.objects.count(),
        "accounts_by_platform": list(accounts_by_platform),
        "screens_by_status": list(screens_by_status),
        "customer_accounts_by_status": list(customer_accounts_by_status),
        "platforms": list(platforms),
    })
