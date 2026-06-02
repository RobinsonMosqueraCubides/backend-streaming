from django.db.models import Count
from rest_framework.decorators import api_view
from rest_framework.response import Response


@api_view(["GET"])
def dashboard_vencidas(request):
    """Cuentas y pantallas por vencer o vencidas."""
    from accounts.models import Account
    from screens.models import Screen
    from customer_accounts.models import CustomerAccount
    from datetime import date

    hoy = date.today()

    # Cuentas vencidas o por vencer
    cuentas = Account.objects.filter(
        status__in=["por_vencer", "vencida"]
    ).select_related("platform", "provider").values(
        "id", "platform__name", "status", "fecha_compra"
    ).order_by("status", "fecha_compra")

    # Pantallas vencidas o por vencer
    pantallas = Screen.objects.filter(
        status__in=["por_vencer", "vencida"]
    ).select_related("account", "customer").values(
        "id", "pin", "status", "fecha_inicio",
        "account__id", "customer__name"
    ).order_by("status", "fecha_inicio")

    # Cuentas de clientes vencidas o por vencer
    customer_accounts = CustomerAccount.objects.filter(
        status__in=["por_vencer", "vencida"]
    ).select_related("account", "customer").values(
        "id", "status", "fecha_inicio",
        "account__id", "customer__name"
    ).order_by("status", "fecha_inicio")

    return Response({
        "fecha_consulta": hoy,
        "total_vencidas": len(cuentas) + len(pantallas) + len(customer_accounts),
        "cuentas_por_vencer": [
            c for c in cuentas if c["status"] == "por_vencer"
        ],
        "cuentas_vencidas": [
            c for c in cuentas if c["status"] == "vencida"
        ],
        "pantallas_por_vencer": [
            p for p in pantallas if p["status"] == "por_vencer"
        ],
        "pantallas_vencidas": [
            p for p in pantallas if p["status"] == "vencida"
        ],
        "customer_accounts_por_vencer": [
            ca for ca in customer_accounts if ca["status"] == "por_vencer"
        ],
        "customer_accounts_vencidas": [
            ca for ca in customer_accounts if ca["status"] == "vencida"
        ],
    })


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
