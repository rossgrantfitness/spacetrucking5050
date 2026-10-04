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
## Emitted when the ship bonks into something. `strength` runs from 0 (a
## gentle bump) to 1 (the hardest bonk); `where` is the spot that got hit.
signal bonked(strength: float, where: Vector3)

## The ship's personality: speed, handling, boost. See res://data/ships/.
@export var ship_data: ShipData

## The rules of flying (see FlightModel.gd).
var flight := FlightModel.new()
## Jolts to the camera: a kick when boost fires, a rumble while it burns, and
## bonks. Both cameras read it.
var shake := ScreenShake.new()
## How healthy the hull is: 1 = like new, 0 = held together with duct tape.
## Nothing ever explodes; a battered rig just smokes and sparks.
var hull: float = 1.0
## How intact the cargo is: 1 = pristine, 0 = a box of crumbs. Bonks knock
## it a little. (Fragile jobs pay a bonus that shrinks with it.)
var cargo_condition: float = 1.0
## Where the last bonk hit, relative to the ship (x = right, y = up,
## z = toward the back). The HUD's little hull picture flashes that spot.
var last_bonk_local := Vector3.ZERO
## How far the rig has flown this trip, in meters (the dashboard odometer).
var odometer: float = 0.0

## Gentle hazards (M5) report here, and the HUD's status lights read them.
## Nothing sets these yet. All run from 0 (nothing) to 1 (full on).
var gravity_pull: float = 0.0
## A gravity well you could slingshot around for free speed.
var slingshot_ready: bool = false
var storm: float = 0.0
## Space cops' speed trap nearby (the trucker's radar detector).
var speed_trap: float = 0.0
## Charging toward a system jump point: below 0 = none near, 0 to 1 = charge.
var jump_charge: float = -1.0

var _was_boosting := false
var _bonk_cooldown := 0.0

@onready var controls: ShipControls = $ShipControls
## The inside of the cab, shown in cockpit view.
@onready var cockpit: Cockpit = $Cockpit
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
	# rules, after checking whether we bonked into something.
	var before := velocity
	move_and_slide()
	flight.velocity = velocity
	_check_for_bonks(before, delta)
	odometer += flight.speed() * delta
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


## Knocks the hull, shakes the camera, bounces the ship a little and tells
## everyone (sparks, sound, HUD). `impact` is how fast we hit, in m/s.
func bonk(impact: float, where: Vector3, away: Vector3 = Vector3.ZERO) -> void:
	var tuning := GameState.tuning
	var strength := bonk_strength(impact, tuning)
	hull = maxf(hull - lerpf(tuning.bonk_damage_min, tuning.bonk_damage_max, strength), 0.0)
	cargo_condition = maxf(cargo_condition - lerpf(tuning.cargo_damage_min, tuning.cargo_damage_max, strength), 0.0)
	last_bonk_local = global_basis.inverse() * (where - global_position)
	shake.add_trauma(lerpf(0.25, tuning.bonk_max_shake, strength))
	flight.velocity += away * impact * tuning.bonk_bounce
	_bonk_cooldown = tuning.bonk_cooldown
	if Settings.rumble:
		Input.start_joy_vibration(0, 0.3 + 0.5 * strength, 0.2 + 0.8 * strength, 0.15 + 0.25 * strength)
	bonked.emit(strength, where)


## How big a bonk hitting something at `impact` m/s is: 0 (gentlest) to 1.
static func bonk_strength(impact: float, tuning: Tuning) -> float:
	return clampf((impact - tuning.bonk_min_speed) / maxf(tuning.bonk_hard_speed - tuning.bonk_min_speed, 0.01), 0.0, 1.0)


## Patches up the hull a bit (1 = all of it).
func repair(amount: float) -> void:
	hull = minf(hull + amount, 1.0)


## Looks at everything we touched this step and bonks on the hardest hit.
func _check_for_bonks(before: Vector3, delta: float) -> void:
	_bonk_cooldown = maxf(_bonk_cooldown - delta, 0.0)
	var hardest := 0.0
	var where := Vector3.ZERO
	var away := Vector3.ZERO
	for i in get_slide_collision_count():
		var contact := get_slide_collision(i)
		var normal := contact.get_normal()  # Points away from what we hit.
		# How fast we were going straight into it, plus how fast it was
		# coming at us (traffic moves too).
		var impact := -before.dot(normal) + contact.get_collider_velocity().dot(normal)
		if impact > hardest:
			hardest = impact
			where = contact.get_position()
			away = normal
	if hardest >= GameState.tuning.bonk_min_speed and _bonk_cooldown <= 0.0:
		bonk(hardest, where, away)


func _update_shake(delta: float) -> void:
	var tuning := GameState.tuning
	if flight.boosting and not _was_boosting:
		shake.add_trauma(tuning.boost_kick_shake)  # The boost kicks in: thump!
	_was_boosting = flight.boosting
	shake.rumble = tuning.boost_rumble_shake if flight.boosting else 0.0
	shake.update(delta, tuning.shake_decay)


## Shows the ship from outside (chase view) or the inside of the cab
## (cockpit view, where we're sitting inside it).
func set_cockpit_view(in_cockpit: bool) -> void:
	_visual_pivot.visible = not in_cockpit
	cockpit.visible = in_cockpit


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
