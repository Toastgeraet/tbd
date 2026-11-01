class_name PixelPlanet
extends Control

## A live, animated pixel planet.
##
## Wraps the vendored Deep-Fold planet scenes behind a small API: choose a
## [enum PlanetCatalog.Type], give it a seed, and it renders itself to exactly
## fill a [member display_size] square. Rotation is animated by the shader, so
## an instance costs one draw call and no per-frame script work of ours.
##
## The planets are generated on a [member resolution]-pixel grid and then scaled
## up, so [member display_size] can be any value without losing crispness --
## the shader posterises in UV space, it is not sampling a texture.

## Which planet scene to build. See [PlanetCatalog].
@export var type: PlanetCatalog.Type = PlanetCatalog.Type.TERRAN_WET:
	set(value):
		if type == value:
			return
		type = value
		if is_node_ready():
			_rebuild()

## Chooses the terrain. Any int works; the planet scripts fold it into the
## 0-10 range their noise expects.
@export var planet_seed: int = 0:
	set(value):
		planet_seed = value
		if _planet != null:
			_planet.set_seed(planet_seed)

## Pixel-art detail level, i.e. how many shader pixels across the planet is.
## Upstream's generator uses 100.
@export_range(10, 400, 1) var resolution: int = 100:
	set(value):
		value = maxi(value, 1)
		if resolution == value:
			return
		resolution = value
		if is_node_ready():
			_rebuild()

## On-screen size of the square the planet occupies. This covers the whole
## visual extent, so rings, flares and accretion discs are included rather
## than clipped -- see [method disc_size] for the planet body alone.
@export var display_size: float = 128.0:
	set(value):
		display_size = maxf(value, 0.0)
		_apply_layout()

## Where the light comes from, in the planet's 0-1 UV space. Ignored by the
## types that light themselves (star, galaxy, black hole).
@export var light_origin: Vector2 = Vector2(0.39, 0.39):
	set(value):
		light_origin = value
		if _planet != null:
			_planet.set_light(light_origin)

## Tilt of the planet's axis, in radians.
@export_range(0.0, 6.28318, 0.01) var tilt: float = 0.0:
	set(value):
		tilt = value
		if _planet != null:
			_planet.set_rotates(tilt)

var _planet: Control = null


func _ready() -> void:
	_rebuild()


## The instantiated upstream planet node, for the shader parameters this
## wrapper does not surface. Null until the node is ready.
func get_planet_node() -> Control:
	return _planet


## Size of the planet body itself, excluding rings and flares. Use this when
## laying out labels or hit areas against the visible disc.
func disc_size() -> float:
	if _planet == null:
		return display_size
	var relative_scale: float = _planet.relative_scale
	return display_size / relative_scale


## Sizes the planet by its body instead of its full extent, so that different
## types read as the same size. Rings and flares then draw outside this node's
## box rather than being shrunk to fit inside it.
func set_disc_size(pixels: float) -> void:
	if _planet == null:
		return
	var relative_scale: float = _planet.relative_scale
	display_size = pixels * relative_scale


## Replaces the palette with a generated one. The upstream schemes are tuned
## per planet type, so results stay plausible.
func randomize_colors() -> void:
	if _planet != null:
		_planet.randomize_colors()


func _rebuild() -> void:
	if _planet != null:
		_planet.queue_free()
		_planet = null

	var scene := PlanetCatalog.scene_for(type)
	if scene == null:
		push_error("No scene registered for planet type %d." % type)
		return

	_planet = scene.instantiate()
	add_child(_planet)
	# Order matters: set_pixels() resizes the shader quads, so it has to run
	# before we measure the planet to lay it out.
	_planet.set_seed(planet_seed)
	_planet.set_pixels(resolution)
	_planet.set_light(light_origin)
	_planet.set_rotates(tilt)
	_apply_layout()


func _apply_layout() -> void:
	custom_minimum_size = Vector2(display_size, display_size)
	if _planet == null:
		return
	# Types with rings or flares draw past their own box, by `relative_scale`,
	# centred on it. Scale the whole extent into `display_size` and shift it
	# back so the visual bounds start at this node's origin.
	# `relative_scale` lives on the untyped upstream Planet.gd, so it needs
	# spelling out before it can take part in typed arithmetic.
	var relative_scale: float = _planet.relative_scale
	var extent := float(resolution) * relative_scale
	if extent <= 0.0:
		return
	var factor: float = display_size / extent
	# Two of the upstream scenes carry a stray pivot_offset from the generator's
	# own GUI. That never mattered there because it sized its viewport instead
	# of scaling the node, but scaling around it would push the planet off-box.
	_planet.pivot_offset = Vector2.ZERO
	_planet.scale = Vector2(factor, factor)
	_planet.position = Vector2.ONE * ((extent - float(resolution)) * 0.5 * factor)
