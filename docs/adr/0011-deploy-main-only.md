# 11. Deploy only `main` through Amplify

- **Status:** Accepted
- **Date:** 2026-10-10

## Context
The `vibe/*` branches were built for a blog post comparing three coding-agent harnesses (Claude Code, Junie and Warp). Each branch deployed to its own Amplify preview. Once the comparison was finished, `amplify.yml` was deleted from `vibe/claude-code` and `vibe/warp-dev` on 2025-08-06 to stop those deploys. `main` held only the spec and prompt, so nothing was deployed at all.

## Decision
`main` is the app's branch from now on. The Claude Code implementation, together with the progression system, is merged into `main` through PR #1. `amplify.yml` is restored at the repo root. The Amplify app builds and deploys `main` only, to https://dailyquest.duhblinn.xyz. Auto-build is turned off for the `vibe/*` branches, and they're left as an archive of the comparison.

## Consequences
- Feature branches get no preview deploys unless one is connected in the Amplify console by hand.
- The build steps live in `amplify.yml`, in the repo, so the Flutter version is pinned alongside `pubspec.yaml` (see [ADR 0010](0010-toolchain-pin.md)).
- The `vibe/*` branches keep their history but don't receive any further changes.
