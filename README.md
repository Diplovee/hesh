# Hesh

Hesh is a lightweight Linux desktop environment for developing and testing
web devices, with a future path to real Android virtual devices. It is a
native Qt 6 application: QML owns presentation while modern C++ owns
application state, device lifecycle, profiles, and persistence.

## Phase 2 status

Implemented:

- Native frameless Qt Quick desktop window with Linux-friendly window actions
- Custom Hesh dark developer-tool visual system
- Dynamic C++ `DeviceManager` and `QAbstractListModel`
- Web devices with built-in viewport profiles
- Create-device flow with an explicit Android “Coming later” state
- Embedded Qt WebEngine web-device preview
- Logical viewport sizing kept separate from visual workspace scaling
- QSettings-backed persistence for devices and selected device
- Compact navigation, URL, zoom, fit, rotation, and DevTools controls
- Per-device persistent WebEngine profiles for cookies, storage, cache, and UA
- Device-scoped standalone native Qt windows with return-on-close behavior
- Raw-viewport standalone clients with no device bezel or label, fitted to the
  available desktop work area, with a right-click Hesh context menu for controls
- Core Qt Test coverage for URL normalization, orientation, presentation lifecycle,
  profile identity, deletion while detached, and persistence

Known limitations:

- Android devices, QEMU, KVM, ADB, APK installation, images, or snapshots
- Live JavaScript/page-memory preservation across a presentation switch; the
  current Qt Quick implementation recreates the visual WebEngineView and
  restores the URL against the same persistent profile
- Qt WebEngine user-agent changes apply to the shared profile and are followed
  by a reload; pages that cache UA-dependent behavior may need a new navigation
- Wayland compositor workspace assignment remains compositor-controlled;
  Hyprland's Hesh rule floats and centers standalone clients while preserving
  their native device dimensions
- Project-local configuration or remote device management

## Requirements

- Linux
- CMake 3.24 or newer
- A C++20 compiler
- Qt 6.5 or newer with these modules:
  - Core
  - Gui
  - Quick
  - QuickControls2
  - WebEngineQuick
  - Test

Qt WebEngine is enabled because the Web Device runtime is functional
and needs an actual embedded browser surface.

## Build and run

From the Hesh project directory:

```bash
cmake -B build -S .
cmake --build build -j
./build/hesh
```

Run the core tests with:

```bash
ctest --test-dir build --output-on-failure
```

The executable is `build/hesh` with the current CMake configuration.

On a Wayland compositor such as Hyprland, the application uses a frameless
Qt Quick window and calls the compositor's system move operation for titlebar
dragging. XWayland remains available through Qt's normal platform handling.

The active Hyprland integration is kept in `~/.config/hypr/hesh.lua`. It
matches only the hidden `Hesh Device <width>x<height>` title token and opens
those clients as floating windows while inheriting the normal Hyprland
decoration and window border. The rule also clamps the requested viewport to
the compositor's reserved Waybar, dock, and panel area.

## Architecture

```text
QML UI
   ↓
Application
   ├── Settings
   └── DeviceManager
          ↓
       Device
        ├── WebDevice
        └── AndroidDevice [future]
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for ownership, persistence,
logical viewport scaling, presentation hosts, and the planned Android runtime
boundary.

## Roadmap

### Phase 2 — Web Device Runtime + standalone windows

Implemented in this checkout. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
for the runtime/profile/presentation decisions.

### Phase 3 — QEMU/KVM Android runtime prototype

Only after the device and presentation abstractions are proven, add a small
Android runtime prototype around QEMU/KVM. That phase should establish process
lifecycle and image contracts before ADB, APK, and snapshot features expand
the scope.
