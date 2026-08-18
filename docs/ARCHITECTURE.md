# Hesh architecture

Hesh keeps the QML presentation layer separate from the C++ application and
device infrastructure.

```text
QML UI
   ↓ context properties and QObject properties
Application
   ├── Settings
   └── DeviceManager
          ↓ QAbstractListModel + selectedDevice
       Device
        ├── WebDevice
        └── AndroidDevice
```

## Application ownership

`Hesh::Application` owns one `Settings` instance and one `DeviceManager`.
`DeviceManager` owns the dynamically created `Device` objects through Qt
parent ownership. QML receives the manager and reads its model; it does not own
or maintain the canonical device collection.

`Settings` is a small replaceable boundary over `QSettings`. It serializes the
device list as compact JSON in one settings value, plus the selected device id.
This keeps persistence out of QML and leaves room for a database or project
file later.

## Device model

`Device` contains identity, type, lifecycle status, and display profile data.
`WebDevice` adds URL, orientation, runtime/navigation state, persistent browser
profile identity, and presentation state. The model uses roles backed by actual
`Device` objects, rather than two hardcoded device slots or a large collection
of QVariant maps.

Web and Android records share the same collection, selection, lifecycle, and
persistence APIs. Android-specific emulator configuration remains on
`AndroidDevice` and `AndroidRuntime` rather than leaking into the base model.

## Profiles

`DeviceProfile` is a value type for logical viewport width and height, device
pixel ratio, and user agent. The built-in catalog includes Pixel 7, Pixel 8,
iPhone 14, Galaxy S24, iPad, Desktop, and Custom.

The web content's logical viewport is kept separate from its visual scale.
`DeviceFrame` gives `WebEngineView` the selected profile's logical dimensions,
then scales the containing frame down to fit the workspace. Scaling the QML
item therefore changes presentation size without changing the website's CSS
viewport. Rotation swaps the logical dimensions before the WebEngine view is
laid out, so landscape is a real `915 × 412` viewport for Pixel 7 rather than a
pixel rotation.

## Web runtime and profiles

Each WebDevice lazily owns one `QQuickWebEngineProfile`. Its storage and cache
paths are derived from the stable device id:

```text
<AppDataLocation>/profile/<device-id>/
```

The profile uses persistent cookies, disk cache, local storage, IndexedDB, and
the selected profile's user-agent. Two devices therefore cannot accidentally
share authentication state. The profile object is shared by the embedded and
standalone visual hosts.

The QML layer reports WebEngine loading, navigation, render-process failure,
and page URL changes back to WebDevice through invokable runtime methods. It
does not own the canonical device collection or persistence.

## Presentation boundary

The current presentation is embedded in the main workspace. The device model
does not depend on that workspace. A future presentation layer can route a
device to either of these hosts:

```text
Device
   ↓
Presentation
   ├── Embedded
   └── Standalone
```

`DeviceManager::openStandalone(deviceId)` and
`DeviceManager::returnToEmbedded(deviceId)` are the presentation boundary.
The manager changes the device's presentation state and emits a device-scoped
request. `Main.qml` creates or destroys one `StandaloneDeviceWindow` for that
id; there is no global device window. The standalone host is a real Qt Quick
`Window`, so Hyprland sees it as a separate client that can be moved,
minimized, or placed on another workspace.

The same `WebEngineView` instance is not reparented between Qt Quick windows.
Qt WebEngine's cross-window reparenting behavior is not relied on for this
runtime boundary. Instead the embedded host is destroyed while detached and a
new host is created in the native window, using the same per-device profile and
the C++ canonical URL. This preserves cookies, localStorage, IndexedDB,
authentication, profile, orientation, UA, and device identity. In-memory page
JavaScript state and scroll position are not guaranteed across the switch.

When a device is detached, the main workspace renders a restrained return
message and does not keep a second active WebEngine view behind the native
window. Closing the native window calls `returnToEmbedded`; removing a detached
device first returns its presentation state and then removes the device.

The normal standalone client is intentionally view-only: it is a frameless Qt
window containing only the logical device viewport, fitted to the available
desktop height by default while preserving the device aspect ratio.
There is no standalone bezel, device-name strip, toolbar, label, footer, or
minimum-size padding. Rotate, scale, fit-to-desktop, DevTools, Return, and
Close actions are available through a small Hesh-styled right-click context
menu so the web surface remains clear.
The requested scale is clamped to the current screen's desktop-available
geometry, which excludes reserved Waybar, dock, and panel areas. Exact 25%,
50%, 75%, 100%, and 125% presentation scales remain available from the
context menu.

On Hyprland, standalone windows use a hidden `Hesh Device <width>x<height>`
title token and the user-scoped `~/.config/hypr/hesh.lua` rule matches that
title independently of the main Hesh shell. It makes the client floating,
resizes it to the requested device geometry inside the compositor's reserved
bar/dock area, and leaves the user's normal Hyprland border style visible.
Hyprland still owns workspace and monitor movement.

DevTools are device-scoped: each frame connects its own page view to its own
DevTools view, so inspecting one device does not retarget another device.

## Android runtime

The intended future boundary is:

```text
AndroidDevice
      ↓
AndroidRuntime
      ↓
Android SDK emulator
      ↓
QEMU/KVM
```

`AndroidRuntime` owns the SDK emulator process lifecycle, boot polling through
ADB, scrcpy display startup, Android key events, rotation, and APK installation.
Hesh expects the system image and AVD to be provisioned through the Android SDK;
it does not bundle images or snapshots.

## Performance notes

The implementation keeps one WebEngine profile per WebDevice and one visible
WebEngine view per presentation. A detached device does not leave an active
embedded view rendering behind it. Qt WebEngine itself remains the dominant
memory consumer; exact RSS depends on Chromium subprocesses, page content, GPU
backend, and compositor. Measure RSS with the app's actual page set when
comparing idle, one-device, two-device, and detached-device cases.
