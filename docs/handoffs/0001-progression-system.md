---
status: done
date: 2026-10-10
branch: feat/progression-system → main
pr: https://github.com/wpieters/daily-quest-workout-app-flutter/pull/1
adrs: [0003, 0004, 0005, 0006, 0007, 0008, 0009, 0010, 0011]
---

# HANDOFF: DailyQuest – Progression System Implementation

## Context

DailyQuest is a Flutter workout tracker for the One Punch Man routine (100 push-ups, 100 sit-ups, 100 squats, 10km run), done in 10 hourly sets of 10. It's themed on Solo Leveling's "Preparation To Become Powerful" daily quest.

- Repo: `wpieters/daily-quest-workout-app-flutter`
- Branches: `main` (spec docs), `vibe/claude-code`, `vibe/warp-dev`, `vibe/jetbrains-junie`
- Assumed target branch: `vibe/claude-code` (the version in daily use). **Confirm with Wynand before starting.**
- Hosting: AWS Amplify, auto-deploys per branch (e.g. `vibe-claude-code.d14wa6u34905q.amplifyapp.com`)
- Current state: the four counters, stage progress, running toggle, streak, and local storage work. None of the progression system below exists yet.
- Note: `spec.md` on `main` predates the XP/level/title additions. Update it as part of this work so it matches this document.

## Goal

Add RPG progression: XP, levels 1–100, titles, and stats. Fix the known UX gap with the running toggle. Multiplayer, the skill store, and the item store are **out of scope**, but the data model must leave room for them.

## Locked decisions (implement as written)

### Daily tracking (existing, keep)
- Push-ups, sit-ups, squats: +1 rep per tap, target 100 (10 stages of 10).
- Running: +100m per tap, target 10km (100 taps). Display in km.
- The day resets at local midnight.

### UX fix (required)
- When "Include running" is unchecked, the running button must be **disabled** (visually greyed out and non-interactive), not just excluded from completion. Every tool missed this first time.

### XP
- 100 XP awarded when an individual exercise reaches its target (not per rep).
- +100 bonus XP when all four are completed, which requires running to be enabled.
- So a full day is 500 XP, and a day without running is 300 XP.
- A missed day costs -150 XP.

### Level protection
- A user cannot drop a level unless they miss **7 consecutive days**.

### Leveling curve
- XP to go from level L to L+1 is `100 + (18 × L) + (2.5 × L^1.35)`, rounded.
- Total XP to reach level 100 is roughly 152–155k.
- Expected pace: about 10 months at 500/day, about a year at a ~440/day average, and about 17 months at 300/day. Make the formula constants configurable in one place.

### Titles (derive from level; don't store separately)
| Level | Title |
|---|---|
| 1 | World's Weakest |
| 10 | Fledgling Warrior |
| 20 | E-Rank Hunter |
| 30 | D-Rank Hunter |
| 40 | C-Rank Hunter |
| 50 | B-Rank Hunter |
| 60 | A-Rank Hunter |
| 70 | National Level Hunter |
| 80 | Shadow Sovereign Candidate |
| 90 | S-Rank Hunter |
| 100 | World's Strongest Hunter |

If a user drops below a threshold, their title drops with them.

### Stats
- Stats are HP, MP, Strength, Vitality, Agility, Intelligence, Perception, and Fatigue.
- Strength comes from push-ups, Vitality from sit-ups, and Agility from squats.
- Stat growth is **level-based**, not rep-based, so the cap isn't hit before level 100.
- Intelligence and Perception increase **only** through skills and items, with no per-level growth.
- HP is derived from Vitality, and MP is derived from Intelligence.
- Each level grants 3 skill points. Store them now, even though there's no store to spend them in yet.

### Fatigue
- Users start with 7. They recover 1 per day, up to their max.
- The max increases over time for users who run.
- Fatigue is spent in multiplayer battles. That's out of scope, so for now just track current and max values.

## Proposed defaults (implement, but keep configurable and flag in the PR)

These are proposals and Wynand hasn't confirmed them.

1. **Missed day definition:** a past day on which no exercise reached its target. Partial days are not penalised.
2. **Missed-day processing:** there's no backend, so calculate missed days on app open by comparing against `lastActiveDate`, and apply them retroactively.
3. **Protection mechanics:** while consecutive misses are fewer than 7, clamp total XP at the current level's floor. Penalties are not banked. From the 7th consecutive miss onward, deductions can cross level boundaries.
4. **Starting stats:** 10 each for Strength, Vitality, Agility, Intelligence, and Perception.
5. **Stat gain on level up:** +2 to Strength, Vitality, or Agility if that exercise was completed on at least 50% of the days spent in the previous level. This gives about 210 maximum by level 100, leaving headroom under a 255 cap.
6. **Level-down penalty:** a flat -5 to Strength, Vitality, and Agility per level lost, with 10 as the floor.
7. **Derived stats:** HP = Vitality × 10 and MP = Intelligence × 5.
8. **Fatigue max:** +1 for every 10 levels gained, but only if running was completed on at least 50% of days in that span. This gives a maximum of 17.

## Open questions (ask, don't guess)

- **Stat cap:** should it be 255, or 999 with items and consumables able to push past the level-based ceiling?
- **Goku animation:** every tool misread this requirement. Wynand's original idea was a power-up GIF that progresses through transformation stages. Get clarification on what triggers each stage (daily stage progress, level, or streak) before building it. Wynand will provide the GIF assets; use placeholders until then.
- **Level-up and title-unlock ceremonies:** what should they look like?
- **Fatigue progression:** should it be based on levels plus running consistency (the proposal above), or on cumulative distance milestones (e.g. 100/250/500/1000/2500km)?

## Data model (extend the existing models; migrate existing saved data)

- **WorkoutDay:** keep the existing fields and add `xpEarned` and `bonusAwarded`.
- **UserProgress:** add `totalXP`, `skillPoints`, `fatigueCurrent`, `fatigueMax`, `consecutiveMissedDays`, `lastActiveDate`, and `stats` (STR/VIT/AGI/INT/PER), plus per-level completion tallies for the stat-gain rule.
- **Derived values (compute, don't persist):** level, XP into the current level, title, HP, and MP.
- **Persistence:** stay with local storage (SharedPreferences). Write a migration so existing users' history converts cleanly to starting values.

## Implementation order

1. Disable the running button when it's toggled off, and add a test for it.
2. Build a pure Dart progression engine with no Flutter imports: the curve, XP awards, missed-day processing, protection, and stats. Unit-test it heavily.
3. Update the data model, persistence, and migration.
4. Add level, XP bar, and title to the main screen, plus floating XP-gain feedback.
5. Add a stats view (character sheet).
6. Add level-up and title-unlock moments, using placeholder animations.
7. Update `spec.md` to match.

## Acceptance criteria

- Unit tests cover:
  - the curve reaching level 100 in roughly 300–350 days at 500 XP/day
  - the 300 vs 500 XP days
  - the bonus requiring running
  - 6 consecutive misses not dropping a level, while 7 can
  - title derivation at every boundary
  - stat gains and the level-down penalty
- Skipping app opens for several days applies the correct penalties exactly once.
- Existing local data survives the upgrade.
- `flutter analyze` is clean, and `flutter build web --release` succeeds.

## Constraints and gotchas

- **Project location:** the Flutter project must stay at the repo root. A subfolder breaks Amplify CI, which happened with Junie.
- **Amplify build:**
  - Don't touch `amplify.yml` unless necessary.
  - It must use `wget`, because `curl` downloads came out truncated.
  - The Flutter version must match local, which is **3.29.3**.
  - There's no root or `yum` in the build image.
- **Git identity:** commits must be authored as `wpieters <me@wynandpieters.dev>`.
- **Stack:** use Riverpod for state, keep clean architecture (features/workout, progress, settings), and keep everything offline-first.
- **Scope:** don't add features beyond this document. A previous tool added unrequested features while core functionality stayed broken.

## Out of scope (future)

- Multiplayer and avatar battles
- The skill store
- The item store and gacha "AFK quests"
- Login and sync
- Notifications and widgets
- The "$1/day penalty" monetisation idea

---

## Outcome (2026-10-10)

Shipped in PR #1 on `feat/progression-system`. All seven implementation steps were completed, and every acceptance criterion passes.

**Answers to the open questions**
- Stat cap: **255** (hard cap), recorded in [ADR 0006](../adr/0006-stat-cap.md).
- Fatigue progression: **levels plus running consistency**, recorded in [ADR 0007](../adr/0007-fatigue-max-progression.md).
- Level-up and title ceremonies: a **full-screen Solo Leveling system popup**, recorded in [ADR 0008](../adr/0008-level-up-ceremony.md).
- Goku animation: **still open**. The paused React prototype (`dailyquest-anime-workout`) had no transformation POC, so the trigger (daily progress, level, or streak) is still undecided.

**Still to confirm**
- The proposed defaults are implemented but not yet signed off. They're recorded as *Proposed* in [ADR 0004](../adr/0004-missed-days-and-level-protection.md) and [ADR 0005](../adr/0005-stat-growth.md).

**Added beyond the brief, at Wynand's request**
- A Solo Leveling system-window restyle and minus (undo) buttons, ported from the React prototype. See [ADR 0009](../adr/0009-dark-system-window-design.md).
- An upgrade to Flutter 3.47.7 and the latest dependencies. See [ADR 0010](../adr/0010-toolchain-pin.md).

**Differences from the brief**
- `amplify.yml` had been deleted to stop the demo branches deploying. It was restored, pinned to Flutter 3.47.7, and PR #1 was retargeted from `vibe/claude-code` to `main`, which is now the only deployed branch. See [ADR 0011](../adr/0011-deploy-main-only.md).
- The code is organised by layer (`models/`, `providers/`, `screens/`) rather than by `features/` as the brief described. The new engine lives in `lib/progression/`, and nothing was restructured.
