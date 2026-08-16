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
        └── AndroidDevice [future]
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
`WebDevice` adds its URL and owns the web-device lifecycle boundary. The model
uses roles backed by actual `Device` objects, rather than two hardcoded device
slots or a large collection of QVariant maps.

Phase 1 supports the Web type. Android records are deliberately not created or
emulated yet; the future type can be added without changing the manager's
collection, selection, or model APIs.

## Profiles

`DeviceProfile` is a value type for logical viewport width and height, device
pixel ratio, and user agent. The built-in catalog includes Pixel 7, Pixel 8,
iPhone 14, Galaxy S24, iPad, Desktop, and Custom.

The web content's logical viewport is kept separate from its visual scale.
`DeviceFrame` gives `WebEngineView` the selected profile's logical dimensions,
then scales the containing frame down to fit the workspace. Scaling the QML
item therefore changes presentation size without changing the website's CSS
viewport.

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

Standalone windows should be implemented as a separate QML window host that
binds to the same `Device` object, not by coupling runtime behavior to
`DeviceWorkspace.qml`.

## Future Android runtime

The intended future boundary is:

```text
AndroidDevice
      ↓
AndroidRuntime
      ↓
QEMU
      ↓
KVM
```

`AndroidRuntime` will eventually own QEMU process lifecycle, KVM detection,
image selection, CPU/RAM/storage configuration, ADB connectivity, APK
installation, and snapshots. None of those capabilities are present in Phase
1, and `src/android/README.md` is documentation only.
