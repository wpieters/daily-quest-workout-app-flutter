// Runs on a schedule (every 15 minutes). For every subscription, works out the
// local time and sends whichever reminder slot has just come due.
//
//   morning   always: the quest is active
//   afternoon only if today's quest isn't complete
//   evening   only if today's quest isn't complete: penalty warning
//
// A slot is due when local time is within WINDOW_MINUTES after its time and
// it hasn't been sent today (lastSent[slot] !== today). Missed runs therefore
// catch up within the window, and nothing is sent twice.
import webpush from 'web-push';
import {
  allSubscriptions,
  deleteSubscription,
  markSent,
} from './store.mjs';
import { vapidKeys } from './vapid.mjs';

const WINDOW_MINUTES = Number(process.env.WINDOW_MINUTES ?? 60);
const APP_URL = process.env.APP_URL ?? 'https://dailyquest.duhblinn.xyz';
const PENALTY_XP = process.env.PENALTY_XP ?? '150';

export const MESSAGES = {
  morning: {
    title: '[Daily Quest] A new quest has arrived',
    body: '100 push-ups, 100 sit-ups, 100 squats, 10 km. Complete it before midnight.',
  },
  afternoon: {
    title: '[Daily Quest] Quest incomplete',
    body: "You haven't finished today's Daily Quest yet. Time remaining: until midnight.",
  },
  evening: {
    title: '[WARNING] Penalty imminent',
    body: `Failing today's Daily Quest costs ${PENALTY_XP} XP. Complete it before midnight.`,
  },
};

/** Local calendar date and minutes-since-midnight for `date` in `timeZone`. */
export function localClock(date, timeZone) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);
  const get = (type) => parts.find((p) => p.type === type).value;
  return {
    date: `${get('year')}-${get('month')}-${get('day')}`,
    minutes: Number(get('hour')) * 60 + Number(get('minute')),
  };
}

const toMinutes = (hhmm) => {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
};

/**
 * Which slots to send for `sub` right now: due by the clock, not sent today,
 * and (after the morning) only while the quest is still incomplete.
 */
export function dueSlots(sub, now = new Date()) {
  const { date, minutes } = localClock(now, sub.timezone);
  const completed = sub.completedDate === date;
  const due = [];
  for (const [slot, time] of Object.entries(sub.times ?? {})) {
    if (!time || !MESSAGES[slot]) continue;
    if (sub.lastSent?.[slot] === date) continue;
    const elapsed = minutes - toMinutes(time);
    if (elapsed < 0 || elapsed >= WINDOW_MINUTES) continue;
    due.push({ slot, date, suppressed: slot !== 'morning' && completed });
  }
  return due;
}

export async function handler() {
  const keys = await vapidKeys();
  webpush.setVapidDetails(
    process.env.VAPID_SUBJECT ?? `mailto:noreply@${new URL(APP_URL).host}`,
    keys.publicKey,
    keys.privateKey,
  );

  const stats = { subscriptions: 0, sent: 0, suppressed: 0, removed: 0, failed: 0 };
  for await (const sub of allSubscriptions()) {
    stats.subscriptions++;
    for (const { slot, date, suppressed } of dueSlots(sub)) {
      // Suppressed slots are still marked, so a late completion doesn't
      // trigger them if the window is wide.
      if (suppressed) {
        stats.suppressed++;
        await markSent(sub.id, slot, date);
        continue;
      }
      try {
        await webpush.sendNotification(
          { endpoint: sub.endpoint, keys: sub.keys },
          JSON.stringify({ ...MESSAGES[slot], slot, url: APP_URL }),
          { TTL: WINDOW_MINUTES * 60, urgency: 'normal' },
        );
        await markSent(sub.id, slot, date);
        stats.sent++;
      } catch (err) {
        if (err.statusCode === 404 || err.statusCode === 410) {
          // The browser unsubscribed or the subscription expired.
          await deleteSubscription(sub.id);
          stats.removed++;
          break;
        }
        stats.failed++;
        console.error(`push to ${sub.id} failed`, err.statusCode, err.body);
      }
    }
  }
  console.log(JSON.stringify(stats));
  return stats;
}
