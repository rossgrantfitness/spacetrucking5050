class_name PSXView
extends SubViewportContainer
## Shows the 3D world the way a 1997 PlayStation would: drawn small (about
## 240 rows of pixels), squeezed down to the PS1's 32 shades per color with a
## fine dither pattern, then blown up to fill the window with chunky,
## unsmoothed pixels.
##
## HOW TO USE: put the whole 3D world inside this node's "Viewport" child.
## Menus, the HUD and text stay OUTSIDE it (in CanvasLayers), so they're drawn
## at full resolution and stay easy to read.
##
## It also sets the "wobbly verts" and "swimming textures" strengths that
## every 3D model's shader reads (see res://shaders/psx.gdshaderinc).
## All the knobs are in res://data/tuning.tres, under "PS1 look".


const POST_SHADER := preload("res://shaders/psx_post.gdshader")

@onready var viewport: SubViewport = $Viewport

var _post := ShaderMaterial.new()


func _ready() -> void:
	stretch = true  # The viewport follows our size, divided by stretch_shrink.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Chunky pixels, no blur.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post.shader = POST_SHADER
	material = _post
	resized.connect(_fit)
	_fit()


## How much to shrink a view `height` pixels tall so it gets close to
## `target_rows` rows of pixels. Always a whole number, so every big pixel is
## the same size.
static func shrink_for(height: float, target_rows: int) -> int:
	return maxi(1, roundi(height / float(maxi(target_rows, 1))))


## The camera currently showing the world.
func camera() -> Camera3D:
	return viewport.get_camera_3d()


## Where a spot in the 3D world shows up on the screen, in the same units as
## the HUD (whose CanvasLayer isn't inside the low-res view).
func unproject(world_position: Vector3) -> Vector2:
	var low_res := camera().unproject_position(world_position)
	return get_global_rect().position + low_res * (size / Vector2(viewport.size))


## Re-reads the "PS1 look" values. Called whenever the window changes size.
func _fit() -> void:
	var tuning := GameState.tuning
	stretch_shrink = shrink_for(size.y, tuning.psx_resolution_height)
	var pixels := (size / float(stretch_shrink)).floor()
	RenderingServer.global_shader_parameter_set("psx_snap_resolution", pixels * tuning.vertex_snap_scale)
	RenderingServer.global_shader_parameter_set("psx_affine_strength", tuning.affine_strength)
	_post.set_shader_parameter("color_levels", tuning.color_levels)
	_post.set_shader_parameter("dither_strength", tuning.dither_strength)


## Input never goes into the 3D world directly. The scene that owns this view
## hands the 3D nodes what they need (for flight, the mouse steering), which
## keeps it obvious where every key press and mouse move ends up.
func _propagate_input_event(_event: InputEvent) -> bool:
	return false
