class_name DriftMarker
extends Control
## A small ring with a dot that sits where the ship's momentum is actually
## carrying it. With momentum, the nose and your real direction can differ:
## after a hard turn (or a boost), you'll see this marker slide away from
## where the rig is pointing, then drift back as grip catches up.
## Hidden when you're nearly stopped or sliding backwards.


const MARKER_COLOR := Color(1.0, 0.85, 0.45)
## How far ahead along our path the marker is placed, in meters.
const LOOK_AHEAD: float = 400.0

## The ship to follow. Set by FlightHUD.
var ship: Ship


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if ship == null or camera == null or ship.flight.speed() < 3.0:
		return
	var heading_to := ship.get_global_transform_interpolated().origin + ship.flight.velocity.normalized() * LOOK_AHEAD
	if camera.is_position_behind(heading_to):
		return
	var spot := camera.unproject_position(heading_to)
	draw_arc(spot, 9.0, 0.0, TAU, 20, MARKER_COLOR, 2.0, true)
	draw_circle(spot, 2.0, MARKER_COLOR)
	# Little "wings" so it reads as a direction marker, not a target.
	draw_line(spot + Vector2(-17.0, 0.0), spot + Vector2(-9.0, 0.0), MARKER_COLOR, 2.0, true)
	draw_line(spot + Vector2(9.0, 0.0), spot + Vector2(17.0, 0.0), MARKER_COLOR, 2.0, true)
