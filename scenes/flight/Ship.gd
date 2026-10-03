class_name Ship
extends CharacterBody3D
## The player's rig in flight.
##
## FlightModel.gd decides HOW it moves; this script moves the actual ship in
## the world, leans the visible model into turns, and shares the ship's state
## with the camera, HUD, trails and engine sound.
##
## The look of the ship lives in its own scene (ShipVisual.tscn) inside the
## VisualPivot node, so the placeholder art can be swapped for a real model
## later without touching this code.


## Emitted after the ship jumps somewhere new (e.g. "back to the start"), so
## things like the engine trails can wipe themselves clean.
signal teleported

## The ship's personality: speed, handling, boost. See res://data/ships/.
@export var ship_data: ShipData

## The rules of flying (see FlightModel.gd).
var flight := FlightModel.new()
## Jolts to the camera: a kick when boost fires, a rumble while it burns (and
## bonks, from M2). Both cameras read it.
var shake := ScreenShake.new()

var _was_boosting := false

@onready var controls: ShipControls = $ShipControls
@onready var _visual_pivot: Node3D = $VisualPivot


func _ready() -> void:
	# Start facing whichever way the ship was placed in the editor.
	var facing := global_basis.get_euler()
	flight.reset(facing.y, facing.x)


func _physics_process(delta: float) -> void:
	flight.update(delta, controls.read(delta), ship_data, GameState.tuning)
	global_basis = flight.orientation()
	velocity = flight.velocity
	# move_and_slide moves us along `velocity`, and if we touch an asteroid it
	# slides us along its surface instead of passing through. The momentum
	# that went into the rock is lost, so hand the result back to the flight
	# rules. (Proper cartoon "bonks" come in M2.)
	move_and_slide()
	flight.velocity = velocity
	_update_shake(delta)
	# Lean the visible model into turns. Only the model leans: the ship itself
	# never rolls, so the camera's horizon stays level.
	_visual_pivot.rotation = Vector3(flight.nose_tilt, 0.0, flight.bank)


## 0 when stopped, 1 at normal top speed, above 1 when boosted past it.
func speed_ratio() -> float:
	return flight.speed() / ship_data.max_speed


## The color of this ship's engine trails (used by EngineTrail).
func trail_color() -> Color:
	return ship_data.trail_color


## How far past top speed we are, from 0 (at or below top speed) to 1 (at
## full boost speed). Drives the boost-speed effects.
func overspeed_ratio() -> float:
	var top := ship_data.max_speed
	return clampf((flight.speed() - top) / (FlightModel.boosted_top_speed(ship_data) - top), 0.0, 1.0)


func _update_shake(delta: float) -> void:
	var tuning := GameState.tuning
	if flight.boosting and not _was_boosting:
		shake.add_trauma(tuning.boost_kick_shake)  # The boost kicks in: thump!
	_was_boosting = flight.boosting
	shake.rumble = tuning.boost_rumble_shake if flight.boosting else 0.0
	shake.update(delta, tuning.shake_decay)


## Shows or hides the ship's model (hidden in cockpit view, where we're
## sitting inside it).
func set_model_visible(model_visible: bool) -> void:
	_visual_pivot.visible = model_visible


## Puts the ship somewhere new, parked, with no smoothing in between.
func teleport(where: Transform3D) -> void:
	global_transform = where
	var facing := where.basis.get_euler()
	flight.reset(facing.y, facing.x)
	controls.clear()
	velocity = Vector3.ZERO
	_visual_pivot.rotation = Vector3.ZERO
	# Tell Godot's motion smoothing not to slide us from the old spot.
	reset_physics_interpolation()
	teleported.emit()
