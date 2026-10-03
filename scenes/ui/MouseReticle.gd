class_name MouseReticle
extends Control
## A small ring showing where the mouse's "virtual stick" is pushing the
## ship. It fades away when the mouse settles back to the middle.


## How far from the middle of the screen the ring sits at a full push.
const REACH: float = 160.0

## The controls to show. Set by FlightHUD.
var controls: ShipControls


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if controls == null:
		return
	var push := controls.mouse_stick()
	var strength := clampf(push.length() * 3.0, 0.0, 0.8)
	if strength < 0.05:
		return
	var center := size * 0.5
	var ring := center + push * REACH
	draw_line(center, ring, Color(1, 1, 1, strength * 0.3), 1.0, true)
	draw_arc(ring, 10.0, 0.0, TAU, 24, Color(1, 1, 1, strength), 2.0, true)
