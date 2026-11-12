# 15. Opaque status strip for the iOS 26 PWA

- **Status:** Proposed
- **Date:** 2026-11-12

## Context
iOS 26 (and 27) changed how standalone web apps are drawn. With the old
`apple-mobile-web-app-status-bar-style` of `black`, Safari draws a blurred
strip across the top of the page, over the app's own content, and the layout
underneath shifts. The app bar background is `#0F131A`, the same as
`theme-color`, so nothing of ours wants to show through that strip anyway.

## Decision
Two changes in `web/index.html`, which only work together (each one alone
still blurs, tested on fresh installs elsewhere):

- `apple-mobile-web-app-status-bar-style` becomes `default`, so the web view
  starts below the status bar and iOS no longer composites over our content.
  `theme-color` stays the app bar colour.
- A real `<div id="ios-status-strip">` (not a `::before` pseudo-element) is
  fixed to the top of the page: opaque `#0F131A`, 12px tall, no
  `backdrop-filter`, `pointer-events: none`, above Flutter's view.

## Consequences
- The strip covers the top 12px of the Flutter view on every platform. The
  app bar is the same colour and has no content that high, so it's invisible.
  Any future design that puts something in the top 12px must account for it.
- The strip looks pointless in isolation. Don't remove it without re-testing
  a fresh install on iOS 26+.
- Status is Proposed until Wynand confirms the fix on a device.
