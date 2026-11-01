class_name PixelPlanetBaker
extends RefCounted

## Renders a planet once and hands back a plain [ImageTexture].
##
## A [PixelPlanet] keeps its shaders running every frame, which is what you
## want for a planet the player is looking at. For map pins, list icons or
## anything drawn many times over, bake it once and use the texture instead.
##
## [codeblock]
## var icon := await PixelPlanetBaker.bake(self, PlanetCatalog.Type.ICE_WORLD, 42)
## $TextureRect.texture = icon
## [/codeblock]
##
## Note that a [TextureRect] takes its minimum size from the texture by default,
## so set [member TextureRect.expand_mode] to
## [constant TextureRect.EXPAND_IGNORE_SIZE] to draw the result smaller.


## Renders [param type] with [param planet_seed] into a transparent texture of
## [param resolution] * relative_scale pixels square. [param host] just needs to
## be any node in the tree; the temporary viewport is freed before returning.
static func bake(
	host: Node,
	type: PlanetCatalog.Type,
	planet_seed: int,
	resolution: int = 100
) -> ImageTexture:
	var scene := PlanetCatalog.scene_for(type)
	if scene == null:
		push_error("No scene registered for planet type %d." % type)
		return null

	var planet: Control = scene.instantiate()
	var viewport := SubViewport.new()
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.add_child(planet)
	host.add_child(viewport)

	planet.set_seed(planet_seed)
	planet.set_pixels(resolution)

	# Rings and flares extend past the planet's own box, centred on it, so the
	# viewport has to cover the full extent or they get cropped.
	var extent := int(ceil(float(resolution) * planet.relative_scale))
	viewport.size = Vector2i(extent, extent)
	planet.position = Vector2.ONE * ((extent - resolution) * 0.5)

	# One frame to run the planet's _ready and lay the quads out, then wait for
	# the draw itself before the render target holds anything.
	await host.get_tree().process_frame
	await RenderingServer.frame_post_draw

	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	return ImageTexture.create_from_image(image)
