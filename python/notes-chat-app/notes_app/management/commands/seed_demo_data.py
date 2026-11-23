"""
seed_demo_data.py — заповнює БД реалістичними демо-даними.

Використання:
    python manage.py seed_demo_data              # створити (ідемпотентно)
    python manage.py seed_demo_data --reset      # очистити і створити заново
    python manage.py seed_demo_data --force      # дозволити на DEBUG=False

Через Docker:
    docker compose run --rm web python manage.py seed_demo_data
"""
from __future__ import annotations

from datetime import timedelta
from decimal import Decimal

from django.conf import settings
from django.contrib.auth.models import Group as DjangoGroup, User
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.utils import timezone

from notes_app.models import (
    ChatMessage,
    Note,
    Notebook,
    Reminder,
    ShopItem,
    ShoppingList,
    Tag,
    TodoItem,
    TodoList,
    UserProfile,
)
from notes_app import services


DEMO_PASSWORD = "demo1234"
DEMO_USERNAME_PREFIX = "demo_"
DEMO_GROUP_PREFIX = "demo_"

# ── Користувачі ───────────────────────────────────────────────────────────────

USER_DATA = [
    {
        "username": "demo_alice",
        "email": "alice@demo.example.com",
        "first_name": "Аліса",
        "last_name": "Шевченко",
        "display_name": "Аліса Шевченко",
        "timezone": "Europe/Kyiv",
        "bio": "Розробниця, читаю технічні книги й пишу нотатки до кожного розділу.",
    },
    {
        "username": "demo_bob",
        "email": "bob@demo.example.com",
        "first_name": "Боб",
        "last_name": "Коваленко",
        "display_name": "Боб Коваленко",
        "timezone": "Europe/Kyiv",
        "bio": "Тімлід. Списки задач — мій основний інструмент управління часом.",
    },
    {
        "username": "demo_carol",
        "email": "carol@demo.example.com",
        "first_name": "Кароль",
        "last_name": "Мельник",
        "display_name": "Кароль Мельник",
        "timezone": "Europe/Kyiv",
        "bio": "UX-дизайнерка. Збираю ідеї, цитати й натхнення у нотатках.",
    },
]

# ── Групи (назва, список username учасників) ──────────────────────────────────

GROUP_DATA = [
    ("demo_команда_розробки", "Команда розробки", ["demo_alice", "demo_bob", "demo_carol"]),
    ("demo_сімейний_чат",    "Сімейний чат",      ["demo_alice", "demo_carol"]),
]

# ── Теги (name, color) — однакові для кожного юзера ──────────────────────────

TAG_DATA = [
    ("робота",     "#4dabf7"),
    ("особисте",   "#ff6b6b"),
    ("навчання",   "#ffd43b"),
    ("важливо",    "#b197fc"),
    ("ідеї",       "#69db7c"),
    ("перечитати", "#ffa94d"),
]

# ── Записники (title, color, is_default) ─────────────────────────────────────

NOTEBOOK_DATA = [
    ("Робочі нотатки",  "#4A90E2", True),
    ("Особисте",        "#E24A4A", False),
    ("Навчання Python", "#4AE29A", False),
]

# ── Нотатки (title, content, priority, is_pinned, notebook_idx, tag_names, group_slug_or_None)
#   priority: 1=low, 2=medium, 3=high, 4=urgent

NOTE_DATA = [
    (
        "Архітектура нового модуля",
        "Визначити межі bounded context для модуля сповіщень.\n"
        "Порти: NotificationPort (вихідний), UserPort.\n"
        "Адаптери: EmailAdapter, WebSocketAdapter.",
        3, True, 0, ["робота", "важливо"], "demo_команда_розробки",
    ),
    (
        "Docker Compose + PostgreSQL",
        "Налаштувати healthcheck для db-сервісу.\n"
        "CONN_MAX_AGE=0 обов'язково при async-режимі — інакше race condition.",
        2, False, 0, ["робота", "навчання"], None,
    ),
    (
        "Django Channels: channel layer",
        "InMemoryChannelLayer — тільки для одного процесу.\n"
        "RedisChannelLayer — для production і горизонтального масштабування.\n"
        "Ключ: group_send() доставляє всім підписаним consumer-ам.",
        2, True, 2, ["навчання"], None,
    ),
    (
        "Ідея: фільтрація нотаток за датою",
        "Додати DateRangeFilter у note_list view.\n"
        "Selectors: додати параметри date_from, date_to у get_user_notes().\n"
        "UI: два date-поля у sidebar.",
        2, False, 0, ["ідеї", "робота"], None,
    ),
    (
        "Книги до прочитання",
        "1. Django ORM — Two Scoops of Django\n"
        "2. Asyncio у Python — Matthew Fowler\n"
        "3. Clean Architecture — Robert Martin",
        1, False, 1, ["навчання", "перечитати"], None,
    ),
    (
        "Конспект: asyncio event loop",
        "Event loop — центр asyncio. Обробляє корутини, I/O, таймери.\n"
        "await дозволяє іншим корутинам працювати поки поточна чекає на I/O.\n"
        "database_sync_to_async — запуск sync-ORM у thread pool.",
        3, False, 2, ["навчання"], None,
    ),
    (
        "Зворотний зв'язок після демо",
        "Команда відзначила: WebSocket-чат працює стабільно.\n"
        "Побажання: показувати статус 'набирає...' при введенні тексту.\n"
        "Пріоритет: низький, наступний спринт.",
        1, False, 0, ["робота"], "demo_команда_розробки",
    ),
    (
        "Рефакторинг selectors.py",
        "Об'єднати get_user_notes і get_note_detail — дублюється prefetch.\n"
        "Винести user_groups у окремий selector get_user_groups_qs().\n"
        "Покрити тестами після рефакторингу.",
        2, False, 0, ["робота", "важливо"], None,
    ),
    (
        "Плани на вихідні",
        "Поїхати на природу, відпочити від екрану.\n"
        "Прочитати хоча б 50 сторінок книги.",
        1, False, 1, ["особисте"], None,
    ),
    (
        "WebSocket: оптимізація history",
        "Зараз load_history() завантажує 50 повідомлень при кожному connect().\n"
        "Ідея: завантажувати тільки якщо клієнт надсилає last_message_id.\n"
        "Зменшить навантаження при реконнекті.",
        2, True, 0, ["ідеї", "навчання"], "demo_команда_розробки",
    ),
]

# ── Нагадування (note_idx, days_from_now, message, repeat) ───────────────────

REMINDER_DATA = [
    (0,  3,  "Перевірити прогрес архітектури",          "none"),
    (3,  7,  "Реалізувати фільтрацію за датою",          "none"),
    (7, 14,  "Code review рефакторингу selectors",       "none"),
    (5,  1,  "Повторити event loop перед співбесідою",   "weekly"),
]

# ── Списки задач (title, description, items, shared_with_usernames) ──────────

TODO_DATA = [
    (
        "Задачі спринту",
        "Технічні задачі поточного спринту",
        [
            "Написати тести для GroupChatConsumer",
            "Оновити GitHub Actions workflow",
            "Рефакторинг selectors.py",
            "Документація WebSocket API",
            "Code review PR #42",
        ],
        ["demo_bob"],
    ),
    (
        "Домашні справи",
        "Побутові задачі на тиждень",
        [
            "Прибирання квартири",
            "Сплатити комунальні",
            "Замовити продукти",
        ],
        [],
    ),
    (
        "Навчальний план",
        "Технічне навчання на місяць",
        [
            "Django Channels: повна документація",
            "PostgreSQL: EXPLAIN ANALYZE для складних запитів",
            "Python asyncio: практика з реальним проєктом",
            "Redis: pub/sub та структури даних",
        ],
        [],
    ),
]

# ── Списки покупок (title, store, items: [(name, qty, unit, price)], group_slug) ─

SHOPPING_DATA = [
    (
        "Продукти на тиждень",
        "АТБ",
        [
            ("Молоко",         Decimal("2"),   "л",  Decimal("45.00")),
            ("Хліб",           Decimal("2"),   "шт", Decimal("38.00")),
            ("Яблука",         Decimal("1"),   "кг", Decimal("55.00")),
            ("Кава мелена",    Decimal("250"), "г",  Decimal("120.00")),
            ("Гречка",         Decimal("1"),   "кг", Decimal("62.00")),
            ("Олія",           Decimal("1"),   "л",  Decimal("75.00")),
        ],
        None,
    ),
    (
        "Офісне обладнання",
        "Rozetka",
        [
            ("Механічна клавіатура", Decimal("1"), "шт", Decimal("2800.00")),
            ("Мишка бездротова",     Decimal("1"), "шт", Decimal("850.00")),
            ("Килимок для мишки XL", Decimal("1"), "шт", Decimal("320.00")),
            ("USB-хаб 7-портовий",   Decimal("1"), "шт", Decimal("480.00")),
        ],
        None,
    ),
    (
        "Спільні покупки для офісу",
        "Metro",
        [
            ("Кава в зернах 1 кг",  Decimal("2"),  "шт", Decimal("450.00")),
            ("Цукор",               Decimal("2"),  "кг", Decimal("80.00")),
            ("Чай асорті",          Decimal("3"),  "шт", Decimal("95.00")),
            ("Серветки",            Decimal("10"), "шт", Decimal("25.00")),
        ],
        "demo_команда_розробки",
    ),
]

# ── Повідомлення чату (group_slug → [(author_username, text)]) ────────────────

CHAT_DATA = {
    "demo_команда_розробки": [
        ("demo_alice", "Привіт команда! Починаємо новий спринт 🚀"),
        ("demo_bob",   "Всім привіт! Я переглянув задачі — виглядає реалістично."),
        ("demo_carol", "Привіт! Чи є якісь блокери з дизайну?"),
        ("demo_alice", "Поки ні, але треба уточнити UX для фільтрів."),
        ("demo_carol", "Ок, підготую макети до завтрашнього дня."),
        ("demo_bob",   "До речі, workflow для GitHub Actions оновив — тепер тести йдуть через Docker."),
        ("demo_alice", "Бачила, дякую! Selenium через standalone-chrome — набагато стабільніше."),
        ("demo_carol", "А коли плануємо демо замовнику?"),
        ("demo_bob",   "Думаю наприкінці спринту, через 12 днів."),
        ("demo_alice", "Зроблю нотатки по всіх фічах до демо."),
        ("demo_carol", "Я підготую UI-screenshots для презентації."),
        ("demo_bob",   "Чудово! Тоді зустрічаємось на стендапі о 10:00."),
        ("demo_alice", "Побачимось! До речі, хтось тестував WebSocket на мобільному?"),
        ("demo_carol", "Так, на iOS Safari — все ок. На Android Chrome теж."),
        ("demo_bob",   "Відмінно. Закриваємо цю задачу."),
        ("demo_alice", "PR з рефакторингом selectors.py готовий до ревью."),
        ("demo_bob",   "Переглянув — є один коментар, але загалом добре."),
        ("demo_alice", "Дякую! Виправлю і замерджу."),
        ("demo_carol", "Нагадайте — ми деплоїмо в п'ятницю?"),
        ("demo_bob",   "Так, о 18:00. Всі будьте напоготові 👍"),
    ],
    "demo_сімейний_чат": [
        ("demo_alice", "Привіт! Де зустрічаємось у вихідні?"),
        ("demo_carol", "Привіт! Пропоную кав'ярню біля парку о 12:00."),
        ("demo_alice", "Чудово! Я куплю пиріжки до чаю."),
        ("demo_carol", "Візьми також яблучний. Там смачні 😊"),
        ("demo_alice", "Ок! До речі, мама телефонувала — хоче побачити нас разом."),
        ("demo_carol", "Може наступного тижня в неділю? Я буду вільна."),
        ("demo_alice", "Домовились! Напишу їй."),
        ("demo_carol", "Список покупок для офісу поповнила — перевір."),
        ("demo_alice", "Бачу, дякую! Замовлю сьогодні."),
        ("demo_carol", "До зустрічі в суботу! ☕"),
    ],
}


class Command(BaseCommand):
    help = "Seeds realistic demo data for notes_chat_app (users, notes, todos, chats)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Delete existing demo data before seeding.",
        )
        parser.add_argument(
            "--force",
            action="store_true",
            help="Allow seeding when DEBUG=False.",
        )

    def handle(self, *args, **options):
        if not settings.DEBUG and not options["force"]:
            raise CommandError("Demo data seeding is disabled when DEBUG=False. Use --force to override.")

        with transaction.atomic():
            if options["reset"]:
                self.stdout.write(self.style.WARNING("Resetting demo data..."))
                self._reset()

            users = self._create_users()
            groups = self._create_groups(users)
            tags = self._create_tags(users)
            notebooks = self._create_notebooks(users)
            notes = self._create_notes(users, notebooks, tags, groups)
            self._create_reminders(users, notes)
            self._create_todo_lists(users)
            self._create_shopping_lists(users, groups)
            self._create_chat_messages(users, groups)
            summary = self._summary(users, groups)

        self.stdout.write(self.style.SUCCESS("Demo data created successfully."))
        self.stdout.write("Login credentials (DEBUG only):")
        for u in USER_DATA:
            self.stdout.write(f"  {u['username']} / {DEMO_PASSWORD}")
        self.stdout.write("")
        for label, count in summary.items():
            self.stdout.write(f"  {label}: {count}")

    # ── Reset ──────────────────────────────────────────────────────────────────

    def _reset(self):
        deleted_users, _ = User.objects.filter(username__startswith=DEMO_USERNAME_PREFIX).delete()
        deleted_groups, _ = DjangoGroup.objects.filter(name__startswith="demo_").delete()
        self.stdout.write(f"  Deleted {deleted_users} users, {deleted_groups} groups and their related data.")

    # ── Users ──────────────────────────────────────────────────────────────────

    def _create_users(self):
        self.stdout.write("Creating demo users...")
        users = {}
        for data in USER_DATA:
            user, _ = User.objects.update_or_create(
                username=data["username"],
                defaults={
                    "email": data["email"],
                    "first_name": data["first_name"],
                    "last_name": data["last_name"],
                    "is_active": True,
                    "is_staff": False,
                    "is_superuser": False,
                },
            )
            user.set_password(DEMO_PASSWORD)
            user.save()
            UserProfile.objects.update_or_create(
                user=user,
                defaults={
                    "display_name": data["display_name"],
                    "timezone": data["timezone"],
                    "bio": data["bio"],
                },
            )
            users[data["username"]] = user
        return users

    # ── Groups ─────────────────────────────────────────────────────────────────

    def _create_groups(self, users):
        self.stdout.write("Creating demo groups...")
        groups = {}
        for slug, display_name, member_usernames in GROUP_DATA:
            group, _ = DjangoGroup.objects.update_or_create(
                name=slug,
                defaults={},
            )
            # Ensure correct members (don't remove extras if already there)
            for username in member_usernames:
                if username in users:
                    group.user_set.add(users[username])
            groups[slug] = group
        return groups

    # ── Tags ───────────────────────────────────────────────────────────────────

    def _create_tags(self, users):
        self.stdout.write("Creating tags...")
        tags = {}  # {username: {tag_name: Tag}}
        for user in users.values():
            tags[user.username] = {}
            for name, color in TAG_DATA:
                tag, _ = Tag.objects.update_or_create(
                    user=user,
                    name=name,
                    defaults={"color": color},
                )
                tags[user.username][name] = tag
        return tags

    # ── Notebooks ──────────────────────────────────────────────────────────────

    def _create_notebooks(self, users):
        self.stdout.write("Creating notebooks...")
        notebooks = {}  # {username: [Notebook, ...]}
        for user in users.values():
            notebooks[user.username] = []
            first = True
            for title, color, is_default in NOTEBOOK_DATA:
                if is_default and first:
                    # Ensure only one default
                    Notebook.objects.filter(user=user, is_default=True).update(is_default=False)
                    first = False
                nb, _ = Notebook.objects.update_or_create(
                    user=user,
                    title=title,
                    defaults={"color": color, "is_default": is_default},
                )
                notebooks[user.username].append(nb)
        return notebooks

    # ── Notes ──────────────────────────────────────────────────────────────────

    def _create_notes(self, users, notebooks, tags, groups):
        self.stdout.write("Creating notes...")
        all_notes = {}  # {username: [Note, ...]}
        for user in users.values():
            all_notes[user.username] = []
            user_notebooks = notebooks[user.username]
            user_tags = tags[user.username]

            for idx, (title, content, priority, is_pinned, nb_idx, tag_names, group_slug) in enumerate(NOTE_DATA):
                nb = user_notebooks[nb_idx] if nb_idx < len(user_notebooks) else None
                group = groups.get(group_slug) if group_slug else None

                note, _ = Note.objects.update_or_create(
                    user=user,
                    title=title,
                    defaults={
                        "content": content,
                        "priority": priority,
                        "is_pinned": is_pinned,
                        "notebook": nb,
                        "group": group,
                    },
                )
                tag_objs = [user_tags[n] for n in tag_names if n in user_tags]
                note.tags.set(tag_objs)
                all_notes[user.username].append(note)

        return all_notes

    # ── Reminders ──────────────────────────────────────────────────────────────

    def _create_reminders(self, users, all_notes):
        self.stdout.write("Creating reminders...")
        now = timezone.now()
        for user in users.values():
            notes = all_notes[user.username]
            for note_idx, days, message, repeat in REMINDER_DATA:
                if note_idx >= len(notes):
                    continue
                note = notes[note_idx]
                remind_at = now + timedelta(days=days)
                Reminder.objects.update_or_create(
                    note=note,
                    message=message,
                    defaults={
                        "remind_at": remind_at,
                        "repeat_pattern": repeat,
                        "is_sent": False,
                    },
                )

    # ── Todo Lists ─────────────────────────────────────────────────────────────

    def _create_todo_lists(self, users):
        self.stdout.write("Creating todo lists...")
        user_list = list(users.values())

        for user in user_list:
            for title, description, item_texts, share_usernames in TODO_DATA:
                todo, _ = TodoList.objects.update_or_create(
                    user=user,
                    title=title,
                    defaults={"description": description, "is_completed": False},
                )
                # Add items (skip duplicates by text)
                existing_texts = set(todo.items.values_list("text", flat=True))
                for pos, text in enumerate(item_texts, start=1):
                    if text not in existing_texts:
                        TodoItem.objects.create(
                            todo_list=todo,
                            text=text,
                            order_position=pos,
                            is_done=False,
                        )
                # Mark first two items as done to show variety
                done_ids = list(todo.items.order_by("order_position").values_list("id", flat=True)[:2])
                TodoItem.objects.filter(id__in=done_ids).update(is_done=True)

                # Share with specified users
                for username in share_usernames:
                    if username in users:
                        todo.shared_with.add(users[username])

    # ── Shopping Lists ─────────────────────────────────────────────────────────

    def _create_shopping_lists(self, users, groups):
        self.stdout.write("Creating shopping lists...")
        for user in users.values():
            for title, store, items, group_slug in SHOPPING_DATA:
                group = groups.get(group_slug) if group_slug else None
                sl, _ = ShoppingList.objects.update_or_create(
                    user=user,
                    title=title,
                    defaults={"store_name": store, "group": group},
                )
                existing_names = set(sl.items.values_list("name", flat=True))
                for name, qty, unit, price in items:
                    if name not in existing_names:
                        ShopItem.objects.create(
                            shopping_list=sl,
                            name=name,
                            quantity=qty,
                            unit=unit,
                            estimated_price=price,
                            is_purchased=False,
                        )
                # Mark first item as purchased to show variety
                first_id = sl.items.order_by("id").values_list("id", flat=True).first()
                if first_id:
                    ShopItem.objects.filter(id=first_id).update(is_purchased=True)

    # ── Chat Messages ──────────────────────────────────────────────────────────

    def _create_chat_messages(self, users, groups):
        self.stdout.write("Creating chat messages...")
        base_time = timezone.now() - timedelta(hours=3)

        for group_slug, messages in CHAT_DATA.items():
            group = groups.get(group_slug)
            if group is None:
                continue
            # Clear existing demo messages for this group to stay idempotent
            ChatMessage.objects.filter(
                group=group,
                content__in=[text for _, text in messages],
            ).delete()

            for offset_minutes, (username, text) in enumerate(messages):
                author = users.get(username)
                if author is None:
                    continue
                msg_time = base_time + timedelta(minutes=offset_minutes * 4)
                ChatMessage.objects.create(
                    group=group,
                    author=author,
                    content=text,
                )
                # Update timestamp directly (auto_now_add prevents normal assignment)
                ChatMessage.objects.filter(
                    group=group, author=author, content=text
                ).order_by("-id").update(timestamp=msg_time)

    # ── Summary ────────────────────────────────────────────────────────────────

    def _summary(self, users, groups):
        user_qs = User.objects.filter(username__startswith=DEMO_USERNAME_PREFIX)
        return {
            "Users":          user_qs.count(),
            "Groups":         DjangoGroup.objects.filter(name__startswith=DEMO_GROUP_PREFIX).count(),
            "Tags":           Tag.objects.filter(user__in=user_qs).count(),
            "Notebooks":      Notebook.objects.filter(user__in=user_qs).count(),
            "Notes":          Note.objects.filter(user__in=user_qs).count(),
            "Reminders":      Reminder.objects.filter(note__user__in=user_qs).count(),
            "Todo lists":     TodoList.objects.filter(user__in=user_qs).count(),
            "Todo items":     TodoItem.objects.filter(todo_list__user__in=user_qs).count(),
            "Shopping lists": ShoppingList.objects.filter(user__in=user_qs).count(),
            "Shop items":     ShopItem.objects.filter(shopping_list__user__in=user_qs).count(),
            "Chat messages":  ChatMessage.objects.filter(group__in=groups.values()).count(),
        }
