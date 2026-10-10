# 2. Offline-first, with a pure Dart progression engine

- **Status:** Accepted
- **Date:** 2026-10-10
- **Source:** [Handoff 0001](../handoffs/0001-progression-system.md)

## Context
The app has no backend, and the handoff rules out login and sync. Yet progression needs time-based rules, such as missed-day penalties, that a server would normally enforce. An earlier React prototype used Supabase and login, which is not the direction for this app.

## Decision
- Riverpod manages state and SharedPreferences stores data. Everything works offline.
- All progression rules live in `lib/progression/`, which is pure Dart with no Flutter imports. Every tunable value lives in `ProgressionConfig`.
- Missed days are settled when the app opens, at midnight while it's open, and on the first tap after midnight. The app compares the current date with `lastActiveDate`, and each day is settled exactly once.
- Stored data carries a `schemaVersion` (currently 2). Data saved before the progression system keeps its history and streaks and starts progression at the starting values, with no penalties for days before the upgrade.

## Consequences
- The rules can be tested without Flutter, and the engine tests run in milliseconds.
- Someone could change the device clock to avoid penalties. That's acceptable for a personal, single-player app, but it would need revisiting for multiplayer.
- Level, title, HP and MP are always derived from stored values, never stored themselves.
