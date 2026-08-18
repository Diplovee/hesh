# Android backend

Hesh can launch an existing Android SDK AVD and manage its lifecycle. The
backend does not bundle Android system images; those remain installed and
licensed through the Android SDK.

The runtime boundary is:

```text
AndroidDevice
    ↓
AndroidRuntime
    ↓
Android SDK emulator
    ↓
QEMU/KVM
```

`AndroidRuntime` owns emulator process lifecycle, boot polling through ADB,
scrcpy display startup when available, Android key events, rotation, and APK
installation. `AndroidDevice` exposes that runtime through the common `Device`
contract while `DeviceManager` remains responsible for collection ownership and
persistence.

## Local prerequisites

- Android SDK platform-tools (`adb`)
- Android SDK emulator package (`emulator`)
- At least one existing AVD
- `scrcpy` for an interactive mirrored display; without it, the emulator's own
  window is used instead

The backend searches `PATH`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`,
`~/Android/Sdk`, and `~/.android/sdk`.

For the complete Omarchy/Arch installation and verification steps, see
[`docs/ANDROID_SETUP.md`](../../docs/ANDROID_SETUP.md).
