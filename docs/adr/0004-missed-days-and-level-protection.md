# 4. Missed days and level protection

- **Status:** Proposed. Implemented, awaiting confirmation.
- **Date:** 2026-10-10
- **Source:** [Handoff 0001](../handoffs/0001-progression-system.md) (locked rules, plus proposed defaults 1 to 3)

## Context
The handoff locked a **-150 XP** penalty for each missed day, and a rule that a level can't be lost until **7 consecutive** days have been missed. Exactly what counts as a missed day, and how the protection works, were left as proposals.

## Decision
- A **missed day** is a past day on which no exercise reached its target. Partial days aren't penalised.
- While consecutive misses are fewer than 7, XP is held at the current level's floor. Penalties beyond the floor are dropped, not saved up for later.
- From the 7th consecutive miss onward, the penalty can push XP below the floor and drop levels.
- Missed days are calculated retroactively, as described in [ADR 0002](0002-offline-first-architecture.md).

## Consequences
- Doing a single exercise to its target protects the whole day. The rule is forgiving on purpose, so a busy day doesn't cost XP.
- When the user opens the app after a long gap, several levels can be lost at once. Since [handoff 0004](../handoffs/0004-missed-day-notice.md) a QUEST FAILED window reports the days missed, the XP lost and the protection or level change, once per rollover; the STATUS screen keeps the running state.
