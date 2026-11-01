# Godot — new project

> **Status:** verified · **Last verified:** 2026-11-01, Godot 4.7.2 — a project scaffolded with exactly these commands imported cleanly, passed its tests, ran without errors or warnings, rendered the menu, and switched to the game scene on a simulated controller A press. The template files themselves are **proven** in cosmic-capitalist.

## Steps

```bash
GODOT="/c/Program Files/Godot/Godot_v4.7.2-stable_win64_console.exe"   # see README for other machines
T="$SKILL_DIR/stacks/godot/templates"   # SKILL_DIR: this skill's base directory, shown when it loads
DEST=~/Documents/<folder-name>
NAME="<Display Name>"

mkdir -p "$DEST" && cp -r "$T"/. "$DEST"/
cd "$DEST"
mv gitignore.txt .gitignore && mv gitattributes.txt .gitattributes && mv editorconfig.txt .editorconfig
sed -i "s/__PROJECT_NAME__/$NAME/g" project.godot scenes/main_menu/main_menu.tscn

"$GODOT" --headless --path . --import                          # registers class_name globals; must come first
"$GODOT" --headless --path . --script res://tests/run_all.gd   # exit 0, "OK -- N assertions passed."
"$GODOT" --headless --path . --quit-after 60                   # main menu loads; expect no ERROR/WARNING lines
```

Then, if the user agreed: `git init`, first commit, and the GitHub remote.

The result has **no icon**. The Project Manager would generate `icon.svg`; add one
and set `application/config/icon` before any export.

### Alternative: the user creates the project in the editor

Also proven — cosmic-capitalist started that way. The user picks **Compatibility**
as the renderer in the Project Manager, then you copy the templates on top. Keep
the generated `icon.svg`, and merge the template's `[gui]`, `[input]` and
`run/main_scene` into the generated `project.godot` rather than overwriting it.

### When the editor opens it

The editor re-saves files on first open: it adds `uid="…"` to scenes and resources,
`unique_id=…` to nodes, writes `.uid` files next to scripts, and may reorder
sub-resources or drop properties equal to their default. This is expected noise.
Commit it rather than fighting it. The `.uid` files belong in git.

## What the templates contain

| Path | What it gives you |
| --- | --- |
| `project.godot` | Compatibility renderer, main scene, theme, stretch settings, and the input fix below |
| `scenes/main_menu/` | Menu with buttons on the right: Continue (disabled), New Game, Load Game, Settings, Quit. Full keyboard and controller support |
| `scenes/game/` | Placeholder gameplay scene; Back button, and Esc / B returns to the menu |
| `ui/theme/main_theme.tres` | Project-wide theme (`gui/theme/custom`): dark translucent buttons with a left accent bar, distinct hover, focus, pressed and disabled styles |
| `tests/` | Dependency-free test harness — see [verification.md](verification.md#the-test-harness) |
| `tools/serve_web.py` | Local server for web builds — see [web-export.md](web-export.md) |
| `export_presets.cfg` | A `Web` preset exporting to `build/web/index.html` |
| `gitignore.txt` | `.godot/`, `/android/`, `/build/` |
| `gitattributes.txt`, `editorconfig.txt` | LF everywhere, UTF-8 |

## Layout

```
scenes/<screen>/   a scene and its script side by side
scripts/<area>/    reusable classes with no scene of their own (class_name)
assets/            art, audio, vendored third-party content
ui/theme/          the project theme
tests/             headless test suites
tools/             headless entry points: validators, dumps, scripted playtests
docs/              concept, specs, engine notes, playtest findings
build/             export output, gitignored
```

## Conventions

- Tabs, typed GDScript (`var cash: int = 0`, typed params and returns),
  `StringName` literals for actions (`&"ui_accept"`).
- `##` doc comments; comments say *why*, not what.
- `%UniqueName` for nodes a script reaches for, `$Path` otherwise.
- `@export_file("*.tscn")` for scene paths, and check the `Error` returned by
  `change_scene_to_file()`.
- `class_name` is global and process-wide. Avoid generic names (`System`, `Item`)
  that could collide with a future engine class. cosmic-capitalist renamed
  `System` to `StarSystem` for this reason.

## Input and focus

All **proven** in cosmic-capitalist and re-verified by the smoke test:

- **Godot 4.7's default `ui_accept` has no joypad binding** — only Enter, Keypad
  Enter and Space. `ui_up`, `ui_down`, `ui_left` and `ui_right` *do* have D-pad and
  stick bindings, so a controller can move focus but not press anything. The
  template's `[input]` section adds joypad A to `ui_accept` and B to `ui_cancel`.
- **Overriding a built-in action replaces it entirely.** The override has to
  re-list the keyboard events too.
- **Device ids in serialized events:** keyboard events are written with
  `device: 16`; `device: -1` means *all* joypads. `device: 0` would bind
  controller #1 only. Generate this text with `var_to_str(event)` in a probe
  rather than writing it by hand.
- **`disabled = true` does not stop focus landing on a button**, which strands
  controller users on a button that does nothing. Also set `focus_mode = FOCUS_NONE`
  (`_set_continue_enabled()` in the template does both).
- **Clicking empty space clears the focus owner**, after which a controller can't
  navigate. The template restores the last focused button on the next
  navigation input.
- Focus wraps around both ends of the column, and is recomputed when the set of
  focusable buttons changes.
- Hovering a button also focuses it, so the hover and focus highlights never sit
  on different buttons.

## Architecture for simulation-heavy games

**Proven** in cosmic-capitalist, from an empty repository to first playable:

- `sim/` is the whole model: `RefCounted` and `Resource` only. No `Node`, no
  signals to the UI, no `Engine` singletons, no `Time`. It must run under
  `--headless` with no scene tree. That is what makes tests and tuning harnesses
  possible.
- One owner object (`Run`) holds all state. It is a `RefCounted`, not an autoload,
  so a harness can create thousands of them.
- **One RNG**, owned by the model and seeded from a run seed. Nothing in `sim/`
  calls the global `randi()`/`randf()`. Same seed + same inputs = same run, with a
  test enforcing it.
- Commands are verbs returning result objects with `ok` and `reason: StringName`.
  The UI maps reason codes to text, and a test fails if a code has no text.
- Money and counts are integers, rounded at transaction time.
- Content lives in JSON under `content/`, validated at load time with loud errors
  that name the file, the key and the expected type.
- Every balance number lives in one `const` file, with comments saying which way
  each knob pushes.
- An append-only log of every state change doubles as an in-game ledger and a
  debugging tool. Retrofitting it later means touching every system.
- `ui/` builds `Control` screens in code from content, reads the model, and calls
  its commands. It never mutates state directly.

## Placeholder art

Procedural SVG generated by a small script works well as placeholder
backgrounds. **Godot's SVG rasteriser (ThorVG) does not support SVG filters**, so
use gradients, circles and paths only — no blur or glow filters.
