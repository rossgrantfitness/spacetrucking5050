extends Camera3D
## The view from the driver's seat. It's bolted to the cab, so it turns with
## the rig but never rolls; the hazard-striped frame on top is drawn by
## CockpitFrame. Like the chase camera, it widens its view at speed and
## shakes with the ship's jolts.


var _ship: Ship
var _seat := Vector3.ZERO


func _ready() -> void:
	_ship = get_parent() as Ship
	_seat = position
	fov = GameState.tuning.base_fov


func _process(delta: float) -> void:
	var tuning := GameState.tuning
	var wanted_fov := ChaseCamera.fov_for(_ship, tuning)
	fov = lerpf(fov, wanted_fov, 1.0 - exp(-tuning.fov_response * delta))
	position = _seat + _ship.shake.offset(tuning.shake_max_offset) * 0.5
	rotation.z = _ship.shake.tilt(deg_to_rad(tuning.shake_max_tilt))
