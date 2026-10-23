# 14. Backup as a local JSON file, no accounts

- **Status:** Accepted
- **Date:** 2026-10-23

## Context
All progress lives in the browser's site storage ([ADR 0002](0002-offline-first-architecture.md)). Clearing site data, losing the phone, or the browser evicting storage under pressure loses everything, and there's no way to move to a new device. The spec lists "data export/import" and "backup/restore" as phase 3 work.

Three options were weighed: a local file the user downloads and re-imports; a cloud save keyed by a random recovery code on the existing reminders backend; and real logins (Cognito, passkeys, Google). The app has one user and an unauthenticated backend built for push subscriptions only.

## Decision
- Backup is a **JSON file** the user downloads from Settings and restores through a file picker. Human-readable on purpose: this is a single-player game, and tamper-proofing would only inconvenience its one player. A checksum detects corruption, not editing.
- The file is **one document** holding every stored key (`user_progress`, `today_workout`, `reminder_settings`) plus `app`, `format` version and `exportedAt`. This document is the canonical interchange format: a future cloud save carries the same payload.
- The app asks the browser for **persistent storage** (`navigator.storage.persist()`) on first launch, so Chrome won't evict the data under pressure.
- **No accounts.** A recovery-code cloud save is the next step if a second device is ever wanted; logins only once there are users other than Wynand.

## Consequences
- Protection depends on the user exporting now and then. The Settings copy should say when the last export was made.
- Import replaces everything, including reminder settings, and must re-sync the push subscription if reminders are on. It is as destructive as Reset All Data and gets the same confirmation.
- Importing a file from a newer `format` is refused; older formats go through the same migrations as stored data (`schemaVersion` on `user_progress`).
- Reminder settings in the file are device preferences, not a subscription; restoring them on a new device still needs the user to switch reminders on there.
