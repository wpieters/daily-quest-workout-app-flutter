# 1. Record decisions and agent handoffs in `docs/`

- **Status:** Accepted
- **Date:** 2026-10-10

## Context
Agents do much of the work on this project, and the handoff briefs they're given can contain product decisions. Before this, handoffs lived in an untracked `handoff.md` at the repo root. Their decisions were lost once a task finished.

## Decision
- Architecture and product decisions are recorded as ADRs in `docs/adr/NNNN-slug.md`, using Status, Context, Decision and Consequences.
- Task briefs for agents are recorded in `docs/handoffs/NNNN-slug.md`. Each starts with frontmatter (`status`, `date`, `branch`, `pr`, `adrs`) and ends with an **Outcome** section once the work ships.
- Any decision that appears in a handoff is also captured as an ADR. The handoff links to the ADR, which then outlives the task.
- The living product spec is `docs/spec.md`.
- ADR statuses are `Proposed`, `Accepted` and `Superseded by NNNN`. Handoff statuses are `open`, `in-progress`, `done` and `superseded`.

## Consequences
- Agents should read `docs/adr/` and any open handoff before starting work. `CLAUDE.md` points them there.
- Numbers are never reused. A superseded ADR stays in place, with its status changed to name its replacement.
