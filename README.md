# Hesh

Current version: **0.1.1**

Hesh is a lightweight Linux desktop environment for developing and testing
web devices, with a future path to real Android virtual devices. It is a
native Qt 6 application: QML owns presentation while modern C++ owns
application state, device lifecycle, profiles, and persistence.

## Phase 1 status

Implemented:

- Native frameless Qt Quick desktop window with Linux-friendly window actions
- Custom Hesh dark developer-tool visual system
- Dynamic C++ `DeviceManager` and `QAbstractListModel`
- Web devices with built-in viewport profiles
- Create-device flow with an explicit Android “Coming later” state
- Embedded Qt WebEngine web-device preview
- Embedded Chromium DevTools with a persistent dark appearance
- Logical viewport sizing kept separate from visual workspace scaling
- QSettings-backed persistence for devices and selected device
- Isolated, persistent cookies, local storage, IndexedDB, and disk cache per web device
- Hardware-accelerated preview rendering with responsive loading and error states
- Core Qt Test coverage for creation, removal, selection, profiles, and persistence

Not implemented yet:

- Android devices, QEMU, KVM, ADB, APK installation, images, or snapshots
- Standalone native device windows
- Full browser navigation toolbar and advanced developer-tool hosting controls
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

Qt WebEngine is enabled in Phase 1 because the first Web Device is functional
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

Web-device metadata is stored through `QSettings`. Browser state is isolated by
device id under the platform application-data and cache directories; generated
Chromium data is never written into the source tree.

On a Wayland compositor such as Hyprland, the application uses a frameless
Qt Quick window and calls the compositor's system move operation for titlebar
dragging. XWayland remains available through Qt's normal platform handling.

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

Prove the browser runtime boundary further, add navigation and host controls,
and allow a device to be presented in its own native window without changing
`DeviceManager`.

### Phase 3 — QEMU/KVM Android runtime prototype

Only after the device and presentation abstractions are proven, add a small
Android runtime prototype around QEMU/KVM. That phase should establish process
lifecycle and image contracts before ADB, APK, and snapshot features expand
the scope.
