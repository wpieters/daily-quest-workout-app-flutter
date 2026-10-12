import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import { describe, it } from 'node:test';

process.env.TABLE_NAME = 'test';

const { dueSlots, localClock } = await import('./dispatch.mjs');
const { isPushEndpoint, parseSubscription } = await import('./api.mjs');
const { vapidKeysFromPem } = await import('./vapid.mjs');

const sub = {
  id: 'x',
  timezone: 'Europe/Dublin',
  times: { morning: '07:00', afternoon: '14:00', evening: '20:00' },
};
// 2026-07-01 is in Irish Summer Time (UTC+1).
const at = (hhmmLocal) => new Date(`2026-07-01T${hhmmLocal}:00+01:00`);

describe('localClock', () => {
  it('converts to the subscription timezone', () => {
    assert.deepEqual(localClock(at('07:05'), 'Europe/Dublin'), {
      date: '2026-07-01',
      minutes: 7 * 60 + 5,
    });
  });
  it('uses h23 so midnight is 0, not 24', () => {
    assert.equal(localClock(at('00:10'), 'Europe/Dublin').minutes, 10);
  });
});

describe('dueSlots', () => {
  it('sends the morning slot once it is due', () => {
    assert.deepEqual(dueSlots(sub, at('07:05')), [
      { slot: 'morning', date: '2026-07-01', suppressed: false },
    ]);
  });
  it('is not due before the slot time', () => {
    assert.deepEqual(dueSlots(sub, at('06:59')), []);
  });
  it('is not due after the window', () => {
    assert.deepEqual(dueSlots(sub, at('08:00')), []);
  });
  it('skips a slot already sent today', () => {
    const sent = { ...sub, lastSent: { morning: '2026-07-01' } };
    assert.deepEqual(dueSlots(sent, at('07:05')), []);
  });
  it('sends again on a new day', () => {
    const sent = { ...sub, lastSent: { morning: '2026-06-30' } };
    assert.equal(dueSlots(sent, at('07:05')).length, 1);
  });
  it('suppresses afternoon and evening once the quest is complete', () => {
    const done = { ...sub, completedDate: '2026-07-01' };
    assert.deepEqual(dueSlots(done, at('14:00')), [
      { slot: 'afternoon', date: '2026-07-01', suppressed: true },
    ]);
    assert.deepEqual(dueSlots(done, at('20:30')), [
      { slot: 'evening', date: '2026-07-01', suppressed: true },
    ]);
  });
  it('still sends the morning slot when yesterday was completed', () => {
    const done = { ...sub, completedDate: '2026-06-30' };
    assert.equal(dueSlots(done, at('07:00'))[0].suppressed, false);
  });
  it('ignores slots switched off', () => {
    const off = { ...sub, times: { ...sub.times, evening: null } };
    assert.deepEqual(dueSlots(off, at('20:00')), []);
  });
});

describe('isPushEndpoint', () => {
  it('accepts the browsers’ push services', () => {
    for (const e of [
      'https://fcm.googleapis.com/fcm/send/abc',
      'https://web.push.apple.com/QAbc',
      'https://updates.push.services.mozilla.com/wpush/v2/abc',
      'https://db5p.notify.windows.com/w/?token=abc',
    ]) {
      assert.ok(isPushEndpoint(e), e);
    }
  });
  it('refuses anything else', () => {
    for (const e of [
      'http://fcm.googleapis.com/x',
      'https://evil.example/fcm.googleapis.com',
      'https://fcm.googleapis.com.evil.example/x',
      'not a url',
      undefined,
    ]) {
      assert.equal(isPushEndpoint(e), false, String(e));
    }
  });
});

describe('parseSubscription', () => {
  const valid = {
    subscription: {
      endpoint: 'https://fcm.googleapis.com/fcm/send/abc',
      keys: { p256dh: 'p', auth: 'a' },
    },
    timezone: 'Europe/Dublin',
    times: { morning: '07:00', afternoon: null, evening: '20:00' },
  };
  it('returns the stored fields', () => {
    assert.deepEqual(parseSubscription(valid), {
      endpoint: valid.subscription.endpoint,
      keys: { p256dh: 'p', auth: 'a' },
      timezone: 'Europe/Dublin',
      times: { morning: '07:00', afternoon: null, evening: '20:00' },
    });
  });
  it('rejects bad times, timezones and all-off', () => {
    assert.throws(() =>
      parseSubscription({ ...valid, times: { morning: '7:00' } }),
    );
    assert.throws(() =>
      parseSubscription({ ...valid, times: { morning: '24:00' } }),
    );
    assert.throws(() => parseSubscription({ ...valid, timezone: 'Mars/Olympus' }));
    assert.throws(() => parseSubscription({ ...valid, times: {} }));
  });
});

describe('vapidKeysFromPem', () => {
  it('derives base64url keys of the right length from a P-256 PEM', () => {
    const { privateKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
    const pem = privateKey.export({ type: 'sec1', format: 'pem' });
    const keys = vapidKeysFromPem(pem);
    assert.equal(Buffer.from(keys.publicKey, 'base64url').length, 65);
    assert.equal(Buffer.from(keys.publicKey, 'base64url')[0], 0x04);
    assert.equal(Buffer.from(keys.privateKey, 'base64url').length, 32);
  });
  it('rejects other curves', () => {
    const { privateKey } = generateKeyPairSync('ec', { namedCurve: 'secp384r1' });
    const pem = privateKey.export({ type: 'sec1', format: 'pem' });
    assert.throws(() => vapidKeysFromPem(pem), /P-256/);
  });
});
