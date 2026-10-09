extends Camera3D
## The view from the driver's seat, inside the 3D cab (see Cockpit.gd). It
## turns with the rig but never rolls. Your head sways a little in turns,
## and like the chase camera, the view widens at speed and shakes with the
## ship's jolts.


var _ship: Ship
var _seat := Vector3.ZERO
var _sway := Vector2.ZERO


func _ready() -> void:
	_ship = get_parent() as Ship
	_seat = position
	fov = GameState.tuning.base_fov


func _process(delta: float) -> void:
	var tuning := GameState.tuning
	var wanted_fov := ChaseCamera.fov_for(_ship, tuning)
	fov = lerpf(fov, wanted_fov, 1.0 - exp(-tuning.fov_response * delta))


# The head sway moves the camera, so it happens in the physics step: the
# camera rides on the ship, which Godot smooths between physics steps.
func _physics_process(delta: float) -> void:
	var tuning := GameState.tuning
	# Your head lags the cab a little: turning right leans you left, pitching
	# up presses you down into the seat.
	var turn := _ship.flight.turn_amount(_ship.ship_data)
	var pitching := _ship.flight.pitch_speed / deg_to_rad(_ship.ship_data.pitch_rate)
	_sway = _sway.lerp(Vector2(-turn, -pitching) * tuning.cockpit_head_sway, 1.0 - exp(-tuning.cockpit_sway_response * delta))
	position = _seat + Vector3(_sway.x, _sway.y, 0.0) + _ship.shake.offset(tuning.shake_max_offset) * 0.15
	rotation.z = _ship.shake.tilt(deg_to_rad(tuning.shake_max_tilt))
