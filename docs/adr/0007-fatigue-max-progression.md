# 7. Fatigue max grows with levels and running

- **Status:** Accepted
- **Date:** 2026-10-10
- **Source:** [Handoff 0001](../handoffs/0001-progression-system.md) (open question, answered by Wynand)

## Context
Fatigue starts at 7 and recovers by 1 a day, up to the maximum. The maximum should grow for users who run. The two options were growth tied to levels plus running consistency, or growth at cumulative distance milestones such as 100, 250 and 500 km.

## Decision
The fatigue maximum grows by **+1 for every 10 levels gained**, but only if running was completed on at least **50% of days** in that span. That gives a maximum of **17**. Each milestone can be earned only once, even after dropping a level and climbing back.

## Consequences
Fatigue is only tracked for now. It will be spent in multiplayer battles, which are out of scope.
