# 3. XP awards and leveling curve

- **Status:** Accepted
- **Date:** 2026-10-10
- **Source:** [Handoff 0001](../handoffs/0001-progression-system.md) (locked decisions)

## Context
Progression needs to reward completing exercises, not individual reps, and reaching level 100 should take most of a year of consistent training.

## Decision
- An exercise reaching its target earns **100 XP**. Completing all four earns a **+100 bonus**, which requires running to be enabled. A full day is worth 500 XP, and a day without running is worth 300 XP.
- The XP needed to go from level L to L+1 is `round(100 + 18·L + 2.5·L^1.35)`, for levels 1 to 100.
- The total XP to reach level 100 is **151,692**. That takes about 304 days at 500 XP a day, about 345 days at 440, and about 506 days at 300.
- Titles are derived from level, never stored, and drop when the level drops. The thresholds are at levels 1, 10, 20 and so on up to 100, and are listed in `docs/spec.md`.
- *Implementation choice, unconfirmed:* the XP a day earns can only go up. Resetting the counters, toggling running off, or using the minus button never awards that XP again and never takes it back.

## Consequences
- The 151,692 total is a little below the handoff's rough estimate of 152k to 155k. The pace targets are still met.
- The curve constants can be changed in one place, `ProgressionConfig`.
