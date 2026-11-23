/**
 * reminders.js — browser toast-нотифікації для Reminder.
 *
 * Механізм:
 *   1. На DOMContentLoaded: відразу викликає checkReminders().
 *   2. Потім кожні POLL_INTERVAL мс повторює запит.
 *   3. GET /reminders/check/ повертає JSON з нагадуваннями за останню годину.
 *   4. Для кожного нового (не показаного в цій сесії) — Bootstrap Toast.
 *   5. sessionStorage запобігає повторному показу тосту під час сесії.
 *
 * Не потребує WebSocket — простий HTTP polling достатній для нагадувань.
 */
(function () {
  'use strict';

  var POLL_INTERVAL = 60_000;          // кожну хвилину
  var STORAGE_KEY   = 'shown_reminders';
  var CHECK_URL     = (window.SCRIPT_NAME || '') + '/reminders/check/';

  function getShownIds() {
    try {
      return new Set(JSON.parse(sessionStorage.getItem(STORAGE_KEY) || '[]'));
    } catch (_) {
      return new Set();
    }
  }

  function markShown(id) {
    var s = getShownIds();
    s.add(id);
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(Array.from(s)));
  }

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function showToast(reminder) {
    var container = document.getElementById('reminder-toast-container');
    if (!container) return;

    var toastEl = document.createElement('div');
    toastEl.className = 'toast align-items-center border-0';
    toastEl.setAttribute('role', 'alert');
    toastEl.setAttribute('aria-live', 'assertive');
    toastEl.setAttribute('aria-atomic', 'true');
    toastEl.style.cssText = 'background: #fff3cd; color: #664d03;';

    var body = '<div class="d-flex">'
      + '<div class="toast-body">'
      + '<strong>🔔 Нагадування</strong><br>'
      + '<span>' + escapeHtml(reminder.note__title) + '</span><br>';

    if (reminder.message) {
      body += '<small>' + escapeHtml(reminder.message) + '</small><br>';
    }

    body += '<small class="text-muted">' + escapeHtml(reminder.remind_at) + '</small>'
      + '</div>'
      + '<button type="button" class="btn-close me-2 m-auto"'
      + ' data-bs-dismiss="toast" aria-label="Закрити"></button>'
      + '</div>';

    toastEl.innerHTML = body;
    container.appendChild(toastEl);

    var toast = new bootstrap.Toast(toastEl, { delay: 8000, autohide: true });
    toast.show();

    toastEl.addEventListener('hidden.bs.toast', function () {
      toastEl.remove();
    });
  }

  async function checkReminders() {
    try {
      var resp = await fetch(CHECK_URL, {
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        credentials: 'same-origin'
      });
      if (!resp.ok) return;

      var data = await resp.json();
      var shown = getShownIds();

      (data.reminders || []).forEach(function (r) {
        if (!shown.has(r.id)) {
          showToast(r);
          markShown(r.id);
        }
      });
    } catch (_) {
      // тихий fail — мережа недоступна або сервер не відповідає
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    // Запускаємо лише якщо toast-container присутній у DOM
    // (base.html додає його лише для автентифікованих)
    if (!document.getElementById('reminder-toast-container')) return;

    checkReminders();
    setInterval(checkReminders, POLL_INTERVAL);
  });
})();
