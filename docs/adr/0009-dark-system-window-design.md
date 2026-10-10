# 9. Dark-only Solo Leveling system-window design

- **Status:** Accepted
- **Date:** 2026-10-10

## Context
The Flutter app used colourful gradient buttons and followed the system light/dark setting, so it looked like a generic fitness app. The paused React prototype (`dailyquest-anime-workout`) had a much closer Solo Leveling look and quest-window wording.

## Decision
- The app is **dark-only**, with these colours:
  - background `#0F131A`
  - panels `#151C28`
  - cyan accent `#00AAFF`, with 30% borders
  - green, orange and red for complete, warning and danger
- Labels are uppercase with wide letter spacing, and counts are bracketed and monospace, like `[42 / 100]`.
- The main screen leads with a QUEST INFO window showing the goals, the "CAUTION! … PENALTIES WILL BE GIVEN ACCORDINGLY" line and the streak.
- The STATUS screen layout comes from the prototype.
- System windows have a pulsing glow, and each tap sets off a power-up ring. Both stay still when reduced motion is requested.
- Each exercise panel has a minus button to undo a mis-tap, following the XP rules in [ADR 0003](0003-xp-and-leveling-curve.md).

## Consequences
- There's no light theme anymore.
- The history and settings screens only picked up the new palette and weren't redesigned.
