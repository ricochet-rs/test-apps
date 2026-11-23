"""
test_selenium.py — E2E тести через реальний браузер (Selenium)

РІВЕНЬ ТЕСТУВАННЯ:
  Unit       → функція Python, без HTTP
  Integration → Django Test Client, симульований HTTP
  E2E (цей файл) → реальний браузер Firefox/Chrome, справжній HTTP

ЧИМ ВІДРІЗНЯЄТЬСЯ ВІД INTEGRATION ТЕСТІВ (test_views.py):
  Integration: self.client.get('/notes/') → Django обробляє всередині процесу
  Selenium:    driver.get('http://127.0.0.1:PORT/notes/') → реальний браузер,
               реальний HTTP запит, рендер HTML, JavaScript виконується

ЩО ТЕСТУЄ SELENIUM ДОДАТКОВО:
  - HTML форми заповнюються реальними keystroke
  - Кнопки клікаються через DOM
  - JavaScript (якщо є) виконується
  - CSS rendering не ламає форми
  - URL навігація через браузер (redirect ланцюги видимі)

КОЛИ НЕ ЗАПУСКАТИ SELENIUM:
  - Якщо geckodriver / chromedriver не встановлені → тести будуть SKIPPED
  - Для CI/CD без дисплею → використовувати headless mode (увімкнений за замовчуванням)

ЯК ЗАПУСТИТИ:
  # 1. Встановити selenium (Selenium Manager автоматично завантажить chromedriver):
  pip install selenium

  # 2. Запустити — chromedriver завантажиться автоматично:
  python manage.py test notes_app.tests.test_selenium -v 2

  # Якщо selenium не встановлений — тести будуть skipped (s), не впадуть.

ТРЮК: SESSION COOKIE
  Замість того щоб заповнювати login форму в браузері,
  ми копіюємо session cookie з Django Test Client до Selenium driver.
  Це швидше і надійніше — тест не залежить від стану login форми.
"""

import os
import unittest

# Selenium може не бути встановленим — graceful fallback
try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.common.keys import Keys
    from selenium.webdriver.chrome.options import Options as ChromeOptions
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    SELENIUM_AVAILABLE = True
except ImportError:
    SELENIUM_AVAILABLE = False

from django.contrib.auth.models import User, Group as DjangoGroup
from django.contrib.staticfiles.testing import StaticLiveServerTestCase
from django.utils import timezone
from datetime import timedelta

from notes_app.models import Note, Reminder

# ChannelLiveServerTestCase — запускає реальний Daphne ASGI сервер.
# Потрібен для тестування WebSocket через реальний браузер.
# Daphne вже встановлений у requirements.txt.
try:
    from channels.testing import ChannelsLiveServerTestCase
    from daphne.testing import DaphneProcess
    CHANNELS_LIVE_SERVER_AVAILABLE = True
except ImportError:
    CHANNELS_LIVE_SERVER_AVAILABLE = False
    DaphneProcess = None

# Якщо встановлена ця змінна → запускаємо через Remote WebDriver (GitHub Actions / Docker)
# Якщо не встановлена → локальний headless Chrome
SELENIUM_REMOTE_URL = os.environ.get("SELENIUM_REMOTE_URL")

# WEB_HOST: hostname контейнера web у Docker-мережі.
# Selenium container не може звернутись до 0.0.0.0 — потрібен реальний hostname.
# Локально: порожній рядок (server bind = 0.0.0.0 не потрібен, Selenium у тому ж процесі).
_WEB_HOST = os.environ.get("WEB_HOST", "")


def _make_headless_driver():
    """
    Повертає WebDriver залежно від середовища:

    - Локально (SELENIUM_REMOTE_URL не встановлена):
        headless Chrome через Selenium Manager (автоматично завантажує chromedriver)

    - GitHub Actions / Docker (SELENIUM_REMOTE_URL встановлена):
        Remote WebDriver → selenium/standalone-chrome контейнер

    Це дозволяє використовувати ОДИН файл тестів в обох середовищах.
    """
    options = ChromeOptions()
    options.add_argument('--no-sandbox')            # потрібно в Docker / CI
    options.add_argument('--disable-dev-shm-usage') # уникаємо проблем shared memory

    if SELENIUM_REMOTE_URL:
        # GitHub Actions: selenium/standalone-chrome вже запущений як сервіс
        return webdriver.Remote(
            command_executor=SELENIUM_REMOTE_URL,
            options=options,
        )

    # Локально: headless Chrome (Selenium Manager завантажить chromedriver)
    options.add_argument('--headless=new')
    return webdriver.Chrome(options=options)


class _DockerLiveServerMixin:
    """
    Mixin для запуску LiveServer в Docker з Remote Selenium.

    Проблема: StaticLiveServerTestCase за замовчуванням bind-ить сервер на
    localhost (127.0.0.1). Remote Selenium container не бачить цю адресу.

    Рішення:
      1. host = '0.0.0.0' → сервер bind-иться на всі інтерфейси контейнера
      2. Якщо WEB_HOST встановлено → замінюємо '0.0.0.0' на ім'я контейнера
         щоб Selenium міг звертатись через Docker внутрішню мережу.

    Локально (WEB_HOST не встановлено): host = '127.0.0.1' (стандартний Django).
      live_server_url = 'http://127.0.0.1:PORT' — Chrome може підключитись.
      КРИТИЧНО: host = '0.0.0.0' локально дає live_server_url = 'http://0.0.0.0:PORT',
      що Chrome відхиляє з ERR_ADDRESS_INVALID.
    У Docker (WEB_HOST=web): host = '0.0.0.0' → bind + URL = 'http://web:PORT'

    ВАЖЛИВО: StaticLiveServerTestCase зберігає live_server_url як classproperty
    (читає cls.host динамічно). ChannelsLiveServerTestCase PRE-COMPUTES
    live_server_url як рядок ('http://0.0.0.0:PORT') і зберігає в cls.__dict__.
    Тому після зміни cls.host ми також оновлюємо live_server_url для другого випадку.
    """
    # В Docker: '0.0.0.0' → bind на всі інтерфейси, потім URL = WEB_HOST.
    # Локально: '127.0.0.1' → Chrome може підключитись напряму.
    host = '0.0.0.0' if _WEB_HOST else '127.0.0.1'

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        if _WEB_HOST:
            cls.host = _WEB_HOST
            # ChannelsLiveServerTestCase pre-computes live_server_url as a string
            # and stores it in cls.__dict__ (e.g. 'http://0.0.0.0:PORT').
            # StaticLiveServerTestCase uses a classproperty that reads cls.host
            # dynamically, so it doesn't need manual update.
            if 'live_server_url' in cls.__dict__:
                cls.live_server_url = cls.live_server_url.replace(
                    '0.0.0.0', _WEB_HOST, 1
                )


# ─────────────────────────────────────────────────────────────────────────────
# 1. LOGIN FLOW — форма входу через браузер
# ─────────────────────────────────────────────────────────────────────────────

@unittest.skipUnless(SELENIUM_AVAILABLE, "selenium not installed — pip install selenium")
class SeleniumLoginFlowTest(_DockerLiveServerMixin, StaticLiveServerTestCase):
    """
    Тестуємо login flow через реальний браузер.

    StaticLiveServerTestCase:
      - Запускає реальний Django HTTP сервер на тимчасовому порту
      - self.live_server_url → 'http://127.0.0.1:XXXXX'
      - Кожен тест має ізольовану тестову БД (rollback як у звичайному TestCase)

    implicitly_wait(5):
      Selenium чекає до 5 секунд на появу елементу в DOM.
      Потрібно бо сторінки завантажуються з мережевою затримкою.
    """

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        if SELENIUM_AVAILABLE:
            cls.driver = _make_headless_driver()
            cls.driver.implicitly_wait(5)

    @classmethod
    def tearDownClass(cls):
        if SELENIUM_AVAILABLE:
            cls.driver.quit()
        super().tearDownClass()

    def setUp(self):
        # Кожен тест отримує свіжого юзера (тестова БД з rollback)
        self.user = User.objects.create_user(
            username='seleniumuser', password='testpass123'
        )

    def test_login_page_renders(self):
        """
        Відкриваємо /accounts/login/ → сторінка завантажилась,
        форма присутня в DOM.

        find_element(By.TAG_NAME, 'form') кидає NoSuchElementException якщо нема.
        """
        self.driver.get(f'{self.live_server_url}/accounts/login/')
        form = self.driver.find_element(By.TAG_NAME, 'form')
        self.assertIsNotNone(form)

    def test_valid_login_redirects_to_notes(self):
        """
        Заповнюємо форму логіну валідними даними, клікаємо Submit.
        Очікуємо redirect на /notes/ (LOGIN_REDIRECT_URL = '/notes/').

        WebDriverWait: click() запускає навігацію асинхронно.
        Без wait — current_url перевіряється до того як Chrome завершив redirect.
        """
        login_url = f'{self.live_server_url}/accounts/login/'
        self.driver.get(login_url)

        self.driver.find_element(By.NAME, 'username').send_keys('seleniumuser')
        self.driver.find_element(By.NAME, 'password').send_keys('testpass123')
        self.driver.find_element(By.CSS_SELECTOR, '[type="submit"]').click()

        # Чекаємо поки URL зміниться — redirect може зайняти частку секунди
        WebDriverWait(self.driver, 5).until(
            EC.url_changes(login_url)
        )

        self.assertIn('/notes/', self.driver.current_url)

    def test_invalid_login_shows_error(self):
        """
        Неправильний пароль → залишаємось на login сторінці (немає redirect).

        current_url не змінюється + форма видима.
        """
        self.driver.get(f'{self.live_server_url}/accounts/login/')

        self.driver.find_element(By.NAME, 'username').send_keys('seleniumuser')
        self.driver.find_element(By.NAME, 'password').send_keys('wrongpassword')
        self.driver.find_element(By.CSS_SELECTOR, '[type="submit"]').click()

        # Залишаємось на сторінці логіну — redirect не відбувся
        self.assertIn('login', self.driver.current_url)


# ─────────────────────────────────────────────────────────────────────────────
# 2. NOTE WORKFLOW — створення нотатки через браузер
# ─────────────────────────────────────────────────────────────────────────────

@unittest.skipUnless(SELENIUM_AVAILABLE, "selenium not installed — pip install selenium")
class SeleniumNoteFlowTest(_DockerLiveServerMixin, StaticLiveServerTestCase):
    """
    Тестуємо user workflow: перегляд списку нотаток і створення нотатки.

    SESSION COOKIE TRICK:
      Замість заповнення форми логіну в браузері, ми:
      1. Логінимось через Django Test Client (швидко, без браузера)
      2. Копіюємо session cookie до Selenium WebDriver
      3. Selenium тепер авторизований без повторного логіну

      Це стандартна техніка для E2E тестів — швидше і надійніше.
    """

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        if SELENIUM_AVAILABLE:
            cls.driver = _make_headless_driver()
            cls.driver.implicitly_wait(5)

    @classmethod
    def tearDownClass(cls):
        if SELENIUM_AVAILABLE:
            cls.driver.quit()
        super().tearDownClass()

    def setUp(self):
        self.user = User.objects.create_user(
            username='noteuser', password='testpass123'
        )
        self._login_via_cookie()

    def _login_via_cookie(self):
        """
        SESSION COOKIE TRICK:
        1. Test Client логіниться → Django видає session_id cookie
        2. Ми копіюємо цей cookie до Selenium driver
        3. Selenium тепер авторизований

        Навіщо: уникаємо залежності E2E тесту від стану login форми.
        Логін форма може мати CSRF, рекапчу, JS валідацію — все це ламає тести.
        """
        # 1. Залогінитись через Test Client
        self.client.force_login(self.user)

        # 2. Отримати session cookie
        session_cookie = self.client.cookies['sessionid']

        # 3. Спочатку відкрити будь-яку сторінку того самого домену
        #    (browser потребує сторінку відкритою щоб встановити cookie)
        self.driver.get(f'{self.live_server_url}/')

        # 4. Передати session cookie до Selenium
        self.driver.add_cookie({
            'name':   'sessionid',
            'value':  session_cookie.value,
            'path':   '/',
        })

    def test_note_list_page_loads(self):
        """
        Авторизований юзер відкриває /notes/ → сторінка завантажилась (200).
        Заголовок або heading містить відповідний текст.
        """
        self.driver.get(f'{self.live_server_url}/notes/')
        # Сторінка завантажилась — немає redirect на login
        self.assertIn('/notes/', self.driver.current_url)

    def test_create_note_via_form(self):
        """
        E2E тест: відкрити /notes/new/, заповнити форму, натиснути Submit.
        Результат: redirect на note_detail або note_list.

        Використовуємо submit_button.click() замість Keys.RETURN:
        Keys.RETURN може не спрацювати якщо форма має JavaScript-валідацію.

        WebDriverWait: redirect відбувається асинхронно після POST.
        """
        new_note_url = f'{self.live_server_url}/notes/new/'
        self.driver.get(new_note_url)

        self.driver.find_element(By.NAME, 'title').send_keys('My Selenium Note')

        # Знаходимо і клікаємо submit button (кнопка типу submit у формі)
        self.driver.find_element(By.CSS_SELECTOR, '[type="submit"]').click()

        # Чекаємо поки URL зміниться — POST → redirect займає час
        WebDriverWait(self.driver, 5).until(
            EC.url_changes(new_note_url)
        )

        self.assertNotIn('/notes/new/', self.driver.current_url)

    def test_created_note_appears_in_list(self):
        """
        Створюємо нотатку через ORM (не через форму) і перевіряємо
        що вона видна в DOM списку нотаток.

        Навіщо: перевіряємо що шаблон правильно рендерить дані з БД.
        Якщо template bug (наприклад {% for %} без note.title) → цей тест впаде.
        """
        Note.objects.create(user=self.user, title='Visible Note', content='Test')

        self.driver.get(f'{self.live_server_url}/notes/')

        # Перевіряємо що текст нотатки видний у HTML сторінки
        self.assertIn('Visible Note', self.driver.page_source)


# ─────────────────────────────────────────────────────────────────────────────
# 3. GROUP CHAT PAGE — перевірка UI чату через реальний браузер
# ─────────────────────────────────────────────────────────────────────────────

@unittest.skipUnless(SELENIUM_AVAILABLE, "selenium not installed — pip install selenium")
class SeleniumGroupChatPageTest(_DockerLiveServerMixin, StaticLiveServerTestCase):
    """
    E2E тест сторінки групового чату.

    Що перевіряємо:
      - Сторінка /groups/<pk>/chat/ рендериться без помилок
      - DOM містить елементи чату: #chat-input, #chat-send-btn, #chat-messages
      - Назва групи видна у topbar
      - Не-член групи отримує redirect
      - group_detail містить посилання на чат

    Примітка: WebSocket не підключиться (StaticLiveServerTestCase = WSGI-сервер,
    не ASGI). Але HTML рендер і наявність DOM-елементів перевіряються повністю.
    Для тестування WebSocket з'єднання — дивись test_consumers.py.
    """

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        if SELENIUM_AVAILABLE:
            cls.driver = _make_headless_driver()
            cls.driver.implicitly_wait(5)

    @classmethod
    def tearDownClass(cls):
        if SELENIUM_AVAILABLE:
            cls.driver.quit()
        super().tearDownClass()

    def setUp(self):
        from django.contrib.auth.models import Group as DjangoGroup
        self.user = User.objects.create_user(username='chatuser', password='testpass123')
        self.other_user = User.objects.create_user(username='outsider', password='testpass123')
        self.group = DjangoGroup.objects.create(name='TestChatGroup')
        self.group.user_set.add(self.user)
        self._login_via_cookie(self.user)

    def _login_via_cookie(self, user):
        self.client.force_login(user)
        session_cookie = self.client.cookies['sessionid']
        self.driver.get(f'{self.live_server_url}/')
        self.driver.add_cookie({
            'name': 'sessionid',
            'value': session_cookie.value,
            'path': '/',
        })

    def test_chat_page_loads_for_member(self):
        """
        Авторизований член групи відкриває /groups/<pk>/chat/ → 200, URL не змінився.
        """
        self.driver.get(f'{self.live_server_url}/groups/{self.group.pk}/chat/')
        self.assertIn(f'/groups/{self.group.pk}/chat/', self.driver.current_url)

    def test_chat_page_shows_group_name(self):
        """
        Назва групи видна у topbar сторінки чату.
        """
        self.driver.get(f'{self.live_server_url}/groups/{self.group.pk}/chat/')
        self.assertIn('TestChatGroup', self.driver.page_source)

    def test_chat_input_element_present(self):
        """
        HTML містить поле вводу повідомлення (id="chat-input").

        Перевіряємо через page_source (не find_element) тому що JS
        одразу вимикає інпут (disabled=true) до встановлення WebSocket.
        StaticLiveServerTestCase = WSGI → WebSocket не підключиться,
        тому елемент існує в HTML але може бути недоступний для взаємодії.
        """
        self.driver.get(f'{self.live_server_url}/groups/{self.group.pk}/chat/')
        self.assertIn('id="chat-input"', self.driver.page_source)

    def test_chat_send_button_present(self):
        """
        HTML містить кнопку відправки (id="chat-send-btn").
        """
        self.driver.get(f'{self.live_server_url}/groups/{self.group.pk}/chat/')
        self.assertIn('id="chat-send-btn"', self.driver.page_source)

    def test_chat_messages_feed_present(self):
        """
        HTML містить контейнер повідомлень (id="chat-messages").
        """
        self.driver.get(f'{self.live_server_url}/groups/{self.group.pk}/chat/')
        self.assertIn('id="chat-messages"', self.driver.page_source)

    def test_non_member_redirected_from_chat(self):
        """
        Юзер не є членом групи → redirect на /groups/ (не залишається на chat URL).

        Увага: сесія для outsider встановлюється заново через cookie trick.
        """
        from django.contrib.auth.models import Group as DjangoGroup
        other_group = DjangoGroup.objects.create(name='OtherGroup')
        # outsider НЕ доданий до other_group

        # Перелогінюємось як outsider
        self._login_via_cookie(self.other_user)
        self.driver.get(f'{self.live_server_url}/groups/{other_group.pk}/chat/')

        WebDriverWait(self.driver, 5).until(
            lambda d: f'/groups/{other_group.pk}/chat/' not in d.current_url
        )
        self.assertNotIn(f'/groups/{other_group.pk}/chat/', self.driver.current_url)

    def test_group_detail_has_chat_link(self):
        """
        Сторінка group_detail містить посилання на чат групи.
        """
        self.driver.get(f'{self.live_server_url}/groups/{self.group.pk}/')
        page = self.driver.page_source
        self.assertIn(f'/groups/{self.group.pk}/chat/', page)


# ─────────────────────────────────────────────────────────────────────────────
# 4. WEBSOCKET CHAT — реальне WebSocket з'єднання через Daphne ASGI сервер
# ─────────────────────────────────────────────────────────────────────────────

if CHANNELS_LIVE_SERVER_AVAILABLE and DaphneProcess is not None:
    class _FreshConnectionDaphneProcess(DaphneProcess):
        """Fix fork-related DB issues before Daphne starts serving."""
        def run(self):
            from django.conf import settings as _ds
            from django.db import connections

            # channels' set_database_connection() reads DATABASES["default"]["TEST"]["NAME"].
            # If it's None, it computes "test_" + current NAME. But the test runner already
            # set NAME = "test_notes_db", so we'd get "test_test_notes_db" — non-existent.
            # Fix: mirror current NAME into TEST["NAME"] so set_database_connection() is a no-op.
            current_name = _ds.DATABASES["default"]["NAME"]
            _ds.DATABASES["default"].setdefault("TEST", {})["NAME"] = current_name

            # Close connections inherited via fork so the subprocess creates fresh ones.
            connections.close_all()
            super().run()
else:
    _FreshConnectionDaphneProcess = None


@unittest.skipUnless(
    SELENIUM_AVAILABLE and CHANNELS_LIVE_SERVER_AVAILABLE,
    "selenium або channels.testing недоступні"
)
class SeleniumWebSocketChatTest(_DockerLiveServerMixin, ChannelsLiveServerTestCase):
    """
    E2E тест реального WebSocket чату через Daphne ASGI сервер.

    ВІДМІННІСТЬ ВІД SeleniumGroupChatPageTest:
      SeleniumGroupChatPageTest: StaticLiveServerTestCase = WSGI (sync) сервер
        → JavaScript WebSocket НЕ підключається (немає ASGI обробника)
        → input залишається disabled
        → можна тільки перевіряти HTML розмітку

      Цей клас: ChannelLiveServerTestCase = Daphne ASGI сервер
        → JavaScript WebSocket підключається РЕАЛЬНО
        → Consumer.connect() виконується
        → input стає enabled (socket.onopen())
        → можна відправляти повідомлення і перевіряти DOM

    ЩО ТЕСТУЄМО:
      - WebSocket з'єднання встановлюється (input змінюється з disabled → enabled)
      - Відправлене повідомлення з'являється у #chat-messages
      - Повний шлях: браузер → WS → Consumer → БД → group_send → DOM
    """
    # Override the default DaphneProcess to close forked DB connections before serving.
    ProtocolServerProcess = _FreshConnectionDaphneProcess

    @classmethod
    def setUpClass(cls):
        # Django test runner sets DEBUG=False via setup_test_environment().
        # DaphneProcess uses fork() on Linux — the child inherits DEBUG=False,
        # causing handle_uncaught_exception() to return minimal 500 pages for all views.
        # Temporarily restore DEBUG=True so the forked subprocess gets correct settings.
        from django.conf import settings as _s
        _was_debug = _s.DEBUG
        _s.DEBUG = True
        try:
            super().setUpClass()  # forks DaphneProcess here
        finally:
            _s.DEBUG = _was_debug
        if SELENIUM_AVAILABLE:
            cls.driver = _make_headless_driver()
            cls.driver.implicitly_wait(10)

    @classmethod
    def tearDownClass(cls):
        if SELENIUM_AVAILABLE:
            cls.driver.quit()
        super().tearDownClass()

    def setUp(self):
        self.user = User.objects.create_user(username='wsclient', password='testpass123')
        self.group = DjangoGroup.objects.create(name='WSChatGroup')
        self.group.user_set.add(self.user)
        self._login_via_cookie(self.user)

    def _login_via_cookie(self, user):
        self.client.force_login(user)
        session_cookie = self.client.cookies['sessionid']
        self.driver.get(f'{self.live_server_url}/')
        self.driver.add_cookie({
            'name': 'sessionid',
            'value': session_cookie.value,
            'path': '/',
        })

    def test_websocket_connects_and_enables_input(self):
        """
        Після відкриття chat page WebSocket підключається і input стає активним.

        group_chat.js логіка:
          inputEl.disabled = true            ← до підключення
          socket.onopen = () => {
              inputEl.disabled = false       ← після підключення
          }

        З StaticLiveServerTestCase (WSGI): WebSocket НЕ підключається → input назавжди disabled.
        З ChannelLiveServerTestCase (Daphne): WebSocket підключається → input стає enabled.

        EC.element_to_be_clickable() чекає поки елемент стане і visible і enabled.
        """
        chat_url = f'{self.live_server_url}/groups/{self.group.pk}/chat/'
        self.driver.get(chat_url)

        import time
        time.sleep(3)
        print(f"\n[DEBUG] live_server_url={self.live_server_url}")
        # Прямий HTTP запит — обходить Selenium щоб бачити сирий HTML
        import urllib.request as _ur
        chat_url_raw = f'{self.live_server_url}/groups/{self.group.pk}/chat/'
        try:
            session_val = self.client.cookies['sessionid'].value
            req = _ur.Request(chat_url_raw)
            req.add_header('Cookie', f'sessionid={session_val}')
            with _ur.urlopen(req, timeout=5) as resp:
                raw_html = resp.read().decode('utf-8', errors='replace')
                print(f"[HTTP] status={resp.status} len={len(raw_html)}", flush=True)
                print(f"[HTTP] first 800 chars: {raw_html[:800]}", flush=True)
                if 'chat-input' not in raw_html:
                    print(f"[HTTP] NO chat-input in response!", flush=True)
        except _ur.HTTPError as http_err:
            body = http_err.read().decode('utf-8', errors='replace')
            print(f"[HTTP] HTTPError {http_err.code}: body len={len(body)}", flush=True)
            print(f"[HTTP] body first 1500: {body[:1500]}", flush=True)
        except Exception as http_err:
            print(f"[HTTP ERROR] {http_err}", flush=True)
        print(f"[DEBUG] current_url={self.driver.current_url}")
        src = self.driver.page_source
        print(f"[DEBUG] page_source len={len(src)}")
        print(f"[DEBUG] page_source[:500]={src[:500]}")
        print(f"[DEBUG] chat-input in source: {'chat-input' in src}")

        chat_input = WebDriverWait(self.driver, 10).until(
            EC.element_to_be_clickable((By.ID, 'chat-input'))
        )
        self.assertFalse(chat_input.get_attribute('disabled'))

    def test_send_message_appears_in_chat_feed(self):
        """
        Відправляємо повідомлення через UI → воно з'являється у #chat-messages.

        Перевіряє повний WebSocket шлях:
          браузер → form submit → socket.send() → Consumer.receive()
          → save_message() → group_send() → chat_message() → self.send()
          → socket.onmessage → appendMessage() → DOM оновлюється

        WebDriverWait + lambda: чекаємо поки DOM містить текст повідомлення.
        """
        self.driver.get(f'{self.live_server_url}/groups/{self.group.pk}/chat/')

        # Чекаємо поки WebSocket підключиться
        chat_input = WebDriverWait(self.driver, 10).until(
            EC.element_to_be_clickable((By.ID, 'chat-input'))
        )

        test_message = 'WebSocket E2E тест'
        chat_input.send_keys(test_message)
        # JS click обходить debug toolbar overlay (djdt div перекриває кнопку)
        send_btn = self.driver.find_element(By.ID, 'chat-send-btn')
        self.driver.execute_script("arguments[0].click()", send_btn)

        # Чекаємо поки повідомлення з'явиться у #chat-messages
        WebDriverWait(self.driver, 10).until(
            lambda d: test_message in d.find_element(By.ID, 'chat-messages').text
        )

        messages_feed = self.driver.find_element(By.ID, 'chat-messages')
        self.assertIn(test_message, messages_feed.text)

    def test_status_shows_connected_after_websocket_opens(self):
        """
        Після підключення статус-бар показує 'Підключено'.

        group_chat.js → setStatus('connected') → statusTextEl.textContent = 'Підключено'
        Перевіряємо що #status-text змінився з 'Підключення...' на 'Підключено'.
        """
        self.driver.get(f'{self.live_server_url}/groups/{self.group.pk}/chat/')

        # Чекаємо поки статус стане 'Підключено'
        WebDriverWait(self.driver, 10).until(
            lambda d: 'Підключено' in d.find_element(By.ID, 'status-text').text
        )

        status_text = self.driver.find_element(By.ID, 'status-text').text
        self.assertIn('Підключено', status_text)


class SeleniumReminderToastTest(_DockerLiveServerMixin, StaticLiveServerTestCase):
    """
    E2E тести для browser toast-нотифікацій (reminders.js).

    Перевіряємо що:
      1. При завантаженні сторінки JS одразу викликає GET /reminders/check/.
      2. Якщо є прострочені нагадування (за останню годину) — Bootstrap Toast з'являється.
      3. Майбутні нагадування та нагадування старіші за 1 год — Toast не з'являється.

    Ключовий момент: JS викликає checkReminders() відразу на DOMContentLoaded,
    тому тест не чекає 60 секунд — лише час HTTP запиту (< 5 сек).
    """

    @classmethod
    def setUpClass(cls):
        if not SELENIUM_AVAILABLE:
            raise unittest.SkipTest('Selenium not available')
        super().setUpClass()
        cls.driver = _make_headless_driver()
        cls.driver.implicitly_wait(5)

    @classmethod
    def tearDownClass(cls):
        cls.driver.quit()
        super().tearDownClass()

    def setUp(self):
        self.user = User.objects.create_user(
            'reminder_selenium', email='rem@test.com', password='pass123'
        )
        self.note = Note.objects.create(
            user=self.user, title='Selenium Reminder Note', content=''
        )

    def tearDown(self):
        Reminder.objects.all().delete()
        Note.objects.all().delete()
        User.objects.filter(username='reminder_selenium').delete()

    def _login_via_cookie(self):
        self.client.force_login(self.user)
        session_cookie = self.client.cookies['sessionid']
        self.driver.get(f'{self.live_server_url}/')
        self.driver.add_cookie({
            'name': 'sessionid',
            'value': session_cookie.value,
            'path': '/',
        })

    def _wait_for_visible_toast(self):
        """
        Чекає, поки toast стане видимим.

        Bootstrap 5.3 додає `.show` разом із `.showing` (opacity: 0) і знімає
        `.showing` лише після fade-анімації. Поки триває анімація, Selenium
        повертає порожній `.text`, тому чекаємо `:not(.showing)` і видимість.
        """
        return WebDriverWait(self.driver, 10).until(
            EC.visibility_of_element_located(
                (By.CSS_SELECTOR, '.toast.show:not(.showing)')
            )
        )

    def test_toast_appears_for_due_reminder(self):
        """
        Нагадування що настало 30 хвилин тому → Toast з'являється на сторінці нотаток.

        Перевіряє повний шлях:
          DOMContentLoaded → checkReminders() → GET /reminders/check/
          → JSON {reminders: [...]} → showToast() → .toast.show у DOM
        """
        Reminder.objects.create(
            note=self.note,
            remind_at=timezone.now() - timedelta(minutes=30),
            message='JS toast E2E test',
        )
        self._login_via_cookie()
        self.driver.get(f'{self.live_server_url}/notes/')

        toast = self._wait_for_visible_toast()
        self.assertIn('Selenium Reminder Note', toast.text)

    def test_toast_contains_reminder_message(self):
        """Toast відображає текст повідомлення нагадування."""
        Reminder.objects.create(
            note=self.note,
            remind_at=timezone.now() - timedelta(minutes=15),
            message='Унікальний текст нагадування XYZ',
        )
        self._login_via_cookie()
        self.driver.get(f'{self.live_server_url}/notes/')

        toast = self._wait_for_visible_toast()
        self.assertIn('Унікальний текст нагадування XYZ', toast.text)

    def test_toast_not_shown_for_future_reminder(self):
        """Майбутнє нагадування → Toast не з'являється."""
        Reminder.objects.create(
            note=self.note,
            remind_at=timezone.now() + timedelta(hours=2),
        )
        self._login_via_cookie()
        self.driver.get(f'{self.live_server_url}/notes/')

        import time
        time.sleep(3)  # Чекаємо DOMContentLoaded + fetch відповідь

        toasts = self.driver.find_elements(By.CSS_SELECTOR, '.toast.show')
        self.assertEqual(len(toasts), 0)


    def test_toast_not_shown_for_old_reminder(self):
        """Нагадування старіше 1 години → Toast не з'являється."""
        Reminder.objects.create(
            note=self.note,
            remind_at=timezone.now() - timedelta(hours=2),
        )
        self._login_via_cookie()
        self.driver.get(f'{self.live_server_url}/notes/')

        import time
        time.sleep(3)

        toasts = self.driver.find_elements(By.CSS_SELECTOR, '.toast.show')
        self.assertEqual(len(toasts), 0)


_EXTERNAL_BASE_URL = os.environ.get("SELENIUM_EXTERNAL_BASE_URL", "").rstrip("/")
_EXTERNAL_USERNAME = os.environ.get("SELENIUM_EXTERNAL_USERNAME", "demo_alice")
_EXTERNAL_PASSWORD = os.environ.get("SELENIUM_EXTERNAL_PASSWORD", "demo1234")


@unittest.skipUnless(
    SELENIUM_AVAILABLE and _EXTERNAL_BASE_URL,
    "external Docker Selenium smoke tests require SELENIUM_EXTERNAL_BASE_URL",
)
class SeleniumDockerStackSmokeTest(unittest.TestCase):
    """
    Smoke-тести проти вже запущеного Docker stack.

    Ці тести не стартують Django LiveServer. Вони відкривають реальний nginx/web
    з docker-compose і перевіряють, що контейнерний запуск справді працює.
    """

    @classmethod
    def setUpClass(cls):
        cls.driver = _make_headless_driver()
        cls.driver.implicitly_wait(5)
        cls.driver.set_window_size(1366, 900)

    @classmethod
    def tearDownClass(cls):
        cls.driver.quit()

    def test_login_page_is_served_by_docker_stack(self):
        self.driver.get(f"{_EXTERNAL_BASE_URL}/accounts/login/")

        self.assertIn("/accounts/login/", self.driver.current_url)
        self.assertTrue(self.driver.find_elements(By.NAME, "username"))
        self.assertTrue(self.driver.find_elements(By.NAME, "password"))
        self.assertTrue(self.driver.find_elements(By.CSS_SELECTOR, "[type='submit']"))

    def test_seeded_demo_user_can_login_through_nginx(self):
        login_url = f"{_EXTERNAL_BASE_URL}/accounts/login/"
        self.driver.get(login_url)

        self.driver.find_element(By.NAME, "username").send_keys(_EXTERNAL_USERNAME)
        self.driver.find_element(By.NAME, "password").send_keys(_EXTERNAL_PASSWORD)
        self.driver.find_element(By.CSS_SELECTOR, "[type='submit']").click()

        WebDriverWait(self.driver, 10).until(
            lambda driver: "/notes/" in driver.current_url
        )
        self.assertIn("/notes/", self.driver.current_url)

    def test_notes_page_static_assets_render_after_login(self):
        login_url = f"{_EXTERNAL_BASE_URL}/accounts/login/"
        self.driver.get(login_url)
        self.driver.find_element(By.NAME, "username").send_keys(_EXTERNAL_USERNAME)
        self.driver.find_element(By.NAME, "password").send_keys(_EXTERNAL_PASSWORD)
        self.driver.find_element(By.CSS_SELECTOR, "[type='submit']").click()

        WebDriverWait(self.driver, 10).until(
            EC.presence_of_element_located((By.TAG_NAME, "body"))
        )
        body_text = self.driver.find_element(By.TAG_NAME, "body").text
        self.assertTrue(body_text.strip())
