# Godot — verifying without the editor

> **Status:** proven · **Last verified:** 2026-11-01, Godot 4.7.2 · **Proven in:** cosmic-capitalist, rechen-trainer, plus the 2026-11-01 template smoke test

The user usually runs the game from the editor. Claude checks its own work
headlessly instead, so it does not have to ask the user to click around.

## Commands

On Windows use the `_console` build — the plain `.exe` prints nothing to the
terminal.

| Purpose | Command |
| --- | --- |
| Import assets, register `class_name` globals | `"$GODOT" --headless --path . --import` |
| Catch script and scene errors at startup | `"$GODOT" --headless --path . --quit-after 60` |
| Run the test suite | `"$GODOT" --headless --path . --script res://tests/run_all.gd` |
| Run a headless tool with arguments | `"$GODOT" --headless --path . --script res://tools/x.gd -- arg1 arg2` |
| Run one scene | `"$GODOT" --path . res://path/scene.tscn` |

## The test harness

`templates/tests/` is a dependency-free harness, proven over a dozen suites in
cosmic-capitalist:

- `run_all.gd` extends `SceneTree`. It preloads every suite in a `const` dictionary,
  so a suite that fails to compile is a loud startup error rather than one that
  silently stops running. It prints one line per suite and exits 0 or 1.
- `test_case.gd` (`class_name TestCase`) has `test(name)`, `ok`, `not_ok`, `eq`,
  `ne`, `close`, `greater` and `less`. Failures print as `suite / test: message`.
- A suite is a `RefCounted` with `run(t: TestCase)`. Register new suites in
  `SUITES`.

GUT can be added later; nothing needs it.

## Probe scenes

For anything that needs the engine running — screenshots, reading engine
defaults, simulated input, generating config text:

1. Write a throwaway `_probe/probe.tscn` and `_probe/probe.gd`.
2. Run it in the background with a timeout, logging to a file (see below).
3. Delete `_probe/` afterwards. Never commit it.

```bash
"$GODOT" --path . --resolution 1152x648 res://_probe/probe.tscn > probe.log 2>&1 &
PID=$!
for i in $(seq 1 30); do kill -0 $PID 2>/dev/null || break; sleep 1; done
kill -9 $PID 2>/dev/null; grep -v '^\[' probe.log
```

Useful techniques:

- **Screenshot** (non-headless only — headless renders nothing):
  `await RenderingServer.frame_post_draw`, then
  `get_viewport().get_texture().get_image().save_png(path)`. `save_png` accepts
  absolute OS paths, so write straight to a scratch directory.
- **Introspection:** `InputMap.action_get_events(&"ui_accept")`, focus
  neighbours, default property values — check, don't assume.
- **Simulated input:** `Input.parse_input_event(event)`. Send the **press and the
  release** — buttons fire `pressed` on release by default.
- **Config text:** `var_to_str(event)` prints version-exact text for the
  `[input]` section of `project.godot`.
- **Pass parameters through environment variables** (`OS.get_environment("SHOT")`)
  to run one probe several ways.

### A probe that walks through several screens

**proven** in rechen-trainer, where it produced menu → picker → game → answer →
result screenshots in one run. The probe scene can't drive the flow itself
(trap 5 below), so on start it hands over to a driver node under `root`, which
survives `change_scene_to_file()`:

```gdscript
extends Node  # _probe/shots.gd, attached to _probe/shots.tscn

func _ready() -> void:
	if get_parent() != get_tree().root or name != "Driver":
		var driver: Node = load("res://_probe/shots.gd").new()
		driver.name = "Driver"
		get_tree().root.add_child.call_deferred(driver)
		return
	_run.call_deferred()

func _shot(file: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT_DIR + file + ".png")

func _run() -> void:
	var tree := get_tree()
	tree.change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
	for i in 20: await tree.process_frame
	await _shot("1_menu")
	tree.current_scene.call("_on_some_button_pressed")  # drive handlers directly
	# … more steps …
	tree.quit()
```

Calling the screen's `_on_*_pressed` handlers directly is quicker than simulating
clicks, at the cost of skipping the input layer.

### Fast headless physics probes

**verified** (rechen-trainer): headless physics runs in real time by default, so
100 shakes × ~4 s of settling ran into a 300 s timeout. `--fixed-fps 60` steps
the engine as fast as the CPU allows, keeping 60 steps per simulated second:

```bash
"$GODOT" --headless --fixed-fps 60 --path . --script res://_probe/stats.gd
```

Drive it from a `SceneTree` script: add the physics node to `root`, then
`await physics_frame` in a loop. Print a distribution (sorted results, min/max,
settle times) rather than one run. Tuning by single runs misled twice here.

### Screenshots on Linux without a display

**proven** in a Claude cloud container (CPU only): `xvfb-run` was preinstalled,
and GL Compatibility rendered correctly in software.

```bash
xvfb-run -a -s "-screen 0 720x1280x24" "$GODOT" --path . --resolution 720x1280 res://_probe/shots.tscn > shots.log 2>&1
```

The ALSA errors and "All audio drivers failed, falling back to the dummy driver"
in the log are harmless.

## Traps

Each of these cost real time. Symptom first.

1. **You edited an asset and the game still shows the old one.** Game mode never
   re-imports; it serves `.godot/imported/`. Run `--headless --import` after
   touching any imported file (`.svg`, `.png`, audio…). In cosmic-capitalist, a
   planet removed from a background SVG kept rendering, hidden only by chance
   behind the new one.
2. **"Identifier "X" not declared in the current scope" for a class you just
   created.** New `class_name` globals are registered by the import step. Re-import.
3. **A headless run prints nothing at all and never exits.** A runtime error
   happened before `quit()` (in `_initialize`, or in a probe's coroutine). The tree
   idles forever with stdout still buffered, so you don't even see the engine
   banner. It looks like an infinite loop in your code. Look at stderr first
   (`2>&1 >/dev/null`). `--check-only` will not catch it — it is a runtime error,
   not a parse error.
4. **Piping Godot into `grep` or `head` shows nothing until it exits** — and if it
   never exits, the tool call times out. Redirect to a file and poll the PID
   instead, as above.
5. **A probe hangs right after switching scenes.** The probe *is* the current
   scene, so `change_scene_to_file()` frees it and kills its coroutine before
   `quit()`. Put the driving logic in a node added to `get_tree().root`, which
   survives scene changes ([example](#a-probe-that-walks-through-several-screens)).
   Knowing this trap didn't stop a later session (rechen-trainer) from hitting it
   again: copy the example rather than rewriting it.
6. **A simulated button press does nothing.** Only the press was sent; buttons act
   on release (`ACTION_MODE_BUTTON_RELEASE`). Send both.
7. **Screenshots look smeared or flat.** With `stretch/mode="canvas_items"`, a window
   smaller than the base size (default 1152×648) resamples the whole canvas. A
   correct pixel-art planet showed up as a flat disc. Pass `--resolution 1152x648`.
8. **A typed `var x := node.prop` fails to parse** when `node` is typed as a base
   class and `prop` lives on an untyped script. Annotate it explicitly:
   `var x: float = node.prop`.
9. **A new script has no `.uid` file yet.** The import step generates it. Commit it.

## Browser-based checks

Driving the web build in a browser is a poor verification tool. Godot renders to
a single `<canvas>`, so the accessibility tree is just "Your browser does not
support the canvas tag" and there is nothing to click by reference. In-app browser
screenshots also time out while the app window is minimised. Verify in-engine with
probes, and use the browser only for "does it load".
