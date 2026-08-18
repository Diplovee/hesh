# Web device rendering invariants

This document records the coordinate-system rules for web devices. Keep these
rules intact when changing `DeviceFrame.qml` or
`StandaloneDeviceWindow.qml`; a small geometry change can make a page look
correct in a browser screenshot while appearing shifted in the desktop window.

## The two coordinate systems

`WebDevice::logicalViewportWidth` and `logicalViewportHeight` are the device's
CSS viewport. They describe the page, not the size of the Hesh window.

- Embedded previews keep `WebEngineView` at the logical viewport size and apply
  the presentation scale to the complete QML surface.
- Standalone windows use the physical-surface path. The WebEngine surface is
  presented at the selected scale and its zoom factor preserves the logical
  CSS viewport.

Both paths must keep the page viewport logical. Do not use the host window
width to make the page appear to fit.

## Standalone alignment rule

In a standalone window, `window.devicePixelRatio` can differ from the QML
screen DPR because Qt WebEngine renders a fractional backing texture. Hesh
reads the page DPR after navigation and applies `webContentOffset` as a
compositor-only x translation. While a navigation is still loading, Hesh
estimates the page DPR from screen DPR × WebEngine zoom so the loading and
error overlays are aligned immediately; transient `about:blank` readings are
ignored.

The `WebEngineView` width must remain exactly `contentSurface.width`. Do not
change it to `parent.width + webContentOffset`, and do not change the page's
CSS or add a page-level margin to compensate. Increasing the WebEngine width
changes `window.innerWidth`, causes responsive layouts to re-center against the
wrong viewport, and produces the characteristic right-shifted standalone
screen.

The `webCompositorOffsetFactor` is deliberately named and documented in
`DeviceFrame.qml`. If Qt, the Wayland scale, or the monitor changes, recalibrate
it only after verifying the CSS viewport first.

## Safe rendering checks

When investigating a future alignment regression:

1. Capture the standalone window and confirm the device surface itself is
   centered.
2. Inspect the page with DevTools and check that `window.innerWidth` and
   `window.innerHeight` equal the device's logical viewport.
3. Check a centered DOM element with `getBoundingClientRect()`; its center
   should be half of the CSS viewport.
4. If those values are correct but the desktop screenshot is shifted, adjust
   only the compositor offset path. Do not edit the web app's CSS.
5. Recheck the embedded preview after every standalone change; the embedded
   path must keep `physicalWebSurface: false`.

For a remote-debug session during local diagnosis:

```bash
QTWEBENGINE_CHROMIUM_FLAGS=--no-sandbox \
QTWEBENGINE_REMOTE_DEBUGGING=9222 ./build/hesh
```

Use the standalone window and a page screenshot for visual confirmation, then
run the normal build and Qt tests before committing. The remote-debugging
environment variable is for diagnosis only and is not required by Hesh.
