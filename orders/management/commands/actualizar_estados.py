from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from orders.models import Order


class Command(BaseCommand):
    help = "Actualiza automáticamente los estados de las órdenes según fechas de cobro y corte"

    def handle(self, *args, **options):
        hoy = timezone.now().date()
        total = 0

        # 1. activo → por_cobrar (faltan 2 días o menos para fecha_cobro)
        qs1 = Order.objects.filter(status="activo").filter(
            fecha_cobro__lte=hoy + timedelta(days=2),
            fecha_cobro__isnull=False,
        )
        count1 = qs1.update(status="por_cobrar")
        total += count1
        if count1:
            self.stdout.write(f"  activo → por_cobrar: {count1} órdenes")

        # 2. por_cobrar → por_vencer (fecha_cobro ya pasó)
        qs2 = Order.objects.filter(status="por_cobrar").filter(
            fecha_cobro__lt=hoy,
            fecha_cobro__isnull=False,
        )
        count2 = qs2.update(status="por_vencer")
        total += count2
        if count2:
            self.stdout.write(f"  por_cobrar → por_vencer: {count2} órdenes")

        # 3. por_vencer → por_cortar (faltan 1 día o menos para fecha_corte)
        qs3 = Order.objects.filter(status="por_vencer").filter(
            fecha_corte__lte=hoy + timedelta(days=1),
            fecha_corte__isnull=False,
        )
        count3 = qs3.update(status="por_cortar")
        total += count3
        if count3:
            self.stdout.write(f"  por_vencer → por_cortar: {count3} órdenes")

        # 4. por_cortar → vencida (fecha_corte ya pasó)
        qs4 = Order.objects.filter(status="por_cortar").filter(
            fecha_corte__lt=hoy,
            fecha_corte__isnull=False,
        )
        count4 = qs4.update(status="vencida")
        total += count4
        if count4:
            self.stdout.write(f"  por_cortar → vencida: {count4} órdenes")

        if total == 0:
            self.stdout.write("  No hay cambios de estado.")
        else:
            self.stdout.write(f"  Total: {total} órdenes actualizadas.")
