"""
test_tasks.py — тести для Celery-задачі send_reminder_notifications.

Покриває:
  - позначення прострочених нагадувань як is_sent=True
  - ігнорування майбутніх і вже відправлених нагадувань
  - відправлення email (через locmem backend)
  - відсутність email якщо у юзера немає email
  - створення наступного нагадування для repeat_pattern (daily/weekly/monthly)
  - відсутність нового нагадування для repeat_pattern='none'
  - JSON-endpoint /reminders/check/ (права доступу + фільтрація)
"""
from django.test import TestCase, override_settings
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta
from django.core import mail

from notes_app.models import Note, Reminder
from notes_app.tasks import send_email_message, send_reminder_notifications


class SendReminderTaskTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            'alice', email='alice@test.com', password='pass123'
        )
        self.note = Note.objects.create(user=self.user, title='Test Note', content='')

    def _reminder(self, offset_minutes=-5, repeat='none', is_sent=False):
        return Reminder.objects.create(
            note=self.note,
            remind_at=timezone.now() + timedelta(minutes=offset_minutes),
            message='Тест нагадування',
            is_sent=is_sent,
            repeat_pattern=repeat,
        )

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_marks_due_reminder_as_sent(self):
        r = self._reminder(offset_minutes=-5)
        send_reminder_notifications()
        r.refresh_from_db()
        self.assertTrue(r.is_sent)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_ignores_future_reminders(self):
        r = self._reminder(offset_minutes=+10)
        send_reminder_notifications()
        r.refresh_from_db()
        self.assertFalse(r.is_sent)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_skips_already_sent_reminders(self):
        self._reminder(offset_minutes=-5, is_sent=True)
        count_before = Reminder.objects.count()
        send_reminder_notifications()
        self.assertEqual(Reminder.objects.count(), count_before)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_sends_email_to_user(self):
        self._reminder(offset_minutes=-5)
        send_reminder_notifications()
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn('alice@test.com', mail.outbox[0].to)
        self.assertIn('Test Note', mail.outbox[0].subject)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_no_email_when_user_has_no_email(self):
        self.user.email = ''
        self.user.save()
        self._reminder(offset_minutes=-5)
        send_reminder_notifications()
        self.assertEqual(len(mail.outbox), 0)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_daily_repeat_creates_next_reminder(self):
        r = self._reminder(offset_minutes=-5, repeat='daily')
        original_at = r.remind_at
        send_reminder_notifications()
        next_r = Reminder.objects.filter(note=self.note, is_sent=False).first()
        self.assertIsNotNone(next_r)
        diff = (next_r.remind_at - original_at).total_seconds()
        self.assertAlmostEqual(diff, 86400, delta=60)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_weekly_repeat_creates_next_reminder(self):
        r = self._reminder(offset_minutes=-5, repeat='weekly')
        original_at = r.remind_at
        send_reminder_notifications()
        next_r = Reminder.objects.filter(note=self.note, is_sent=False).first()
        self.assertIsNotNone(next_r)
        diff = (next_r.remind_at - original_at).total_seconds()
        self.assertAlmostEqual(diff, 7 * 86400, delta=60)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_monthly_repeat_creates_next_reminder(self):
        r = self._reminder(offset_minutes=-5, repeat='monthly')
        send_reminder_notifications()
        next_r = Reminder.objects.filter(note=self.note, is_sent=False).first()
        self.assertIsNotNone(next_r)
        self.assertGreater(next_r.remind_at, r.remind_at)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_no_repeat_when_pattern_is_none(self):
        self._reminder(offset_minutes=-5, repeat='none')
        count_before = Reminder.objects.count()
        send_reminder_notifications()
        self.assertEqual(Reminder.objects.count(), count_before)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_processes_multiple_reminders(self):
        r1 = self._reminder(offset_minutes=-10)
        r2 = self._reminder(offset_minutes=-3)
        send_reminder_notifications()
        r1.refresh_from_db()
        r2.refresh_from_db()
        self.assertTrue(r1.is_sent)
        self.assertTrue(r2.is_sent)
        self.assertEqual(len(mail.outbox), 2)


class SendEmailMessageTaskTest(TestCase):
    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_sends_email_message_through_celery_task(self):
        result = send_email_message.apply(
            kwargs={
                'subject': 'Celery notification',
                'message': 'Message from Celery task',
                'recipient_list': ['user@example.com'],
            }
        ).get()

        self.assertEqual(result['sent'], 1)
        self.assertEqual(result['recipients'], ['user@example.com'])
        self.assertEqual(len(mail.outbox), 1)
        self.assertEqual(mail.outbox[0].subject, 'Celery notification')
        self.assertIn('Message from Celery task', mail.outbox[0].body)

    @override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
    def test_empty_recipient_list_does_not_send_email(self):
        result = send_email_message.apply(
            kwargs={
                'subject': 'No recipients',
                'message': 'This should not be sent',
                'recipient_list': ['', '  '],
            }
        ).get()

        self.assertEqual(result['sent'], 0)
        self.assertEqual(result['recipients'], [])
        self.assertEqual(len(mail.outbox), 0)


class RemindersCheckViewTest(TestCase):
    def setUp(self):
        self.alice = User.objects.create_user(
            'alice', email='alice@test.com', password='pass123'
        )
        self.bob = User.objects.create_user(
            'bob', email='bob@test.com', password='pass123'
        )
        self.note = Note.objects.create(user=self.alice, title='Alice Note', content='')

    def test_requires_login(self):
        resp = self.client.get('/reminders/check/')
        self.assertEqual(resp.status_code, 302)
        self.assertIn('/accounts/login/', resp['Location'])

    def test_returns_json_with_due_reminder(self):
        self.client.force_login(self.alice)
        r = Reminder.objects.create(
            note=self.note,
            remind_at=timezone.now() - timedelta(minutes=30),
            message='Due now',
        )
        resp = self.client.get('/reminders/check/')
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(len(data['reminders']), 1)
        self.assertEqual(data['reminders'][0]['id'], r.id)
        self.assertIn('note__title', data['reminders'][0])

    def test_excludes_future_reminders(self):
        self.client.force_login(self.alice)
        Reminder.objects.create(
            note=self.note,
            remind_at=timezone.now() + timedelta(minutes=30),
        )
        resp = self.client.get('/reminders/check/')
        self.assertEqual(len(resp.json()['reminders']), 0)

    def test_excludes_reminders_older_than_1_hour(self):
        self.client.force_login(self.alice)
        Reminder.objects.create(
            note=self.note,
            remind_at=timezone.now() - timedelta(hours=2),
        )
        resp = self.client.get('/reminders/check/')
        self.assertEqual(len(resp.json()['reminders']), 0)

    def test_excludes_other_users_reminders(self):
        self.client.force_login(self.bob)
        Reminder.objects.create(
            note=self.note,
            remind_at=timezone.now() - timedelta(minutes=30),
        )
        resp = self.client.get('/reminders/check/')
        self.assertEqual(len(resp.json()['reminders']), 0)

    def test_returns_multiple_due_reminders(self):
        self.client.force_login(self.alice)
        for i in range(3):
            Reminder.objects.create(
                note=self.note,
                remind_at=timezone.now() - timedelta(minutes=10 + i),
            )
        resp = self.client.get('/reminders/check/')
        self.assertEqual(len(resp.json()['reminders']), 3)
