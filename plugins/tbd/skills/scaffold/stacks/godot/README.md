# Godot 4 game

> **Status:** proven (desktop, web export, headless tests, Android debug APK) · researched (Play Store, CI builds) · **Last verified:** 2026-11-01, Godot 4.7.2 stable · **Proven in:** cosmic-capitalist, rechen-trainer

2D and UI-heavy games in GDScript, run from the editor on Windows, exported to the
web or to Android, with a headless test suite Claude can run without the editor.

| Area | Status | File |
| --- | --- | --- |
| New project from templates | **verified** (smoke test 2026-11-01); templates **proven** in cosmic-capitalist | [new-project.md](new-project.md) |
| Headless verification, probes, tests | **proven** | [verification.md](verification.md) |
| GDScript and engine gotchas | **proven** | [gdscript-gotchas.md](gdscript-gotchas.md) |
| Web export and local serving | **proven** | [web-export.md](web-export.md) |
| Android export, wireless one-click deploy | **proven** (debug APK); Play Store **researched** | [android-export.md](android-export.md) |
| Claude cloud sessions | **proven** (edit, import, tests, probes, screenshots); CI builds **researched** | [cloud-and-ci.md](cloud-and-ci.md) |
| Portrait mobile screens, translations | **proven** | [new-project.md](new-project.md#portrait-mobile-apps) |
| Recipe: procedural pixel planets | **proven** | [recipes/pixel-planets/README.md](recipes/pixel-planets/README.md) |
| Recipe: 2D physics play area inside a UI screen | **proven** | [recipes/physics-subviewport/README.md](recipes/physics-subviewport/README.md) |

## Choose it when

- The game is 2D, menu- or UI-heavy, a simulation, a management or trading game.
- Desktop, browser or Android phones are the targets.
- Logic should be testable headless — Godot runs GDScript with no window.

Be careful when:

- **3D** — nothing here has been tried in 3D.
- **C# / .NET** — untried, and it complicates the web export and cloud builds.
  Every proven path here is GDScript only.

## Defaults that worked, and why

| Choice | Why |
| --- | --- |
| Godot **4.7.2 stable** | Current at the time. Scenes from 4.2 projects import fine. |
| **GL Compatibility** renderer | Web export requires it. It also has the widest Android device support, and it is the renderer most likely to work under software OpenGL in a GPU-less cloud container. |
| **GDScript only** | No .NET build step, so exports and cloud builds stay simple. |
| Jolt physics | The 4.7 Project Manager default; harmless when unused. |
| Stretch `canvas_items` + aspect `expand` | Handles any window and phone aspect ratio. **But** it resamples the whole canvas: pixel art smears at non-native sizes. Consider `viewport` stretch mode for pixel-art games. |
| Typed GDScript, tabs, LF | Matches Godot's formatter and catches errors at parse time. |

## Questions to ask

- Targets: desktop only, + web, + Android? Debug APKs are proven; Play Store
  release is researched only — say so.
- Portrait (phone app) or landscape? See [new-project.md](new-project.md#portrait-mobile-apps).
- Does it read the accelerometer or other sensors? They are **off** by default.
- Controller support? The templates include it; keep or drop.
- Is it simulation-heavy? Then adopt the `sim/` + `ui/` split and headless tests
  from [new-project.md](new-project.md#architecture-for-simulation-heavy-games)
  from day one, and consider the [spec-driven increments](../../reference/spec-driven-increments.md) process.
- Pixel art? Decide the stretch mode now; it is painful to change later.
- Will cloud sessions work on it? See [cloud-and-ci.md](cloud-and-ci.md).

## New project — short version

Copy `templates/` into the new folder, rename the dotfiles, replace
`__PROJECT_NAME__`, then import, test, and run. Full steps and what each template
contains are in [new-project.md](new-project.md).

## Environment — Tobi's Windows PC (as of 2026-11-01)

| Thing | Value |
| --- | --- |
| Godot console build (prints to stdout) | `/c/Program Files/Godot/Godot_v4.7.2-stable_win64_console.exe` |
| Export templates | `%APPDATA%\Godot\export_templates\4.7.2.stable\` — full bundle incl. Android (installed 2026-11-01) |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk` (build-tools 35, 36; platform android-36; `adb` not on PATH) |
| Java | 21 on PATH; JDK 17 (Temurin) installed for Android and set in Editor Settings |
| Shells | Git Bash and Windows PowerShell 5.1 |

## Pitfalls that cost the most time

Details in the linked files. These each burned real time:

1. **Edited an asset, game still shows the old one** — game mode never re-imports.
   Run `--headless --import`. ([verification.md](verification.md))
2. **"Identifier not declared in the current scope" for a new `class_name`** — needs
   that re-import too.
3. **A headless script "hangs" with no output at all** — a runtime error before
   `quit()`; stdout stays buffered. Read stderr first.
4. **Controller A does nothing on a focused button** — Godot 4.7's default
   `ui_accept` has no joypad binding. The templates fix it. ([new-project.md](new-project.md#input-and-focus))
5. **Web build shows a black page** — single-threaded dev server deadlocked.
   Use `templates/tools/serve_web.py`. ([web-export.md](web-export.md))
6. **Shaking the phone does nothing** — sensors are disabled by default in 4.7
   (`input_devices/sensors/enable_accelerometer`). ([android-export.md](android-export.md#pitfalls))
