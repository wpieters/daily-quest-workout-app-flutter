# 6. Stat cap of 255

- **Status:** Accepted
- **Date:** 2026-10-10
- **Source:** [Handoff 0001](../handoffs/0001-progression-system.md) (open question, answered by Wynand)

## Context
The handoff asked whether stats should have a hard cap of 255, or a cap of 999 with items and consumables able to push stats past what leveling gives.

## Decision
Stats have a **hard cap of 255**, set by `ProgressionConfig.statCap`.

## Consequences
Leveling alone reaches about 208, so future items have roughly 47 points of headroom.
