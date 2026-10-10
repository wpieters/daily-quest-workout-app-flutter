# 5. Stat growth and derived stats

- **Status:** Proposed. Implemented, awaiting confirmation.
- **Date:** 2026-10-10
- **Source:** [Handoff 0001](../handoffs/0001-progression-system.md) (locked rules, plus proposed defaults 4 to 7)

## Context
These rules were locked by the handoff:
- Strength comes from push-ups, Vitality from sit-ups and Agility from squats.
- Stats grow with level, not with reps.
- Intelligence and Perception grow only through skills and items.
- Each level grants 3 skill points.

The exact numbers were left as proposals.

## Decision
- All stats start at **10**.
- On a level-up, Strength, Vitality or Agility gains **+2** if its exercise was completed on at least **50%** of the days spent at the previous level. The day of the level-up counts with whatever has been completed so far that day.
- On a level-down, Strength, Vitality and Agility each lose **5 per level lost**, but never drop below **10**.
- HP is Vitality × 10, and MP is Intelligence × 5. Both are derived, never stored.
- *Implementation choice, unconfirmed:* skill points are granted only the first time a level is reached, and they aren't removed on a level-down. This stops users from dropping a level and climbing back to earn the points again.

## Consequences
- Training consistently reaches about 208 in each stat by level 100, which leaves room under the [cap](0006-stat-cap.md) for future items.
- Skill points are stored but can't be spent until the skill store exists.
