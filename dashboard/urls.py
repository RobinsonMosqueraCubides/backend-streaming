from django.urls import path
from . import views

urlpatterns = [
    path("resumen/", views.resumen_financiero, name="dashboard-resumen"),
    path("ingresos/plataforma/", views.ingresos_por_plataforma, name="ingresos-plataforma"),
    path("ingresos/proveedor/", views.ingresos_por_proveedor, name="ingresos-proveedor"),
    path("ingresos/cliente/", views.ingresos_por_cliente, name="ingresos-cliente"),
    path("egresos/proveedor/", views.egresos_por_proveedor, name="egresos-proveedor"),
    path("egresos/plataforma/", views.egresos_por_plataforma, name="egresos-plataforma"),
    path("vencimientos/", views.vencimientos_cliente, name="vencimientos-cliente"),
    path("cliente/<int:customer_id>/", views.resumen_cliente, name="resumen-cliente"),
    path("inventario/", views.inventario, name="dashboard-inventario"),
    path("clientes-inactivos/", views.clientes_inactivos, name="clientes-inactivos"),
    path("clientes-antiguos/", views.clientes_antiguos, name="clientes-antiguos"),
    path("cobros/", views.cobros_pendientes, name="cobros-pendientes"),
    path("cobros/marcar/", views.marcar_cobro, name="cobros-marcar"),
    path("pagos/actualizar-pago/", views.actualizar_pago, name="pagos-actualizar"),
    path("pagos/fecha-personalizada/", views.fecha_personalizada, name="pagos-fecha"),
    path("pagos/corte/", views.corte_pago, name="pagos-corte"),
]
