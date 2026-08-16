# Android runtime setup

Hesh launches an existing Android SDK AVD. It does not bundle the Android
Emulator or a system image.

The Android runtime is locked by default in Hesh 0.2.1 to avoid starting a
resource-intensive emulator on machines with limited memory. To explicitly
enable it for a capable host, configure the build with:

```bash
cmake -S . -B build -DHESH_ENABLE_ANDROID=ON
cmake --build build --parallel 2
```

Leave that option off for the normal lightweight build.

## Omarchy/Arch Linux

Install the Arch packages that provide ADB and the optional mirrored display:

```bash
sudo pacman -S --needed android-tools scrcpy
```

Install Android Studio, or install the Android SDK Command-line Tools and the
SDK packages manually. In Android Studio's SDK Manager, install:

- Android SDK Command-line Tools
- Android Emulator
- Android SDK Platform-Tools
- One Android system image

Create an AVD in Android Studio's Device Manager. The name shown there is the
exact name to enter in Hesh.

## Command-line SDK setup

The SDK root used by Hesh is normally `~/Android/Sdk`. For Fish, make the tools
available in new terminals with:

```fish
set -Ux ANDROID_HOME $HOME/Android/Sdk
fish_add_path -U $ANDROID_HOME/platform-tools
fish_add_path -U $ANDROID_HOME/emulator
fish_add_path -U $ANDROID_HOME/cmdline-tools/latest/bin
```

The package names for system images vary by installed SDK release. List the
available packages first, then install a matching image:

```fish
sdkmanager --list | rg 'system-images;android'
sdkmanager --licenses
sdkmanager "platform-tools" "emulator" "system-images;android-35;google_apis;x86_64"
avdmanager create avd -n Pixel_7_API_35 -k "system-images;android-35;google_apis;x86_64"
```

If the selected API/image is unavailable, use the exact package ID printed by
`sdkmanager --list` instead.

## Verify before launching Hesh

```fish
adb version
emulator -list-avds
emulator -accel-check
```

`emulator -accel-check` should report usable KVM. Then run Hesh, choose
**New Device → Android Device**, and enter the exact AVD name. The default ADB
serial `emulator-5554` is correct for the first emulator instance.

`scrcpy` is optional. When installed, Hesh starts it for interactive display;
otherwise the Android Emulator's own window is used.

Official references:

- <https://developer.android.com/tools/sdkmanager>
- <https://developer.android.com/tools/avdmanager>
- <https://developer.android.com/studio/run/emulator-commandline>
- <https://developer.android.com/studio/run/emulator-acceleration>
