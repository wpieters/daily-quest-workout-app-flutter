---
status: in-progress
date: 2026-10-23
branch: feat/export-import → main
pr:
adrs: [0014]
---

# HANDOFF: DailyQuest – Backup and restore (JSON export/import)

## Context
DailyQuest is a Flutter PWA at https://dailyquest.duhblinn.xyz. Everything is in SharedPreferences (browser local storage on web) under three keys, written by `StorageService` (`lib/services/storage_service.dart`): `user_progress` (`UserProgress`, carries `schemaVersion`, currently 2), `today_workout` (`WorkoutDay`), `reminder_settings` (`ReminderSettings`). [ADR 0014](../adr/0014-local-json-backup.md) decides on a local JSON file and no accounts.

The web-only pieces follow the pattern in `lib/services/reminder_service.dart`: an abstract service, a `_stub` and a `_web` implementation chosen by conditional import, `dart:js_interop` bindings in the web file, and a fake in `test/fakes/` for tests.

## Goal
In Settings, a **Backup** section with:

- **Export**: downloads `dailyquest-backup-YYYY-MM-DD.json`. Afterwards the section shows "Last export: <date>" (stored locally, not in the file).
- **Import**: opens a file picker, validates the file, shows a confirmation naming what's in it ("Level 12, 38-day streak, 41 workouts, exported 2026-10-20. Replace everything on this device?"), then replaces all three keys, reloads the workout and reminder state, and re-syncs the push subscription if reminders are on (`ReminderNotifier.reload` already exists; see how Reset All Data chains `disable`/`resetAll`/`reload` in `settings_screen.dart`).
- **Persistent storage**: on first launch the web app calls `navigator.storage.persist()`. Nothing to show the user; log the result in debug builds only.

### File format
```json
{
  "app": "dailyquest",
  "format": 1,
  "exportedAt": "2026-10-23T18:04:11.000Z",
  "data": {
    "user_progress": { ...exactly what is stored... },
    "today_workout": { ... } | null,
    "reminder_settings": { ... } | null
  },
  "checksum": "<sha256 hex of the canonical JSON of data>"
}
```
`data` values are the stored JSON verbatim, so the existing `fromJson` migrations apply on import. Canonical JSON for the checksum: keys sorted, no whitespace (write one small helper and test it). Import refuses: not JSON, `app` mismatch, `format` newer than the app's, checksum mismatch, or `user_progress` failing to parse. A missing checksum on a hand-edited file is refused too; the error message says which check failed.

## Plan
1. `lib/services/backup_service.dart` (+ `_stub`, `_web`): `Future<void> download(String filename, String json)` and `Future<String?> pickFile()` (null when cancelled). Web: `Blob` + object URL + anchor click for download; `<input type="file" accept=".json,application/json">` for pick. Stub: unsupported, section hidden (as reminders do when unavailable).
2. `lib/models/backup.dart`: pure Dart `Backup` with `encode(...)`, `decode(String)` returning either a backup or a reason, `summary` for the confirmation text, the canonical-JSON + sha256 helpers (`package:crypto` is already transitively available; add it to `pubspec.yaml` explicitly).
3. `StorageService.exportAll()` / `importAll(Map)` moving raw JSON strings; `lastExportAt` under a new key `last_export_at` (not included in the backup, and cleared by Reset All Data).
4. `WorkoutNotifier.reloadFromStorage()`: like the `_load` path but without rollover side effects being skipped; simplest is to reuse `_load` and then `rollover`.
5. Settings section with the two actions, the last-export line, and the confirmation dialog. Errors in a snackbar.
6. `web/index.html` or `push.js`: `navigator.storage?.persist?.()` guarded, once.
7. Tests: `Backup` encode/decode round-trip, every refusal reason, checksum canonicalisation; `StorageService` export/import; provider reload; settings UI with a `FakeBackupService` (export writes, import with a canned file replaces state and asks first; cancel leaves things alone).
8. Spec: add the Backup section to Settings and replace "Data export/import" and "Backup/restore" with pointers to it. Drop "Widget for home screen" from phase 3 (not a PWA feature).

## Constraints
- Commits as `wpieters <me@wynandpieters.dev>`; Riverpod 3 `Notifier`; `crypto` is the only new dependency.
- Offline-first: both actions work with no network. Only the optional push re-sync touches the API, and it must not block the import.
- Import is destructive: same confirmation weight as Reset All Data.
- iOS Safari PWA: downloads open the share sheet rather than saving silently. Acceptable, but check the filename survives.

## Open questions
- Should Export also be offered from the QUEST FAILED window or after a long streak ("back this up")? Default: no, keep it in Settings; revisit if the last-export date keeps getting old.
- The `last_export_at` nudge: show the line in muted text, or turn it orange after 30 days? Default: muted only.

## Outcome
Implemented on `feat/export-import`.

- `lib/models/backup.dart`: `Backup` (encode/decode, canonical JSON, SHA-256 checksum, filename), `BackupException` with the reason shown to the user. `crypto` added to `pubspec.yaml`.
- `lib/services/backup_service.dart` (+ `_stub`, `_web`) over `web/backup.js`: `download`, `pickFile` (null on cancel), and a `persist()` call at page load.
- `StorageService.exportAll/importAll`, `loadLastExport/saveLastExport` (key `last_export_at`, cleared by Reset All Data). `WorkoutNotifier.reload()` re-reads storage and settles any days that ended since the backup.
- Settings: Backup section with Export (shows the last export date), Import (validate, confirm with level/streak/workouts/export date, replace, reload workout and reminder state). Hidden when the service is unavailable.
- Tests: 17 new (model round-trip and every refusal, storage export/import, settings UI with a fake service: export, import with confirm and cancel, bad file, picker cancelled). 157 total.

**Found along the way**: a backup whose history doesn't include yesterday comes back with streak 0 after import, because reload runs the rollover and the streak rule from PR #7 applies. That's correct for real files, which carry history; the UI test's fixture needed a completed yesterday.

**Open questions**: both defaults kept (Settings only; muted last-export line).
