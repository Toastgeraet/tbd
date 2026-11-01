# Godot — GDScript and engine gotchas

> **Status:** proven · **Last verified:** 2026-11-01, Godot 4.7.2 · **Proven in:** cosmic-capitalist

Each one was hit for real. Symptom first.

## Typing

- **"Trying to assign an array of type "Array"" at runtime.** `Dictionary.keys()`
  and bare `[value]` literals are untyped `Array`s. Assigning them to an
  `Array[String]` passes the parser and throws at runtime — inside `_initialize`
  that looks like a silent hang. Build typed arrays by appending.
- **`Array[Inner]` doesn't work for an inner class.** Typed arrays need a globally
  registered class: make it a top-level `class_name` (`CargoLot`, not `Cargo.Lot`).
- **"argument 2 should be "Side" but is "MarketQuote.Side""** — an enum declared in
  one `class_name` script does not unify with itself when another script names it.
  Use typed `const`s across script boundaries (`MarketQuote.BUY`), and keep enums
  for use inside one script.
- **`if value is SomeEnum` fails.** Enums are ints; compare or range-check.
- **`var x := planet.relative_scale` fails to infer** when `planet` is typed as
  `Control` and the property lives on an untyped script. Write
  `var x: float = planet.relative_scale`.

## Closures

- **A lambda that assigns an outer local doesn't change it.** Lambdas capture by
  value. Append to a shared `Array` (or mutate an object) instead.

## UI and layout

- **A long label silently widens its whole container past the window.** Unclipped
  `Label`s report their full text as minimum width. Use `clip_text = true` plus
  `SIZE_EXPAND_FILL` for any label whose text comes from content.
- **"Nodes with non-equal opposite anchors will have their size overridden after
  _ready()"** — code is setting `size` on a control with stretching anchors. Give
  it explicit offsets and no stretching anchors if code sizes it.
- **A scaled control jumps off position.** Scaling happens around `pivot_offset`.
  Zero it before scaling (`pivot_offset = Vector2.ZERO`).
- **A `TextureRect` refuses to draw smaller than its texture.** It takes its
  minimum size from the texture by default; set
  `expand_mode = EXPAND_IGNORE_SIZE`.
- **Disabled buttons still take controller focus.** Set `focus_mode = FOCUS_NONE`
  as well (see [new-project.md](new-project.md#input-and-focus)).

## Engine behaviour

- **The global RNG is seeded randomly at startup** in Godot 4 — no `randomize()`
  needed. Four consecutive runs produced four different results. For determinism,
  use a seeded `RandomNumberGenerator` rather than the globals.
- **`await` helpers that render need a node in the tree** — baking a texture
  through a `SubViewport`, for example, waits for frames. They cannot run from a
  pure model layer, and bulk use should be sequential and cached.
- **Scenes in the old `format=2`** (Godot 3 syntax, `ExtResource( 4 )`) still turn
  up in "Godot 4" downloads. Rewrite them as `format=3` when importing.
