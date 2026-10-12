---
status: done
date: 2026-10-12
branch: feat/reminders → main
pr: https://github.com/wpieters/daily-quest-workout-app-flutter/pull/2
adrs: [0012]
---

# HANDOFF: DailyQuest – Daily Quest Reminders

## Context
DailyQuest is a Flutter PWA at https://dailyquest.duhblinn.xyz, deployed from `main` by Amplify. Progression (XP, levels, titles) shipped in [handoff 0001](0001-progression-system.md). Wynand wants to be reminded about the Daily Quest during the day. The design is settled in [ADR 0012](../adr/0012-web-push-reminders.md): Web Push from a small AWS backend, because browsers can't schedule notifications for a closed PWA.

## Goal
Three optional, user-set reminders a day, delivered as push notifications to the installed PWA:

| Slot | Default | Sent when |
|---|---|---|
| Morning | 07:00 | always: "a new quest has arrived" |
| Afternoon | 14:00 | only if today's quest isn't complete |
| Evening | 20:00 | only if today's quest isn't complete: penalty warning (-150 XP) |

Times are local to the device's timezone. Each can be switched off.

## Done so far
- `infra/terraform/`: DynamoDB table, API Lambda with Function URL, dispatch Lambda on a 15-minute EventBridge rule, VAPID key in SSM, IAM scoped to the table and key, CloudWatch log groups with 14-day retention. **Applied** 2026-10-12; API at `https://7xqk6vcnevbxx32k3ris3sfd5e0tdujd.lambda-url.us-east-1.on.aws`.
  - Gotcha: since October 2025 a public Function URL needs `lambda:InvokeFunction` (with `lambda:InvokedViaFunctionUrl`) as well as `lambda:InvokeFunctionUrl`, or every request gets 403. That needs AWS provider 6.x for `invoked_via_function_url`. Planned as one extra permission; **apply pending**.
- `infra/lambda/reminders/`: Node 22 Lambda code (`api.mjs`, `dispatch.mjs`, `store.mjs`, `vapid.mjs`) with unit tests for the pure logic (`npm test`, 16 passing).
- Flutter side:
  - `web/push_sw.js` (push + click handling) and `web/push.js` (permission, subscribe, API calls), loaded from `index.html`. The worker is registered at scope `/push/` because Flutter 3.47's own service worker is a stub that unregisters itself and would replace a worker at `/`.
  - `lib/models/reminder_settings.dart`, `lib/services/reminder_service.dart` (+ `_web`/`_stub` via conditional import), `lib/providers/reminder_provider.dart`. Settings persist under the `reminder_settings` key.
  - `WorkoutNotifier._completeDay` fires `reportCompleted` once per day, fire-and-forget.
  - Settings screen: master switch, one row per slot with a checkbox and time picker; install hint on iOS Safari; hidden entirely when `REMINDERS_API_URL` is empty.
  - `amplify.yml` passes `--dart-define=REMINDERS_API_URL=...`.
  - Tests: 21 new (model, provider, completion hook, settings UI); 110 total.

## Constraints
- Commits as `wpieters <me@wynandpieters.dev>`.
- Riverpod 3 `Notifier`; no new state-management libraries.
- Offline-first stays: tracking must never wait on the network.
- Only `main` deploys; feature branches don't get previews (ADR 0011).
- The `dailyquest` AWS profile is admin. Agents may run `terraform plan` but not `apply`.

## Open questions
- Should the evening message include the current streak or level? (The server doesn't know them; the app would have to send them with each `PUT`.)
- Timezone changes while travelling: the app re-`PUT`s on launch, so the server follows the device after the first open in the new zone. Good enough?

## Outcome
Shipped on `feat/reminders` (PR #2). Verified end to end on 2026-10-12: the Amplify branch preview subscribed from a phone, an evening slot was set for a minute ahead, and the dispatcher's next 15-minute tick delivered the push.

**Found along the way**
- Public Function URLs created after October 2025 need `lambda:InvokeFunction` (scoped by `lambda:InvokedViaFunctionUrl`) as well as `lambda:InvokeFunctionUrl`; without it every request is 403. Needed AWS provider 6.x.
- The Function URL's CORS list must include every origin the app is served from. Branch previews on `amplifyapp.com` are added through `extra_allowed_origins`.
- Flutter 3.47 removed `--pwa-strategy`, and its generated service worker now unregisters itself. The push worker therefore lives at scope `/push/`.
- A subscription is per browser and origin, so the preview and production domains hold separate subscriptions; the preview's expires with the 60-day TTL unless switched off.

**Open questions**: unchanged, see below. Neither blocks use.
