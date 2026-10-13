---
status: in-progress
date: 2026-10-13
branch: feat/power-up-sprites → main
pr:
adrs: [0013]
---

# HANDOFF: DailyQuest – Streak power-up with pixel sprites

## Context
DailyQuest is a Flutter PWA at https://dailyquest.duhblinn.xyz. The first completion of the day shows `CompletionAnimation` (`lib/widgets/completion_animation.dart`): a full-screen overlay with a gradient disc, a ⚡ glyph, dots and "DAILY QUEST COMPLETE!" text, coloured by `UserProgress.powerLevelTier`. It's functional but generic. [ADR 0013](../adr/0013-pixel-sprites-cc-by.md) decides to replace the centrepiece with a pixel-art hero from the Tiny RPG Battle Kit I pack (CC BY 4.0) and draw the tier aura around it.

Source pack on Wynand's machine: `~/tinyRPGBattleKit01_v2_0/`. Only the files listed below are copied into the repo.

## Goal
On the first completion of the day, the overlay shows the hero powering up, with the aura escalating by streak tier:

| Tier | Streak | Colour (`AppTheme`) | Look |
|---|---|---|---|
| 0 | 0 (first ever day) | `mutedForeground` | hero *victory* loop, soft grey glow |
| 1 | 1–7 | `primaryBlue` | blue aura: pulsing radial glow + rising particles |
| 2 | 8–30 | `powerYellow` | yellow aura, larger and faster; Fire sheet behind the hero, hue-shifted to gold |
| 3 | 31–100 | `powerRed` | Thunder sheet strikes the hero once, then electric arcs (Flutter-drawn) crackle around the aura |
| 4 | 100+ | `powerPurple` | silver-purple aura, Revive sparkle rows drifting around the hero, slow-motion feel |

The existing text ("DAILY QUEST / COMPLETE! / SUPER SAIYAN!") stays, below the hero. Total length stays around 2.5 s and it still ends by calling `onComplete`. `disableAnimations` shows the hero's last frame with a steady glow and no sheet effects.

## Assets to vendor (1x, keep original file names)
Under `assets/sprites/`, plus `assets/sprites/LICENSE.md` with the attribution.

| File (from pack) | Size | Layout |
|---|---|---|
| `battleChars/3fRMK_1x/sv_actors/20240926bundleFighter3f.png` | 648×432 | RPG Maker MV side-view actor: 9 columns × 6 rows of 72×72. Motion *m* is at row `m ~/ 3`, columns `(m % 3) * 3 .. +2`. Motions: 0 walk, 1 wait, 2 chant, 3 guard, 4 damage, 5 evade, 6 thrust, 7 swing, 8 missile, 9 skill, 10 spell, 11 item, 12 escape, **13 victory**, 14 dying, 15 abnormal, 16 sleep, 17 dead. MV plays 0-1-2-1 at roughly 5 fps for loops. |
| `VFX/RMK/animations/20221110bundleFireFX-Sheet.png` | 960×576 | 192×192 cells, 5 per row, row-major; 13 frames used, the rest blank |
| `VFX/RMK/animations/20221110bundleThunderFX-Sheet.png` | 960×576 | same grid; 11 frames used (one-shot) |
| `VFX/RMK/animations/20221110bundleReviveFX-Sheet.png` | 960×1344 | same grid; rows 0–3 are a 20-frame sparkle loop; rows 4–6 are a burst, not needed |

The VFX sheets are at RPG Maker's 1x already; there is no 2x version. The 2x actor sheets are plain upscales, so don't ship them. The Volt, Barrier, Haste and most other sheets are editor-composited fragments; leave them.

Check the exact used-frame counts against the PNGs before hard-coding them (the counts above are from eyeballing the sheets).

## Plan
1. **`SpriteAnimation` widget** (`lib/widgets/sprite_animation.dart`): takes an `ui.Image`, a `frameSize`, a list of source `Rect`s (or a grid + frame indices), `fps`, `loop`, `scale` and optional `ColorFilter`. Ticker-driven; paints with `canvas.drawImageRect` and `FilterQuality.none`. A `SpriteSheet` helper builds the frame lists for the two RPG Maker layouts above. Image loading via a `FutureProvider` or `precacheImage`, so the overlay never shows a blank frame; cache decoded images for the session.
2. **`PowerUpAura` painter**: the Flutter-drawn glow, particles and (tier 3) arcs, parameterised by tier colour. Lift the particle code out of `CompletionAnimation` and make it look intentional (radial burst from the hero's feet, rising, fading).
3. **Rewrite `CompletionAnimation`** to compose: dark gradient backdrop → effect sheet (tiers 2–4) → aura → hero → text. Hero at 4× (288 px) on phones, 3× when height < 700. Keep the `powerLevel` + `onComplete` API so `WorkoutScreen` doesn't change.
4. **Attribution**: `assets/sprites/LICENSE.md`; a "Hero sprites: Tiny RPG Battle Kit I by Gabriel 'tiopalada' Lima, CC BY 4.0" line in the Settings About card, linking to the licence. Register `assets/sprites/` in `pubspec.yaml`.
5. **Tests**: `SpriteSheet` frame-rect maths for both layouts (pure Dart); `SpriteAnimation` advances frames with `tester.pump`; `CompletionAnimation` still calls `onComplete` and respects `disableAnimations`; a golden is optional. Keep total under a second of pumped time per test.
6. Update `docs/spec.md` (animation section) and CLAUDE.md's "Animation Specifications" table if the tier look changes.

## Constraints
- Commits as `wpieters <me@wynandpieters.dev>`; Riverpod 3 `Notifier`; no new packages (no flame, no rive).
- Offline-first: sprites are bundled assets, never fetched.
- Web release build is the target: check `flutter build web --release` size delta (should be well under 500 KB) and that `FilterQuality.none` holds on CanvasKit and the HTML renderer path Amplify builds.
- Honour `MediaQuery.disableAnimations` as `GlowPulse` does.

## Open questions
- **Which hero?** Fighter is the default (red hair, fists: closest to the One Punch Man theme). The pack also has Healer, Mage and Noble; the sheet layout is identical, so it could later follow the character's title or be a setting.
- **Tier 3 colour**: `powerRed` is what the theme has, but "electric" reads better in white-blue. Keep red for the aura and draw the arcs in white, or change the theme colour?
- **Where else to show the hero?** A small idle-loop (motion 1 *wait*) on the Character screen would reuse the same widget for little cost. Not in scope unless cheap.

## Outcome
Implemented on `feat/power-up-sprites`.

- `lib/sprites/sprite_sheet.dart`: `SpriteSheet`, `SvActorSheet` (RPG Maker MV actor layout, `SvMotion` enum) and `RmmvAnimationSheet`, plus the `Sprites` catalogue with the used frame lists. Pure Dart, unit-tested.
- `lib/widgets/sprite_animation.dart`: `SpriteAnimation` (Ticker-driven, nearest-neighbour, optional `ColorFilter`, `animate: false` for reduced motion; one-shot effects paint nothing after they finish), `SpriteImages` cache with a test hook, and `hueRotate()`.
- `lib/widgets/power_up_aura.dart`: the Flutter-drawn glow, particles and tier-3 arcs.
- `lib/widgets/completion_animation.dart` rewritten around them; same `powerLevel`/`onComplete` API, so `WorkoutScreen` is unchanged. `main()` warms the sprite cache.
- Attribution in `assets/sprites/LICENSE.md` and the Settings About card. Bundle delta: 92 KB of PNG.
- Tests: 12 new (sheet maths, frame advance/loop/one-shot/still, overlay layering per tier, reduced motion, completion callback). 123 total.

**Found along the way**
- The exact used cells differ from the eyeballed counts: Fire uses cells 0,1,3,5–12 (flame body 6–9), Thunder 0,2–9,11, Revive 0–30. Blank cells inside a sequence are the artist's flicker and are played as blanks.
- Effect cells (192 px) at 3× are 576 px wide, so they sit in an `OverflowBox` over the hero's 288 px box rather than sizing the layout.
- A one-shot sheet that holds its last frame leaves Thunder's stray sparks on screen; `SpriteAnimation` now ends empty, as RPG Maker does.

**Open questions**: Fighter and `powerRed` with white arcs, as proposed. The idle hero on the Character screen is left for later.
