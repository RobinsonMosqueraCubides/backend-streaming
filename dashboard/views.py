from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db.models import Sum, Count, Q
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
def vencimientos_cliente(request):
    """Listado de órdenes con nombre del cliente, teléfono, fechas de vencimiento y plataformas."""
    orders = (
        Order.objects
        .select_related("customer")
        .prefetch_related(
            "screens__account__platform",
            "customer_accounts__account__platform",
        )
    )

    status = request.query_params.get("status")
    fecha_desde = request.query_params.get("fecha_desde")
    fecha_hasta = request.query_params.get("fecha_hasta")

    if status:
        orders = orders.filter(status=status)
    if fecha_desde:
        orders = orders.filter(fecha_corte__gte=fecha_desde)
    if fecha_hasta:
        orders = orders.filter(fecha_corte__lte=fecha_hasta)

    orders = orders.order_by("-fecha_corte")

    data = []
    for order in orders:
        plataformas = set()
        for screen in order.screens.all():
            if screen.account and screen.account.platform:
                plataformas.add(screen.account.platform.name)
        for ca in order.customer_accounts.all():
            if ca.account and ca.account.platform:
                plataformas.add(ca.account.platform.name)

        data.append({
            "orden_id": order.id,
            "cliente": order.customer.name if order.customer else "Sin cliente",
            "telefono": order.customer.phone if order.customer else None,
            "fecha_cobro": order.fecha_cobro.isoformat() if order.fecha_cobro else None,
            "fecha_corte": order.fecha_corte.isoformat() if order.fecha_corte else None,
            "status": order.status,
            "plataformas": sorted(plataformas),
            "items_count": order.items_count,
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


@api_view(["GET"])
def resumen_cliente(request, customer_id):
    """Resumen global de un cliente: datos personales, pantallas, cuentas y órdenes."""
    from customers.models import Customer

    try:
        customer = Customer.objects.get(pk=customer_id)
    except Customer.DoesNotExist:
        return Response({"error": "Cliente no encontrado"}, status=404)

    screens = (
        Screen.objects
        .filter(customer=customer)
        .select_related("account__platform")
        .order_by("-created_at")
    )
    customer_accounts = (
        CustomerAccount.objects
        .filter(customer=customer)
        .select_related("account__platform")
        .order_by("-created_at")
    )
    orders = (
        Order.objects
        .filter(customer=customer)
        .prefetch_related("screens", "customer_accounts")
        .order_by("-created_at")
    )

    total_gastado = sum(
        float(s.precio_venta or 0) for s in screens
    ) + sum(
        float(ca.precio_venta or 0) for ca in customer_accounts
    )

    return Response({
        "cliente": {
            "id": customer.id,
            "name": customer.name,
            "phone": customer.phone,
        },
        "resumen": {
            "total_pantallas": screens.count(),
            "total_cuentas": customer_accounts.count(),
            "total_ordenes": orders.count(),
            "total_gastado": total_gastado,
        },
        "pantallas": [
            {
                "id": s.id,
                "plataforma": s.account.platform.name if s.account and s.account.platform else None,
                "pin": s.pin,
                "precio_venta": float(s.precio_venta) if s.precio_venta else None,
                "status": s.status,
                "fecha_inicio": s.fecha_inicio.isoformat() if s.fecha_inicio else None,
                "fecha_cobro": s.fecha_cobro.isoformat() if s.fecha_cobro else None,
                "fecha_corte": s.fecha_corte.isoformat() if s.fecha_corte else None,
            }
            for s in screens
        ],
        "cuentas": [
            {
                "id": ca.id,
                "plataforma": ca.account.platform.name if ca.account and ca.account.platform else None,
                "precio_venta": float(ca.precio_venta) if ca.precio_venta else None,
                "status": ca.status,
                "fecha_inicio": ca.fecha_inicio.isoformat() if ca.fecha_inicio else None,
                "fecha_cobro": ca.fecha_cobro.isoformat() if ca.fecha_cobro else None,
                "fecha_corte": ca.fecha_corte.isoformat() if ca.fecha_corte else None,
            }
            for ca in customer_accounts
        ],
        "ordenes": [
            {
                "id": o.id,
                "total": float(o.total) if o.total else None,
                "status": o.status,
                "fecha_cobro": o.fecha_cobro.isoformat() if o.fecha_cobro else None,
                "fecha_corte": o.fecha_corte.isoformat() if o.fecha_corte else None,
                "items_count": o.items_count,
            }
            for o in orders
        ],
    })


@api_view(["GET"])
def inventario(request):
    """Resumen de inventario de cuentas por plataforma y estado."""
    from providers.models import Platform

    cuentas = (
        Account.objects
        .filter(is_active=True)
        .values("platform__name")
        .annotate(
            total=Count("id"),
            disponibles=Count("id", filter=Q(screens__status="disponible")),
            activas=Count("id", filter=Q(status="activo")),
            por_vencer=Count("id", filter=Q(status="por_vencer")),
            vencidas=Count("id", filter=Q(status="vencida")),
            caidas=Count("id", filter=Q(status="caida")),
        )
        .order_by("-total")
    )

    data = []
    totales = {"total": 0, "disponibles": 0, "activas": 0, "por_vencer": 0, "vencidas": 0, "caidas": 0}

    for c in cuentas:
        plataforma = c["platform__name"] or "Sin plataforma"
        entry = {
            "plataforma": plataforma,
            "total": c["total"],
            "disponibles": c["disponibles"],
            "activas": c["activas"],
            "por_vencer": c["por_vencer"],
            "vencidas": c["vencidas"],
            "caidas": c["caidas"],
        }
        data.append(entry)
        for key in totales:
            totales[key] += c[key]

    return Response({"cuentas": data, "totales": totales})


@api_view(["GET"])
def clientes_inactivos(request):
    """Clientes sin compras en los últimos X días (default 30)."""
    from datetime import timedelta
    from django.utils import timezone
    from customers.models import Customer

    dias = int(request.query_params.get("dias", 30))
    fecha_limite = timezone.now().date() - timedelta(days=dias)

    clientes_con_compra = set(
        Screen.objects.filter(customer__isnull=False, created_at__date__gte=fecha_limite)
        .values_list("customer_id", flat=True)
    )
    clientes_con_compra.update(
        CustomerAccount.objects.filter(customer__isnull=False, created_at__date__gte=fecha_limite)
        .values_list("customer_id", flat=True)
    )

    todos_clientes = Customer.objects.all()
    data = []
    for customer in todos_clientes:
        if customer.id in clientes_con_compra:
            continue

        ultima_pantalla = (
            Screen.objects.filter(customer=customer)
            .order_by("-created_at")
            .first()
        )
        ultima_cuenta = (
            CustomerAccount.objects.filter(customer=customer)
            .order_by("-created_at")
            .first()
        )

        ultima_fecha = None
        if ultima_pantalla and ultima_cuenta:
            ultima_fecha = max(ultima_pantalla.created_at.date(), ultima_cuenta.created_at.date())
        elif ultima_pantalla:
            ultima_fecha = ultima_pantalla.created_at.date()
        elif ultima_cuenta:
            ultima_fecha = ultima_cuenta.created_at.date()

        total_compras = (
            Screen.objects.filter(customer=customer).exclude(status="disponible").count()
            + CustomerAccount.objects.filter(customer=customer).count()
        )
        total_gastado = float(
            Screen.objects.filter(customer=customer).exclude(status="disponible")
            .aggregate(s=Sum("precio_venta"))["s"] or 0
        ) + float(
            CustomerAccount.objects.filter(customer=customer)
            .aggregate(s=Sum("precio_venta"))["s"] or 0
        )

        dias_sin_compra = (timezone.now().date() - ultima_fecha).days if ultima_fecha else None

        data.append({
            "cliente_id": customer.id,
            "nombre": customer.name,
            "telefono": customer.phone,
            "ultima_compra": ultima_fecha.isoformat() if ultima_fecha else None,
            "dias_sin_compra": dias_sin_compra,
            "total_compras": total_compras,
            "total_gastado": total_gastado,
        })

    data.sort(key=lambda x: x["dias_sin_compra"] or 0, reverse=True)
    return Response(data)
