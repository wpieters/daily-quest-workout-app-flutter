// Public HTTP API behind a Lambda Function URL. CORS is enforced by the URL
// config; this handler only validates and stores.
//
//   GET    /vapid                  -> { publicKey }
//   PUT    /subscriptions          { subscription, timezone, times }
//   POST   /subscriptions/complete { endpoint, date }
//   DELETE /subscriptions          { endpoint }
import {
  deleteSubscription,
  idFor,
  markCompleted,
  putSubscription,
} from './store.mjs';
import { vapidKeys } from './vapid.mjs';

export const SLOTS = ['morning', 'afternoon', 'evening'];

// Browsers' push services. Anything else is refused so the public endpoint
// can't be used to store arbitrary URLs.
const PUSH_HOSTS = [
  'fcm.googleapis.com',
  'web.push.apple.com',
  'updates.push.services.mozilla.com',
  '.notify.windows.com',
];

const MAX_BODY_BYTES = 4096;
const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;
const DATE_RE = /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/;

class BadRequest extends Error {
  constructor(message) {
    super(message);
    this.statusCode = 400;
  }
}

export function isPushEndpoint(endpoint) {
  let url;
  try {
    url = new URL(endpoint);
  } catch {
    return false;
  }
  if (url.protocol !== 'https:') return false;
  return PUSH_HOSTS.some((h) =>
    h.startsWith('.') ? url.hostname.endsWith(h) : url.hostname === h,
  );
}

export function isTimezone(tz) {
  if (typeof tz !== 'string' || !tz) return false;
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

/** Validates the PUT body and returns the item fields to store. */
export function parseSubscription(body) {
  const sub = body?.subscription;
  if (!sub || !isPushEndpoint(sub.endpoint)) {
    throw new BadRequest('subscription.endpoint must be a push service URL');
  }
  const { p256dh, auth } = sub.keys ?? {};
  if (typeof p256dh !== 'string' || typeof auth !== 'string') {
    throw new BadRequest('subscription.keys.p256dh and .auth are required');
  }
  if (!isTimezone(body.timezone)) {
    throw new BadRequest('timezone must be a valid IANA zone');
  }
  const times = {};
  for (const slot of SLOTS) {
    const t = body.times?.[slot] ?? null;
    if (t !== null && !(typeof t === 'string' && TIME_RE.test(t))) {
      throw new BadRequest(`times.${slot} must be "HH:MM" or null`);
    }
    times[slot] = t;
  }
  if (SLOTS.every((s) => times[s] === null)) {
    throw new BadRequest('at least one reminder time is required');
  }
  return {
    endpoint: sub.endpoint,
    keys: { p256dh, auth },
    timezone: body.timezone,
    times,
  };
}

function parseBody(event) {
  if (!event.body) return {};
  const raw = event.isBase64Encoded
    ? Buffer.from(event.body, 'base64').toString('utf8')
    : event.body;
  if (Buffer.byteLength(raw) > MAX_BODY_BYTES) {
    throw new BadRequest('body too large');
  }
  try {
    return JSON.parse(raw);
  } catch {
    throw new BadRequest('body must be JSON');
  }
}

const json = (statusCode, body) => ({
  statusCode,
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(body),
});

async function route(method, path, body) {
  if (method === 'GET' && path === '/vapid') {
    const { publicKey } = await vapidKeys();
    return json(200, { publicKey });
  }
  if (method === 'PUT' && path === '/subscriptions') {
    const item = parseSubscription(body);
    await putSubscription(item);
    return json(200, { id: idFor(item.endpoint) });
  }
  if (method === 'POST' && path === '/subscriptions/complete') {
    if (!isPushEndpoint(body.endpoint)) throw new BadRequest('endpoint');
    if (!DATE_RE.test(body.date ?? '')) throw new BadRequest('date');
    try {
      await markCompleted(body.endpoint, body.date);
    } catch (err) {
      if (err.name === 'ConditionalCheckFailedException') {
        return json(404, { error: 'unknown subscription' });
      }
      throw err;
    }
    return json(200, { ok: true });
  }
  if (method === 'DELETE' && path === '/subscriptions') {
    if (!isPushEndpoint(body.endpoint)) throw new BadRequest('endpoint');
    await deleteSubscription(idFor(body.endpoint));
    return json(200, { ok: true });
  }
  return json(404, { error: 'not found' });
}

export async function handler(event) {
  const method = event.requestContext?.http?.method ?? 'GET';
  const path = (event.rawPath ?? '/').replace(/\/+$/, '') || '/';
  try {
    return await route(method, path, parseBody(event));
  } catch (err) {
    if (err instanceof BadRequest) return json(400, { error: err.message });
    console.error(err);
    return json(500, { error: 'internal error' });
  }
}
