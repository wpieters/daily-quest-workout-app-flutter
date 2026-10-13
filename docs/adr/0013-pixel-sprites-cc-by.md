# 13. Pixel-art hero and effects from Tiny RPG Battle Kit I (CC BY 4.0)

- **Status:** Proposed
- **Date:** 2026-10-13

## Context
The power-up sequence on daily completion ([spec](../spec.md), CLAUDE.md "Animation Specifications") is drawn entirely with Flutter primitives today: a spinning gradient disc, a ⚡ glyph and twenty dots. Wynand wants something with more character. Hand-drawing anime auras is out of scope, and no free aura sheet in his packs fits the tiers.

He owns **Tiny RPG - Battle Kit I v2.0** by Gabriel "tiopalada" Lima, licensed **CC BY 4.0**. It contains four heroes as RPG Maker MV side-view actor sheets (18 motions × 3 frames, 72×72 px cells at 1x) and 25 RPG Maker MV animation sheets (192×192 px cells, 5 per row). A handful of the effects (Fire, Thunder, Haste, the sparkle rows of Revive) are complete strip animations; the rest are fragments the RPG Maker editor composites, and are not usable as-is.

## Decision
- The daily-completion animation gets a **pixel-art hero** from this pack, playing its *victory* motion, with the **tier aura drawn in Flutter around it** (colour from `AppTheme.getPowerLevelColor`). Effect sheets from the pack may be layered for the higher tiers, hue-shifted at runtime with a `ColorFilter` matrix so one sheet serves several tiers.
- Only the sheets the app uses are vendored, under `assets/sprites/`, at **1x** and drawn with `FilterQuality.none` at an integer scale, so pixels stay crisp and the download stays small.
- **Attribution**, as CC BY 4.0 requires: `assets/sprites/LICENSE.md` (title, author, licence link, which files), a line in the Settings "About" card, and a note in this ADR. Files keep the pack's original names so they can be traced back.
- The pack's zip and unused sheets stay out of the repo.

## Consequences
- The repo now redistributes third-party art; CC BY permits that, including in a commercial app, as long as the credit stays. Removing the credit from the About card would be a licence breach.
- Sprite rendering needs a small `SpriteAnimation` widget (Ticker-driven `CustomPaint` of a sub-rect of the sheet). No new package.
- The RPG Maker MV layout is a de-facto standard, so other packs in the same format can be dropped in later (a different hero per title, enemies for a future boss mode) without new code.
