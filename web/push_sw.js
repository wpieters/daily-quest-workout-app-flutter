'use strict';

// Push service worker for Daily Quest reminders. Registered by push.js at
// scope /push/ so Flutter's own (self-unregistering) service worker never
// replaces it. It doesn't control the page; it only receives pushes.

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = { body: event.data && event.data.text() };
  }
  const title = payload.title || '[Daily Quest]';
  const options = {
    body: payload.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    // One notification per slot; a newer one replaces an unread older one.
    tag: 'dailyquest-' + (payload.slot || 'reminder'),
    renotify: true,
    data: { url: payload.url || '/' },
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = new URL((event.notification.data && event.notification.data.url) || '/', self.location.origin).href;
  event.waitUntil(
    self.clients
      // This worker controls nothing, so ask for uncontrolled windows too.
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clients) => {
        const open = clients.find((c) => c.url.startsWith(self.location.origin));
        if (open) return open.focus();
        return self.clients.openWindow(url);
      }),
  );
});
