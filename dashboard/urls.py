from django.urls import path
from . import views

urlpatterns = [
    path("resumen/", views.resumen_financiero, name="dashboard-resumen"),
    path("ingresos/plataforma/", views.ingresos_por_plataforma, name="ingresos-plataforma"),
    path("ingresos/proveedor/", views.ingresos_por_proveedor, name="ingresos-proveedor"),
    path("ingresos/cliente/", views.ingresos_por_cliente, name="ingresos-cliente"),
    path("egresos/proveedor/", views.egresos_por_proveedor, name="egresos-proveedor"),
    path("egresos/plataforma/", views.egresos_por_plataforma, name="egresos-plataforma"),
]
