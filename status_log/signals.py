from django.db.models.signals import pre_save
from django.dispatch import receiver
from accounts.models import Account
from screens.models import Screen
from customer_accounts.models import CustomerAccount
from .models import StatusLog


@receiver(pre_save, sender=Account)
@receiver(pre_save, sender=Screen)
@receiver(pre_save, sender=CustomerAccount)
def track_status_change(sender, instance, **kwargs):
    """Registra en status_log cada cambio de estado."""
    if instance.pk:
        try:
            old = sender.objects.get(pk=instance.pk)
            if old.status != instance.status:
                StatusLog.objects.create(
                    model_name=sender._meta.object_name,
                    object_id=instance.pk,
                    old_status=old.status,
                    new_status=instance.status,
                )
        except sender.DoesNotExist:
            pass
