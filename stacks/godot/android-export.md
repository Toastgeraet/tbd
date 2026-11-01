# Godot — Android export

> **Status:** researched · **Last checked:** 2026-11-01, Godot 4.7.2 · **Proven in:** — (prerequisites inspected on Tobi's PC; nothing exported yet)

Nothing on this page has been run. Verify each step, and upgrade this file to
**proven** — with the pitfalls you hit — once an APK has actually run on a phone.

## Prerequisites

| Need | Notes |
| --- | --- |
| Android export templates | Part of the full template bundle. Installed via *Editor → Manage Export Templates*. |
| JDK | Godot documents **JDK 17**. 21 may work for a plain export but may break Gradle builds. |
| Android SDK | platform-tools, build-tools, a platform, cmdline-tools. An Android Studio install provides them. |
| Editor settings | *Editor Settings → Export → Android*: the Java SDK path and the Android SDK path. |
| Debug keystore | Godot generates one when needed. |

Checking a machine:

```bash
ls "$APPDATA/Godot/export_templates/4.7.2.stable/" | grep -i android || echo "no android templates"
java -version 2>&1 | head -1
echo "ANDROID_HOME=${ANDROID_HOME:-unset}"; ls "$LOCALAPPDATA/Android/Sdk"
ls "$LOCALAPPDATA/Android/Sdk/build-tools" "$LOCALAPPDATA/Android/Sdk/platforms"
```

On 2026-11-01, Tobi's PC had the SDK (build-tools 35 and 36, platform android-36,
`adb` under platform-tools but not on PATH) and Java 21, but **only web export
templates**.

## Steps

1. Install the Android templates.
2. Set both paths in Editor Settings.
3. *Project → Export → Add… → Android*.
4. On the phone, enable USB debugging (Developer options) and connect it. The
   Android button at the top right of the editor builds, installs and launches.
   Headless: `"$GODOT" --headless --path . --export-debug "Android" build/android/game.apk`.

### Play Store

- Needs an **`.aab`** rather than an `.apk`. That goes through the Gradle build:
  *Project → Install Android Build Template*, then enable *Use Gradle Build* in the
  preset. This is where the JDK version is most likely to matter.
- Needs a **release keystore**. Keep it and its passwords out of git.
- Check the store's current target API level requirement.

## What changes for a game built from these templates

- **The Android back button quits the app — even mid-game.** It does not trigger
  `ui_cancel`. `application/config/quit_on_go_back` defaults to on. Turn it off and
  handle `NOTIFICATION_WM_GO_BACK_REQUEST` (for example: game → menu, menu → quit
  confirmation).
- **"Quit to Desktop"** makes no sense on Android, where apps rarely have quit
  buttons. Hide it there (`OS.has_feature("android")`).
- **Touch works on menus without changes** — Godot turns taps into mouse events by
  default.
- **Controllers** work on Android too.
- **Notches and rounded corners** can cover edge-anchored UI, such as the
  right-hand menu column. Check the safe area (`DisplayServer.get_display_safe_area()`).
- **Renderer:** GL Compatibility maps to OpenGL ES 3, the widest device coverage.
