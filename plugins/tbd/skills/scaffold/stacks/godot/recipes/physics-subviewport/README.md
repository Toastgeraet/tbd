# Recipe — a 2D physics play area inside a UI screen

> **Status:** proven · **Last verified:** 2026-11-01, Godot 4.7.2 · **Proven in:** rechen-trainer (shake box with marbles, portrait Android)

The case: a `Control`-based screen (labels, buttons, containers) with a box in
the middle where `RigidBody2D`s tumble around, and the box has to fit any phone
width and still look sharp.

## The pattern

Simulate in a `SubViewport` of fixed size. Scale only the *rendering*, through
the viewport's `canvas_transform`, and show the result in a `TextureRect` that
lives in the normal container layout.

```
ShakeBoxGame (Control)
├─ …containers… └─ BoxArea (TextureRect, expand_mode=1, stretch_mode=5 keep-aspect-centered)
└─ BoxViewport (SubViewport, size 1400×1040, transparent_bg, render_target_update_mode=4)
   └─ ShakeBox (Node2D, physics in local units; draw size 700×520)
```

```gdscript
func _setup_box_viewport() -> void:
	var render_scale := float(_box_viewport.size.x) / ShakeBox.DRAW_SIZE.x  # 2.0
	_box_viewport.canvas_transform = Transform2D(0.0, Vector2.ONE * render_scale, 0.0,
			Vector2(_box_viewport.size) / 2.0)
	_box_area.texture = _box_viewport.get_texture()
```

Why it's built this way:

- **No scaled parent above the rigid bodies.** Physics runs in unscaled units,
  so gravity, impulses and speed caps keep the same meaning on every screen.
  Godot's docs warn against scaling physics bodies. That warning is the reason;
  the failure itself was not reproduced here (*researched*).
- **`canvas_transform` affects drawing only**, not physics, so a viewport twice
  the logical size renders at double resolution. Without it the box blurs on
  1080p phones, where `canvas_items` stretch upscales the 720-wide UI.
- **A SubViewport has its own `World2D`**, so the box's bodies can't collide with
  anything else on the screen.
- **Input doesn't reach it** through the `TextureRect`. That was fine here,
  because buttons and the accelerometer drive the box. For direct touch, use a
  `SubViewportContainer` instead.

## Shaking bodies convincingly

From tuning with a headless probe (100 shakes per setting, see
[verification.md](../../verification.md#fast-headless-physics-probes)):

- **A random impulse per body barely moves a pile.** Marbles resting against
  each other cancel each other's sideways kicks. Give all bodies **one shared
  sideways jolt** (the box moving under them) plus a little scatter per body.
  Crossings went from ~0 to a good spread.
- **Check the launch speed against obstacle height**: `v = sqrt(2·g·h)`. With
  default 2D gravity (980 px/s²), clearing a 175 px wall needs ~590 px/s of lift.
  Lower walls and sloped sides beat stronger kicks, which tunnel.
- **Damping stands in for rolling resistance.** Without it, round bodies roll
  on a flat floor for seconds. `linear_damp = 0.6` and `angular_damp = 4` brought
  the settle time down to ~4 s.
- **Detect "settled" by speed, not `sleeping`**: every body below ~15 px/s for
  0.5 s, with a timeout (4.5 s) as a fallback. Count bodies by position only
  after that.
- **Thick walls** (80 px slabs), `continuous_cd = CCD_MODE_CAST_SHAPE` and a
  speed cap in `_integrate_forces` kept every body inside the box over hundreds
  of shakes.
- **Draw the cover over hidden bodies as a separate `Node2D` with a higher
  `z_index`.** Fading its `modulate.a` reveals what's underneath.

Source of truth: `scenes/shake_boxes/` in the rechen-trainer repository.
