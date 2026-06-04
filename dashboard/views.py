from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db.models import Sum, Count
from accounts.models import Account
from screens.models import Screen
from customer_accounts.models import CustomerAccount
from orders.models import Order


@api_view(["GET"])
def resumen_financiero(request):
    """Resumen financiero general."""
    # Ingresos
    ingresos_orders = Order.objects.aggregate(total=Sum("total"))["total"] or 0
    ingresos_screens = Screen.objects.exclude(status="disponible").aggregate(
        total=Sum("precio_venta")
    )["total"] or 0
    ingresos_cuentas = CustomerAccount.objects.aggregate(
        total=Sum("precio_venta")
    )["total"] or 0

    # Egresos
    egresos = Account.objects.aggregate(total=Sum("purchase_price"))["total"] or 0

    # Balance
    ingresos_totales = ingresos_screens + ingresos_cuentas
    balance = ingresos_totales - egresos

    # Conteos
    cuentas_activas = Account.objects.filter(is_active=True).count()
    pantallas_vendidas = Screen.objects.exclude(status="disponible").count()
    pantallas_disponibles = Screen.objects.filter(status="disponible").count()
    ordenes_activas = Order.objects.filter(status="activo").count()

    return Response({
        "ingresos": {
            "orders_total": float(ingresos_orders),
            "screens_total": float(ingresos_screens),
            "customer_accounts_total": float(ingresos_cuentas),
            "total": float(ingresos_totales),
        },
        "egresos": float(egresos),
        "balance": float(balance),
        "conteos": {
            "cuentas_activas": cuentas_activas,
            "pantallas_vendidas": pantallas_vendidas,
            "pantallas_disponibles": pantallas_disponibles,
            "ordenes_activas": ordenes_activas,
        },
    })


@api_view(["GET"])
def ingresos_por_plataforma(request):
    """Ingresos totalizados por plataforma."""
    screens = (
        Screen.objects.exclude(status="disponible")
        .values("account__platform__name")
        .annotate(total=Sum("precio_venta"), count=Count("id"))
        .order_by("-total")
    )
    cuentas = (
        CustomerAccount.objects.values("account__platform__name")
        .annotate(total=Sum("precio_venta"), count=Count("id"))
        .order_by("-total")
    )

    # Merge
    result = {}
    for s in screens:
        name = s["account__platform__name"] or "Sin plataforma"
        result[name] = {"screens": float(s["total"] or 0), "cuentas": 0, "count_screens": s["count"]}
    for c in cuentas:
        name = c["account__platform__name"] or "Sin plataforma"
        if name not in result:
            result[name] = {"screens": 0, "cuentas": 0, "count_screens": 0}
        result[name]["cuentas"] = float(c["total"] or 0)
        result[name]["count_cuentas"] = c["count"]

    data = []
    for name, vals in result.items():
        vals["plataforma"] = name
        vals["total"] = vals["screens"] + vals["cuentas"]
        data.append(vals)
    data.sort(key=lambda x: x["total"], reverse=True)

    return Response(data)


@api_view(["GET"])
def ingresos_por_proveedor(request):
    """Ingresos totalizados por proveedor (via email → provider)."""
    screens = (
        Screen.objects.exclude(status="disponible")
        .values("account__email__provider__name")
        .annotate(total=Sum("precio_venta"), count=Count("id"))
        .order_by("-total")
    )
    cuentas = (
        CustomerAccount.objects.values("account__email__provider__name")
        .annotate(total=Sum("precio_venta"), count=Count("id"))
        .order_by("-total")
    )

    result = {}
    for s in screens:
        name = s["account__email__provider__name"] or "Sin proveedor"
        result[name] = {"screens": float(s["total"] or 0), "cuentas": 0, "count_screens": s["count"]}
    for c in cuentas:
        name = c["account__email__provider__name"] or "Sin proveedor"
        if name not in result:
            result[name] = {"screens": 0, "cuentas": 0, "count_screens": 0}
        result[name]["cuentas"] = float(c["total"] or 0)
        result[name]["count_cuentas"] = c["count"]

    data = []
    for name, vals in result.items():
        vals["proveedor"] = name
        vals["total"] = vals["screens"] + vals["cuentas"]
        data.append(vals)
    data.sort(key=lambda x: x["total"], reverse=True)

    return Response(data)


@api_view(["GET"])
def ingresos_por_cliente(request):
    """Ingresos totalizados por cliente."""
    screens = (
        Screen.objects.exclude(status="disponible")
        .values("customer__name")
        .annotate(total=Sum("precio_venta"), count=Count("id"))
        .order_by("-total")
    )
    cuentas = (
        CustomerAccount.objects.values("customer__name")
        .annotate(total=Sum("precio_venta"), count=Count("id"))
        .order_by("-total")
    )

    result = {}
    for s in screens:
        name = s["customer__name"] or "Sin cliente"
        result[name] = {"screens": float(s["total"] or 0), "cuentas": 0, "count_screens": s["count"]}
    for c in cuentas:
        name = c["customer__name"] or "Sin cliente"
        if name not in result:
            result[name] = {"screens": 0, "cuentas": 0, "count_screens": 0}
        result[name]["cuentas"] = float(c["total"] or 0)
        result[name]["count_cuentas"] = c["count"]

    data = []
    for name, vals in result.items():
        vals["cliente"] = name
        vals["total"] = vals["screens"] + vals["cuentas"]
        data.append(vals)
    data.sort(key=lambda x: x["total"], reverse=True)

    return Response(data)


@api_view(["GET"])
def egresos_por_proveedor(request):
    """Egresos (compras) totalizados por proveedor."""
    egresos = (
        Account.objects.values("email__provider__name")
        .annotate(total=Sum("purchase_price"), count=Count("id"))
        .order_by("-total")
    )
    data = []
    for e in egresos:
        data.append({
            "proveedor": e["email__provider__name"] or "Sin proveedor",
            "total": float(e["total"] or 0),
            "count": e["count"],
        })
    return Response(data)


@api_view(["GET"])
def egresos_por_plataforma(request):
    """Egresos (compras) totalizados por plataforma."""
    egresos = (
        Account.objects.values("platform__name")
        .annotate(total=Sum("purchase_price"), count=Count("id"))
        .order_by("-total")
    )
    data = []
    for e in egresos:
        data.append({
            "plataforma": e["platform__name"] or "Sin plataforma",
            "total": float(e["total"] or 0),
            "count": e["count"],
        })
    return Response(data)
