# Godot — Android export

> **Status:** proven (debug APK, one-click deploy over wireless adb, sensors, back button) · researched (Play Store, release signing, Gradle builds) · **Last verified:** 2026-11-01, Godot 4.7.2, JDK 17, Windows 11 → Xiaomi phone · **Proven in:** rechen-trainer

A portrait game built from these templates in a cloud session was exported on
Tobi's PC, installed over wireless debugging with the editor's Remote Deploy
button, and ran correctly: touch, accelerometer shake, back button.

## Prerequisites

| Need | Notes |
| --- | --- |
| Android export templates | **proven:** a machine with only the *web* templates gives "No export template found at the expected path: …/4.7.2.stable/android_debug.apk". *Editor → Manage Export Templates → Download and Install* fetches the full bundle (~1.2 GB) including Android. |
| JDK 17 | **proven:** `winget install EclipseAdoptium.Temurin.17.JDK`. Java 21 was not tried. |
| Android SDK | **proven:** an Android Studio install (`%LOCALAPPDATA%\Android\Sdk`, build-tools 35/36, platform android-36) was enough. |
| Editor settings | *Editor Settings → Export → Android*: **Java SDK Path** (`C:\Program Files\Eclipse Adoptium\jdk-17.<ver>-hotspot`) and **Android SDK Path**. |
| Debug keystore | **proven:** Godot generated it by itself once the JDK path was set; no `keytool` needed. |

Checking a machine:

```bash
ls "$APPDATA/Godot/export_templates/4.7.2.stable/" | grep -i android || echo "no android templates"
java -version 2>&1 | head -1
ls "$LOCALAPPDATA/Android/Sdk/build-tools" "$LOCALAPPDATA/Android/Sdk/platforms"
```

## Project settings an Android game needs

Put these in `project.godot` up front (the template has the first one):

```ini
[rendering]
textures/vram_compression/import_etc2_astc=true

[application]
config/quit_on_go_back=false          ; then handle NOTIFICATION_WM_GO_BACK_REQUEST

[input_devices]
sensors/enable_accelerometer=true     ; only if the game reads sensors
sensors/enable_gravity=true

[display]
window/handheld/orientation=1         ; portrait; 0 = landscape
```

## Export preset

A hand-written minimal preset in `export_presets.cfg` is accepted. The editor
fills in every missing option on first open, which shows up as a large diff of
`export_presets.cfg`. Commit it. The keys that matter:

```ini
[preset.1]
name="Android"
platform="Android"
runnable=true
export_path="build/android/<name>.apk"

[preset.1.options]
gradle_build/use_gradle_build=false
architectures/arm64-v8a=true
version/code=1
version/name="0.1.0"
package/unique_name="de.toastgeraet.<name>"
package/name="<Display Name>"
```

Exporting: *Project → Export… → Android → **Export Project…***, with *Export With
Debug* ticked. *Export PCK/ZIP…* writes only the game data, not an app. Unticking
debug needs a release keystore.

Next to the APK, `apksigner` writes `<name>.apk.idsig`. That is the APK Signature
Scheme v4 file for `adb install --incremental`. Don't ship it.

## Pitfalls

Symptom first.

1. **"Target platform requires 'ETC2/ASTC' texture compression. Enable 'Import
   ETC2 ASTC' to fix."** in the export dialog → `import_etc2_astc` is off by
   default → set it (above), or click *Show Project Setting*.
2. **"The project name does not meet the requirement for the package name format
   and will be updated to …"** → the package name is derived from the project
   name, and "Rechen-Trainer" has a hyphen → set *Package → Unique Name*
   explicitly. Only a warning; the export still works.
3. **Shaking the phone does nothing; `Input.get_accelerometer()` is
   `Vector3.ZERO`** → Godot 4.7 ships with
   `input_devices/sensors/enable_accelerometer=false` (also gravity, gyroscope,
   magnetometer) → enable the sensors you read. Found by dumping
   `ProjectSettings.get_property_list()`; the fix then worked on the phone.
4. **The Android back button quits the app, even mid-game** →
   `quit_on_go_back` defaults to on and does not raise `ui_cancel` → turn it
   off and handle `NOTIFICATION_WM_GO_BACK_REQUEST` in each screen's
   `_notification()`. proven: game → menu, menu → quit.
5. **`git pull` refuses: "You have unstaged changes" in `project.godot` and
   `export_presets.cfg`** → the editor re-saves both on open: it reorders keys
   and fills preset defaults → check `git diff`. Reordering is noise
   (`git restore`). Keep the preset defaults (`git pull --autostash`) and
   commit them.
6. **A Xiaomi phone (MIUI/HyperOS) wants a Xiaomi account before the editor can
   install** → Xiaomi gates *Developer options → Install via USB* behind a
   signed-in account, and adb installs need it even over Wi-Fi → sign in once.
   proven on one phone. The exact error text wasn't recorded.

## One-click deploy over wireless debugging

**proven.** Android 11+, phone and PC on the same Wi-Fi.

1. Phone: *Developer options → Wireless debugging* → on → *Pair device with
   pairing code* (shows IP:port and a 6-digit code).
2. PC: `& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" pair <ip>:<pair-port>`
3. PC: `adb connect <ip>:<port>`, using the port on the main *Wireless debugging*
   screen, which differs from the pairing port. Repeat this step whenever
   wireless debugging restarts; pairing is remembered.
4. Editor: the **Remote Deploy** button is the fourth icon at the top right, after
   Play, Pause and Stop. Its menu lists the phone; picking it exports, installs
   and launches.

Use the `adb.exe` from the SDK path set in Editor Settings. A different adb
version kills the editor's adb server.

Remote Deploy builds into the editor's cache with remote-debug settings that
connect back to the PC. For an APK to share (a GitHub Release, for example), use
*Export Project…*.

## What changes for a game built from these templates

- **"Quit to Desktop"** makes no sense on Android. Hide it there
  (`OS.has_feature("android")`). *researched*
- **Touch works on menus without changes.** Taps arrive as mouse events by
  default. **proven**
- **Notches and rounded corners** can cover edge-anchored UI. Check
  `DisplayServer.get_display_safe_area()`. *researched*
- **Renderer:** GL Compatibility maps to OpenGL ES 3, the widest device coverage.

## Not yet done

- **Play Store**: needs an `.aab` through the Gradle build (*Project → Install
  Android Build Template*, *Use Gradle Build*) and a release keystore kept out of
  git. Check the store's current target API level requirement.
- **Release signing.** An APK signed with one machine's debug key only updates
  over an install signed with that same key. Switching keys later means
  uninstalling first.
- **Building the APK in a cloud session or CI.** See [cloud-and-ci.md](cloud-and-ci.md).
