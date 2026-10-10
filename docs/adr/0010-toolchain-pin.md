# 10. Pin the Flutter toolchain, and match it in Amplify

- **Status:** Accepted
- **Date:** 2026-10-10

## Context
Earlier, an Amplify build failed because CI used a different Flutter version from local development.

## Decision
`pubspec.yaml` requires **Dart ^3.13** and **Flutter >=3.47.0**, and Flutter 3.47.7 is used locally. `amplify.yml` downloads that same Flutter 3.47.7 release. Dependencies track their latest major versions: `flutter_riverpod` 3, `vibration` 3, `flutter_lints` 6 and `cupertino_icons` 2.

## Consequences
- A build that uses an older Flutter fails immediately with a clear version error, rather than with confusing compile errors.
- When the local Flutter version changes, update the SDK URL in `amplify.yml` in the same commit. Downloads in the build must use `wget`, because `curl` produced truncated files.
