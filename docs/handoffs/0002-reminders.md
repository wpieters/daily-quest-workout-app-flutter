---
status: in-progress
date: 2026-10-12
branch: feat/reminders → main
pr:
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
- `infra/terraform/`: DynamoDB table, API Lambda with Function URL, dispatch Lambda on a 15-minute EventBridge rule, VAPID key in SSM, IAM scoped to the table and key, CloudWatch log groups with 14-day retention. `make tp` plans cleanly; **it has not been applied.**
- `infra/lambda/reminders/`: Node 22 Lambda code (`api.mjs`, `dispatch.mjs`, `store.mjs`, `vapid.mjs`) with unit tests for the pure logic (`npm test`, 16 passing).

## Remaining work (Flutter side)
1. **Apply the infrastructure** (`make ta` in `infra/terraform/`, Wynand only), and note the `reminders_api_url` output.
2. **Service worker.** Flutter's generated `flutter_service_worker.js` doesn't handle `push`. Add a small `web/push_sw.js` (or import a script into the generated worker) that shows the notification from the push payload (`title`, `body`, `url`) and opens/focuses the app on click.
3. **Reminder settings** in `SettingsScreen`: an on/off switch and three time pickers. Persist in `UserProgress` (bump `schemaVersion` to 3 with a migration) or a separate `reminder_settings` key.
4. **Subscription flow.** On enabling: request `Notification.permission` from the tap, `pushManager.subscribe` with the VAPID key from `GET /vapid`, then `PUT /subscriptions` with the subscription JSON, `Intl.DateTimeFormat().resolvedOptions().timeZone`, and the times. Re-`PUT` on every settings change and on launch (this refreshes the TTL). `DELETE` on disabling. Use `package:web` / `dart:js_interop`; keep it behind an abstract `ReminderService` so the pure Dart tests don't touch JS.
5. **Completion hook.** In `WorkoutNotifier._completeDay`, after the first completion of the day, `POST /subscriptions/complete` with today's local date. Fire-and-forget; log failures.
6. **Build-time API URL.** Pass the Function URL as `--dart-define=REMINDERS_API_URL=...` in `amplify.yml`, read with `String.fromEnvironment`. If empty, hide the reminder settings.
7. **Install guidance.** On iOS Safari outside standalone mode, show "Add to Home Screen to enable reminders" instead of the switch.
8. Tests: provider tests for settings persistence and the completion hook (mock `ReminderService`); a test that the UI hides when the API URL is empty.
9. Update `docs/spec.md` and the Outcome section here; set `status: done`.

## Constraints
- Commits as `wpieters <me@wynandpieters.dev>`.
- Riverpod 3 `Notifier`; no new state-management libraries.
- Offline-first stays: tracking must never wait on the network.
- Only `main` deploys; feature branches don't get previews (ADR 0011).
- The `dailyquest` AWS profile is admin. Agents may run `terraform plan` but not `apply`.

## Open questions
- Should the evening message include the current streak or level? (The server doesn't know them; the app would have to send them with each `PUT`.)
- Timezone changes while travelling: the app re-`PUT`s on launch, so the server follows the device after the first open in the new zone. Good enough?
