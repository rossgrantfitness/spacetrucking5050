class_name StickView
extends Control
## A round gauge showing a 2D input, as if looking down at a thumbstick.
##   Hollow ring      = what you're pressing right now (raw input).
##   Filled dot       = the smoothed version the ship would actually feel.
##   Faint inner ring = the deadzone (input inside it is ignored).


const BACKGROUND_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const RIM_COLOR := Color(1.0, 1.0, 1.0, 0.5)
const GUIDE_COLOR := Color(1.0, 1.0, 1.0, 0.12)
const DEADZONE_COLOR := Color(1.0, 0.62, 0.82, 0.45)
const RAW_COLOR := Color(1.0, 1.0, 1.0, 0.8)
const SMOOTHED_COLOR := Color(1.0, 0.69, 0.28)

var _raw := Vector2.ZERO
var _smoothed := Vector2.ZERO
var _deadzone := 0.0


## Call this every frame with fresh values (each axis runs from -1 to 1).
func show_input(raw: Vector2, smoothed: Vector2, deadzone: float) -> void:
	_raw = raw
	_smoothed = smoothed
	_deadzone = deadzone
	queue_redraw()  # Ask Godot to call _draw() again with the new values.


func _draw() -> void:
	var center := size / 2.0
	var radius := minf(size.x, size.y) / 2.0 - 8.0
	draw_circle(center, radius, BACKGROUND_COLOR)
	draw_arc(center, radius, 0.0, TAU, 48, RIM_COLOR, 2.0, true)
	draw_line(center + Vector2(-radius, 0.0), center + Vector2(radius, 0.0), GUIDE_COLOR)
	draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, radius), GUIDE_COLOR)
	if _deadzone > 0.0:
		draw_arc(center, radius * _deadzone, 0.0, TAU, 32, DEADZONE_COLOR, 1.0, true)
	draw_arc(center + _raw * radius, 8.0, 0.0, TAU, 24, RAW_COLOR, 2.0, true)
	draw_circle(center + _smoothed * radius, 6.0, SMOOTHED_COLOR)
