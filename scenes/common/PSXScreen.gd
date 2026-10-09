class_name PSXScreen
extends CanvasLayer
## Gives the 3D world the look of a late PlayStation 1 game (think 1999-2000),
## drawn at your screen's own resolution:
## - Every model's corners snap to a grid, so models gently wobble as they
##   move, and textures swim a little on big surfaces up close. This node
##   sets how strong those are; every 3D shader reads them (see
##   res://shaders/psx.gdshaderinc).
## - A screen pass squeezes colors to the PS1's 32 shades per channel with a
##   fine dither pattern (res://shaders/psx_post.gdshader).
##
## HOW TO USE: add it to a scene with a 3D world, on a layer BELOW the HUD and
## menus (they're drawn after it, so text stays perfectly crisp).
## All the knobs are in res://data/tuning.tres, under "PS1 look".


const POST_SHADER := preload("res://shaders/psx_post.gdshader")

var _post := ShaderMaterial.new()


func _ready() -> void:
	var screen := ColorRect.new()
	screen.name = "ColorAndDither"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post.shader = POST_SHADER
	screen.material = _post
	add_child(screen)
	get_viewport().size_changed.connect(_refresh)
	_refresh()


## The grid model corners snap to, for a screen `size` pixels big: `rows`
## rows tall, as wide as the screen's shape needs. Fewer rows = wobblier.
static func snap_grid(size: Vector2, rows: float) -> Vector2:
	return Vector2(rows * size.x / maxf(size.y, 1.0), rows)


## How big one dot of the dither pattern is, in real screen pixels, so the
## pattern looks the same on a small window and a 4K screen.
static func dither_dot_size(screen_height: float, dither_rows: float) -> float:
	return maxf(1.0, roundf(screen_height / maxf(dither_rows, 1.0)))


## Re-reads the "PS1 look" values. Called whenever the window changes size.
func _refresh() -> void:
	var tuning := GameState.tuning
	var window := Vector2(get_window().size)  # In real screen pixels.
	RenderingServer.global_shader_parameter_set("psx_snap_resolution", snap_grid(window, tuning.vertex_snap_rows))
	RenderingServer.global_shader_parameter_set("psx_affine_strength", tuning.affine_strength)
	_post.set_shader_parameter("color_levels", tuning.color_levels)
	_post.set_shader_parameter("dither_strength", tuning.dither_strength)
	_post.set_shader_parameter("dot_size", dither_dot_size(window.y, tuning.dither_rows))
