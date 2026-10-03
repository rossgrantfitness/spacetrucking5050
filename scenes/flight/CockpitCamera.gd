extends Camera3D
## The view from the driver's seat. It's bolted to the cab, so it turns with
## the rig but never rolls; the hazard-striped frame on top is drawn by
## CockpitFrame. Like the chase camera, it widens its view a little at speed.


var _ship: Ship


func _ready() -> void:
	_ship = get_parent() as Ship
	fov = GameState.tuning.base_fov


func _process(delta: float) -> void:
	var tuning := GameState.tuning
	var wanted_fov := ChaseCamera.fov_for_speed(_ship.speed_ratio(), tuning)
	fov = lerpf(fov, wanted_fov, 1.0 - exp(-tuning.fov_response * delta))
