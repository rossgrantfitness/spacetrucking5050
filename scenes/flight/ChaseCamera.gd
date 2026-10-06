class_name ChaseCamera
extends Camera3D
## A chase camera hanging behind and a little above the ship.
##
## - It swings around lazily, so in a turn you see the rig lead the way.
## - It falls back while boosting, and shakes a little when boost kicks in.
## - It widens its view (FOV) at high speed, and more at boost speed.
## - It keeps the horizon level, even while the rig leans into turns. Only if
##   the player switches on "camera roll" does it lean along (a lot of people
##   get motion sick from a rolling camera, so it's off by default).
## - The mouse wheel zooms it in and out (it remembers the zoom until you
##   quit the game).
##
## All the numbers live in res://data/tuning.tres, under "Chase camera" and
## "Field of view".


## The ship to follow.
@export var target: Ship

# The camera's own, lagging copy of the ship's heading and pitch.
var _heading := 0.0
var _pitch := 0.0
var _pullback := 0.0
## How zoomed out the camera is (1 = the usual distance). Shared by every
## chase camera, so the zoom you picked is kept after docking.
static var zoom_goal := 1.0
var _zoom := 1.0


## The field of view for the ship's speed: normal until 70% of top speed (by
## default), gently wider up to top speed, then wider still the further a
## boost pushes past it. The cockpit camera uses this too.
static func fov_for(ship: Ship, tuning: Tuning) -> float:
	var fast := clampf((ship.speed_ratio() - tuning.speed_fov_threshold) / (1.0 - tuning.speed_fov_threshold), 0.0, 1.0)
	return tuning.base_fov + tuning.speed_fov_bonus * fast + tuning.boost_fov_bonus * ship.overspeed_ratio()


func _ready() -> void:
	# We place the camera ourselves every frame, using the ship's smoothed
	# position, so Godot's own motion smoothing would only get in the way.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	snap_behind_target()


## Jumps straight to the resting spot behind the ship (no swinging).
func snap_behind_target() -> void:
	var ship_transform := target.get_global_transform_interpolated()
	var facing := ship_transform.basis.get_euler()
	_pitch = facing.x
	_heading = facing.y
	_pullback = 0.0
	_zoom = zoom_goal
	fov = GameState.tuning.base_fov
	_place(ship_transform.origin, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if not current or wheel == null or not wheel.pressed:
		return
	var tuning := GameState.tuning
	if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_goal = maxf(zoom_goal / tuning.chase_zoom_step, tuning.chase_zoom_min)
	elif wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_goal = minf(zoom_goal * tuning.chase_zoom_step, tuning.chase_zoom_max)
	else:
		return
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	var tuning := GameState.tuning
	_zoom = lerpf(_zoom, zoom_goal, 1.0 - exp(-tuning.chase_zoom_response * delta))
	# get_global_transform_interpolated() = where the ship APPEARS this frame,
	# smoothed between physics steps, so the camera never jitters.
	var ship_transform := target.get_global_transform_interpolated()
	var facing := ship_transform.basis.get_euler()

	var follow := 1.0 - exp(-tuning.chase_turn_follow * delta)
	_heading = lerp_angle(_heading, facing.y, follow)
	_pitch = lerpf(_pitch, facing.x, follow)

	# Fall back while boosting, and stay back while still going boost-fast.
	var boost_feel := maxf(target.overspeed_ratio(), 0.5 if target.flight.boosting else 0.0)
	var pullback_goal := tuning.chase_boost_pullback * boost_feel
	_pullback = lerpf(_pullback, pullback_goal, 1.0 - exp(-tuning.chase_pullback_response * delta))

	var roll := target.flight.bank * tuning.camera_roll_amount if Settings.camera_roll else 0.0
	_place(ship_transform.origin, roll)
	# Screen shake: a small nudge and tilt on top of the resting spot.
	global_position += global_basis * target.shake.offset(tuning.shake_max_offset)
	rotate_object_local(Vector3.BACK, target.shake.tilt(deg_to_rad(tuning.shake_max_tilt)))

	var wanted_fov := ChaseCamera.fov_for(target, tuning)
	fov = lerpf(fov, wanted_fov, 1.0 - exp(-tuning.fov_response * delta))


func _place(ship_position: Vector3, roll: float) -> void:
	var tuning := GameState.tuning
	# A view direction made of only heading and pitch, never roll: that's what
	# keeps the horizon level.
	var view := Basis.from_euler(Vector3(_pitch, _heading, 0.0))
	global_position = ship_position + view * Vector3(0.0, tuning.chase_height * _zoom, tuning.chase_distance * _zoom + _pullback)
	look_at(ship_position + view * Vector3(0.0, 0.0, -tuning.chase_look_ahead), view.y)
	if roll != 0.0:
		rotate_object_local(Vector3.BACK, roll)
