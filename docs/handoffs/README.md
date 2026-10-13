# Agent Handoffs

Task briefs given to agents, numbered like ADRs (see [ADR 0001](../adr/0001-record-decisions-and-handoffs.md)). Any decisions a handoff makes are also recorded as ADRs.

Each handoff starts with this frontmatter:

```yaml
---
status: open | in-progress | done | superseded
date: YYYY-MM-DD
branch: feature-branch → target-branch
pr: <link, once opened>
adrs: [NNNN, ...]
---
```

When the work ships, add an **Outcome** section at the end. It should cover what shipped, how the open questions were answered, and any differences from the brief.

| # | Handoff | Status |
|---|---|---|
| [0001](0001-progression-system.md) | Progression system (XP, levels, titles, stats) | done |
| [0002](0002-reminders.md) | Daily Quest reminders (Web Push + AWS) | done |
| [0003](0003-power-up-sprites.md) | Streak power-up with pixel sprites | in-progress |
