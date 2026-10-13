---
status: in-progress
date: 2026-10-13
branch: feat/missed-day-notice → main
pr:
adrs: [0004, 0008]
---

# HANDOFF: DailyQuest – Missed-day penalty notice

## Context
[ADR 0004](../adr/0004-missed-days-and-level-protection.md) charges -150 XP per missed day, held at the level floor for the first six consecutive misses, and notes: "There is no on-screen notice for this yet; it only shows on the STATUS screen." `WorkoutNotifier.rollover` applies the penalty through `ProgressionEngine.catchUp` and discards the result's `missedDaysProcessed` and level-down `levelChanges`. The evening reminder (handoff 0002) threatens the penalty, so it should visibly land.

## Goal
When the app opens (or rolls over mid-session) after one or more missed days, a **QUEST FAILED** system window explains what happened, once, before anything else:

- days missed (e.g. "3 days without a completed exercise")
- XP lost (the real amount, after the floor; "-0 XP" when fully protected at the floor)
- either "Level protected · N miss(es) of protection left" or "Lv 10 → Lv 9" when a level was lost
- "Tap to continue"

Same shape as the level-up window ([ADR 0008](../adr/0008-level-up-ceremony.md)) but in the danger colour, no hero sprite.

## Plan
1. `MissedDayPenalty` value object (days, xpLost, fromLevel, toLevel, protectionLeft).
2. `WorkoutState.pendingPenalty`, filled in `rollover` from the XP/level before and after `catchUp` when `missedDaysProcessed > 0`; `dismissPenalty()` clears it. Not persisted: if the app is killed before the tap, the status screen still has the facts.
3. `MissedDayOverlay` widget; `WorkoutScreen` shows it above the other overlays and holds level-up windows until it's dismissed.
4. Tests: provider (one miss at the floor, three misses, a week away with a level drop, no notice on a normal day), widget (text and dismiss).
5. Spec and ADR 0004 consequence updated.

## Constraints
- Commits as `wpieters <me@wynandpieters.dev>`; Riverpod 3 `Notifier`; no new packages.
- Rollover stays idempotent: the notice appears only when a penalty was actually applied in this run.

## Open questions
- Should the notice also show when protection held XP at the floor and nothing was lost? Default: yes, the miss still counts toward losing protection, and the window says so.
