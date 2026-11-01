# Recipe — procedural pixel planets

> **Status:** proven · **Last verified:** 2026-09, Godot 4.7.2 · **Proven in:** cosmic-capitalist

Deep-Fold's **Pixel Planets** (MIT): 12 shader-generated planet types — terran,
islands, ice, lava, gas giants (with and without rings), asteroid, black hole,
galaxy, star. They contain no image files, so each planet costs one draw call and
no texture memory, any seed gives a new world, and they stay crisp at any size.

Source: <https://github.com/Deep-Fold/PixelPlanets>, or the itch.io download
(<https://deep-fold.itch.io/pixel-planet-generator>). On Tobi's PC a copy is at
`C:\Users\Tobi\Documents\PixelPlanets`. It targets Godot 4.2.

This folder holds the **wrapper scripts** (`planet_catalog.gd`, `pixel_planet.gd`,
`pixel_planet_baker.gd`), copied from cosmic-capitalist. The shaders themselves
come from upstream.

## Import

```bash
SRC=~/Documents/PixelPlanets          # the upstream project
DST=assets/pixel_planets
mkdir -p "$DST" && cp -r "$SRC/Planets/." "$DST/" && cp "$SRC/LICENSE" "$DST/"
rmdir "$DST/Moon" 2>/dev/null || true                       # empty upstream folder
grep -rl 'res://Planets/' "$DST" | xargs sed -i 's|res://Planets/|res://assets/pixel_planets/|g'
mkdir -p scripts/planets && cp "$SKILL_DIR"/stacks/godot/recipes/pixel-planets/*.gd scripts/planets/
```

Then two fixes to the vendored copy:

1. **`Planet.tscn` is still Godot 3 `format=2`.** Rewrite it as `format=3`:
   one `ext_resource` for `Planet.gd`, and a `Control` root with the same anchors,
   offsets, `custom_minimum_size` and size flags.
2. **`Galaxy/Galaxy.tscn`:** its `ColorRect` has full-rect anchors, so
   `set_pixels()` can't size it. Godot warns about the overridden size, and the
   galaxy renders at the wrong size. Replace `anchor_right/anchor_bottom = 1.0`
   with `offset_right/offset_bottom = 100.0`.

Add a `README.md` to `assets/pixel_planets/` listing these changes, then run
`--headless --import` — the wrapper classes need it to register.

Leave out the generator's `GUI/` folder and its `HTML5FileExchange` addon; they
are only needed to run the generator itself.

## Use

Never reference the vendored scenes directly; go through the wrappers.

```gdscript
var world := PixelPlanet.new()
world.type = PlanetCatalog.Type.ICE_WORLD
world.planet_seed = 42
world.display_size = 96.0          # full extent, rings included
add_child(world)
world.set_disc_size(360.0)         # or: size by the body, rings draw outside

var icon := await PixelPlanetBaker.bake(self, PlanetCatalog.Type.GAS_GIANT, 7)
```

- `PlanetCatalog` — the `Type` enum, `scene_for()`, `display_name()`,
  `all_types()`, `random_type(rng, pool)` (pass a seeded RNG for determinism) and
  `HABITABLE_TYPES`.
- `PixelPlanet` (`Control`) — a live planet: `type`, `planet_seed`, `resolution`
  (shader pixels across, 100 upstream), `display_size`, `light_origin`, `tilt`,
  `set_disc_size()`, `randomize_colors()`.
- `PixelPlanetBaker.bake()` — **async**: it renders through a `SubViewport` and
  needs a host node in the tree. For many icons, bake sequentially and cache by
  `(type, seed)`. Display the result with `expand_mode = EXPAND_IGNORE_SIZE`.

## Pitfalls

- **Ringed and flaring types look tiny next to plain planets.** `relative_scale`
  (3 for the ringed giant, 2 for the star and black hole) reserves room for rings
  inside the same box. Use `set_disc_size()` so every body is the same size.
- **Gas Giant or Star sits off-centre when scaled.** Upstream left a
  `pivot_offset = (100, 100)` on them. `PixelPlanet` zeroes it before scaling.
- **A planet looks flat or smeared in a screenshot.** The window was smaller than
  the base resolution and the canvas was resampled. It is not the shader — see
  [verification.md](../../verification.md) trap 7.
