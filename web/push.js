'use strict';

// Browser side of Daily Quest reminders. Flutter calls these through
// dart:js_interop (see lib/services/reminder_service_web.dart). Every
// function takes and returns JSON strings so the interop stays trivial.
//
// The push service worker lives at scope /push/, separate from Flutter's own
// service worker, which unregisters itself and would otherwise replace ours.
(function () {
  const SW_URL = '/push_sw.js';
  const SW_SCOPE = '/push/';

  function urlBase64ToUint8Array(base64) {
    const padding = '='.repeat((4 - (base64.length % 4)) % 4);
    const raw = atob((base64 + padding).replace(/-/g, '+').replace(/_/g, '/'));
    return Uint8Array.from(raw, (c) => c.charCodeAt(0));
  }

  const isIos = () => /iP(hone|ad|od)/.test(navigator.userAgent);
  const isStandalone = () =>
    window.matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;

  async function registration() {
    const existing = await navigator.serviceWorker.getRegistration(SW_SCOPE);
    if (existing) return existing;
    return navigator.serviceWorker.register(SW_URL, { scope: SW_SCOPE });
  }

  async function api(apiUrl, method, path, body) {
    const res = await fetch(apiUrl + path, {
      method,
      headers: { 'content-type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`${method} ${path} -> ${res.status}`);
    return res.json();
  }

  const timezone = () => Intl.DateTimeFormat().resolvedOptions().timeZone;

  /**
   * What this browser can do right now.
   *   unsupported  no service worker or push API
   *   needsInstall iOS, but not running from the home screen
   *   denied       permission refused earlier; the browser won't ask again
   *   off          nothing subscribed
   *   on           subscribed
   */
  async function support() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) {
      return { status: 'unsupported' };
    }
    if (isIos() && !isStandalone()) return { status: 'needsInstall' };
    if (Notification.permission === 'denied') return { status: 'denied' };
    const reg = await navigator.serviceWorker.getRegistration(SW_SCOPE);
    const sub = reg && (await reg.pushManager.getSubscription());
    return { status: sub ? 'on' : 'off' };
  }

  /** Must be called from a user gesture (permission prompt). */
  async function enable(apiUrl, settings) {
    const permission = await Notification.requestPermission();
    if (permission !== 'granted') return { status: permission === 'denied' ? 'denied' : 'off' };
    const reg = await registration();
    let sub = await reg.pushManager.getSubscription();
    if (!sub) {
      const { publicKey } = await api(apiUrl, 'GET', '/vapid');
      sub = await reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(publicKey),
      });
    }
    await api(apiUrl, 'PUT', '/subscriptions', {
      subscription: sub.toJSON(),
      timezone: timezone(),
      times: settings.times,
    });
    return { status: 'on' };
  }

  /** Re-sends the current subscription and times; a no-op when not subscribed. */
  async function sync(apiUrl, settings) {
    const reg = await navigator.serviceWorker.getRegistration(SW_SCOPE);
    const sub = reg && (await reg.pushManager.getSubscription());
    if (!sub) return { status: 'off' };
    await api(apiUrl, 'PUT', '/subscriptions', {
      subscription: sub.toJSON(),
      timezone: timezone(),
      times: settings.times,
    });
    return { status: 'on' };
  }

  async function disable(apiUrl) {
    const reg = await navigator.serviceWorker.getRegistration(SW_SCOPE);
    const sub = reg && (await reg.pushManager.getSubscription());
    if (sub) {
      try {
        await api(apiUrl, 'DELETE', '/subscriptions', { endpoint: sub.endpoint });
      } finally {
        await sub.unsubscribe();
      }
    }
    return { status: 'off' };
  }

  /** Tells the server today's quest is done so later reminders are skipped. */
  async function complete(apiUrl, date) {
    const reg = await navigator.serviceWorker.getRegistration(SW_SCOPE);
    const sub = reg && (await reg.pushManager.getSubscription());
    if (!sub) return { status: 'off' };
    await api(apiUrl, 'POST', '/subscriptions/complete', { endpoint: sub.endpoint, date });
    return { status: 'on' };
  }

  // JSON-string boundary for Dart.
  const wrap = (fn) => async (...args) => JSON.stringify(await fn(...args.map((a) => (typeof a === 'string' && a.startsWith('{') ? JSON.parse(a) : a))));
  window.dqPush = {
    support: wrap(support),
    enable: wrap(enable),
    sync: wrap(sync),
    disable: wrap(disable),
    complete: wrap(complete),
  };
})();
