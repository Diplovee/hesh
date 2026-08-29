# Android backend (planned)

As of Hesh **0.1.3**, Android support is intentionally not implemented in
Phase 1. No QEMU, KVM,
ADB, APK, image, or snapshot code belongs in this directory yet.

The future backend should introduce an `AndroidDevice` implementation of the
base `Device` contract. Its runtime boundary is expected to look like:

```text
AndroidDevice
    ↓
AndroidRuntime
    ↓
QEMU
    ↓
KVM
```

The runtime will own process lifecycle, image selection, CPU/RAM/storage
configuration, ADB connectivity, and snapshots. `DeviceManager` should remain
agnostic to those details.
