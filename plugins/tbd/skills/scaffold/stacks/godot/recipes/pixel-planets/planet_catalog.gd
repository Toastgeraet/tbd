class_name PlanetCatalog
extends RefCounted

## Registry of the vendored Deep-Fold pixel planet scenes.
##
## The scenes themselves live in `res://assets/pixel_planets/` and keep their
## upstream layout, so they can be re-synced from the original project. Address
## them through this catalog rather than by path, so the paths only exist here.

enum Type {
	TERRAN_WET,
	TERRAN_DRY,
	ISLANDS,
	NO_ATMOSPHERE,
	GAS_GIANT,
	GAS_GIANT_RINGED,
	ICE_WORLD,
	LAVA_WORLD,
	ASTEROID,
	BLACK_HOLE,
	GALAXY,
	STAR,
}

const _SCENES := {
	Type.TERRAN_WET: preload("res://assets/pixel_planets/Rivers/Rivers.tscn"),
	Type.TERRAN_DRY: preload("res://assets/pixel_planets/DryTerran/DryTerran.tscn"),
	Type.ISLANDS: preload("res://assets/pixel_planets/LandMasses/LandMasses.tscn"),
	Type.NO_ATMOSPHERE: preload("res://assets/pixel_planets/NoAtmosphere/NoAtmosphere.tscn"),
	Type.GAS_GIANT: preload("res://assets/pixel_planets/GasPlanet/GasPlanet.tscn"),
	Type.GAS_GIANT_RINGED: preload("res://assets/pixel_planets/GasPlanetLayers/GasPlanetLayers.tscn"),
	Type.ICE_WORLD: preload("res://assets/pixel_planets/IceWorld/IceWorld.tscn"),
	Type.LAVA_WORLD: preload("res://assets/pixel_planets/LavaWorld/LavaWorld.tscn"),
	Type.ASTEROID: preload("res://assets/pixel_planets/Asteroids/Asteroid.tscn"),
	Type.BLACK_HOLE: preload("res://assets/pixel_planets/BlackHole/BlackHole.tscn"),
	Type.GALAXY: preload("res://assets/pixel_planets/Galaxy/Galaxy.tscn"),
	Type.STAR: preload("res://assets/pixel_planets/Star/Star.tscn"),
}

const _DISPLAY_NAMES := {
	Type.TERRAN_WET: "Terran (Wet)",
	Type.TERRAN_DRY: "Terran (Dry)",
	Type.ISLANDS: "Islands",
	Type.NO_ATMOSPHERE: "No Atmosphere",
	Type.GAS_GIANT: "Gas Giant",
	Type.GAS_GIANT_RINGED: "Ringed Gas Giant",
	Type.ICE_WORLD: "Ice World",
	Type.LAVA_WORLD: "Lava World",
	Type.ASTEROID: "Asteroid",
	Type.BLACK_HOLE: "Black Hole",
	Type.GALAXY: "Galaxy",
	Type.STAR: "Star",
}

## Types that read as an ordinary colonisable world, for when a random planet
## should not turn out to be a black hole.
const HABITABLE_TYPES: Array[Type] = [
	Type.TERRAN_WET,
	Type.TERRAN_DRY,
	Type.ISLANDS,
	Type.ICE_WORLD,
]


static func scene_for(type: Type) -> PackedScene:
	return _SCENES.get(type)


static func display_name(type: Type) -> String:
	return _DISPLAY_NAMES.get(type, "Unknown")


static func all_types() -> Array[Type]:
	var result: Array[Type] = []
	for type in _SCENES:
		result.append(type)
	return result


## Picks a random type. Pass a seeded [RandomNumberGenerator] to keep galaxy
## generation reproducible; omit it to use the global RNG.
static func random_type(rng: RandomNumberGenerator = null, pool: Array[Type] = []) -> Type:
	var types := pool if not pool.is_empty() else all_types()
	if rng != null:
		return types[rng.randi() % types.size()]
	return types[randi() % types.size()]
