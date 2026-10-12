# 12. Reminders via Web Push, with a small AWS backend

- **Status:** Accepted
- **Date:** 2026-10-12

## Context
Wynand wants three daily reminders: in the morning that the quest is active, in the afternoon if it's still incomplete, and a sterner warning in the evening. The app is a PWA installed to the home screen.

No browser can fire a notification at a chosen time while a PWA is closed. `flutter_local_notifications` supports web but states that browsers don't support scheduled or repeating notifications. Chrome's Notification Triggers API, which would have allowed it, is listed as "no longer pursuing". Periodic Background Sync is Chromium-only and fires on Chrome's engagement-based schedule, not at a given time. Only **Web Push** wakes a closed PWA on both Android and iOS (16.4+, installed to the home screen), and Web Push needs a server to send the pushes.

[ADR 0002](0002-offline-first-architecture.md) made the app offline-first with no backend.

## Decision
Reminders are delivered by Web Push from a small backend in the same AWS account and region as the Amplify app, managed with Terraform under `infra/terraform/` (same layout as Wynand's other projects: an S3 remote state in `piforge-tfstate`, a module per concern, and a Makefile with `ti`/`tp`/`ta`).

- **DynamoDB** holds one item per push subscription: the endpoint and keys, the IANA timezone, the three times (or null when off), the date the quest was last completed, and the date each slot was last sent. A TTL expires subscriptions the app stops refreshing.
- **An API Lambda behind a Function URL** (no API Gateway) exposes `GET /vapid`, `PUT /subscriptions`, `POST /subscriptions/complete` and `DELETE /subscriptions`. CORS is restricted to the app origin. It's unauthenticated: the app is public, so any secret shipped with it would be too. The endpoint only accepts URLs on the browsers' push services, caps the body at 4 KB, and has reserved concurrency of 2.
- **A dispatch Lambda** runs every 15 minutes, computes each subscription's local time, and sends whichever slot has come due within the last hour and hasn't been sent today. The morning slot always sends; the afternoon and evening slots are suppressed when today is marked complete. Suppression is server-side because a service worker can't read the app's storage and Chrome penalises pushes that show nothing. Subscriptions the push service reports as gone (404/410) are deleted.
- **VAPID keys** are a P-256 key that Terraform generates and stores in SSM as a SecureString. The Lambda derives the public key from it, so no key is ever hand-copied; the app fetches it from `GET /vapid`.

The app stays offline-first for tracking. Only reminders need the network: the app `PUT`s its subscription and times whenever settings change or on launch, and `POST`s "complete" when the day's quest is done. If a request fails, the worst case is an extra reminder.

## Consequences
- This amends ADR 0002: the app now has a backend, but one it never depends on to function.
- Anyone can register a subscription. The damage is bounded to a few push messages to their own device and a few DynamoDB writes; the cost for one real user is within the free tier.
- iOS users must install the PWA to the home screen before the permission prompt will work, and both Chrome and Safari require the prompt to come from a tap.
- The VAPID private key lives in Terraform state as well as in SSM. The state bucket is encrypted; rotating the key means tainting `tls_private_key.vapid`, after which every subscription must be re-registered.
- The `dailyquest` AWS profile currently resolves to the `terraform-japanedugames` admin user in account 774305596805. It should be scoped down before this is applied routinely.
