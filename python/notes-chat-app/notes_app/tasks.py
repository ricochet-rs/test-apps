from celery import shared_task
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from datetime import timedelta


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_kwargs={"max_retries": 3},
)
def send_email_message(self, *, subject, message, recipient_list, from_email=None):
    """
    Надсилає email-повідомлення через Celery.

    Використання:
        send_email_message.delay(
            subject="Нове повідомлення",
            message="Текст повідомлення",
            recipient_list=["user@example.com"],
        )
    """
    recipients = [
        email.strip()
        for email in recipient_list
        if isinstance(email, str) and email.strip()
    ]
    if not recipients:
        return {"sent": 0, "recipients": []}

    sent_count = send_mail(
        subject=subject,
        message=message,
        from_email=from_email or settings.DEFAULT_FROM_EMAIL,
        recipient_list=recipients,
        fail_silently=False,
    )
    return {"sent": sent_count, "recipients": recipients}


@shared_task
def send_reminder_notifications():
    """
    Знаходить усі прострочені нагадування і:
      1. Надсилає email (у dev — виводить у консоль).
      2. Позначає is_sent=True.
      3. Якщо repeat_pattern ≠ none — створює наступне нагадування.

    Викликається Celery Beat кожну хвилину.
    """
    from .models import Reminder

    now = timezone.now()
    pending = (
        Reminder.objects
        .select_related('note__user')
        .filter(remind_at__lte=now, is_sent=False)
    )

    for reminder in pending:
        user = reminder.note.user

        if user.email:
            send_mail(
                subject=f'Нагадування: {reminder.note.title}',
                message=reminder.message or f'Час нагадування для «{reminder.note.title}».',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,
            )

        reminder.is_sent = True
        reminder.save(update_fields=['is_sent'])

        _schedule_next(reminder)


def _schedule_next(reminder):
    if reminder.repeat_pattern == 'none':
        return

    from .models import Reminder
    from dateutil.relativedelta import relativedelta

    delta_map = {
        'daily':   relativedelta(days=1),
        'weekly':  relativedelta(weeks=1),
        'monthly': relativedelta(months=1),
    }
    delta = delta_map.get(reminder.repeat_pattern)
    if delta:
        Reminder.objects.create(
            note=reminder.note,
            remind_at=reminder.remind_at + delta,
            message=reminder.message,
            is_sent=False,
            repeat_pattern=reminder.repeat_pattern,
        )
