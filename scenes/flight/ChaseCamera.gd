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
## - LOOK AROUND: hold the middle mouse button (the wheel) and move the mouse
##   (or use the right stick) to swing it around the rig in any direction,
##   the rig staying in the middle of the screen. Let go and it eases back
##   behind the rig (and the mouse steers again). Hold the right mouse button
##   and drag to pan. When the mouse is free (watch mode, on autopilot), drag
##   with the left button instead. See "Chase camera" in tuning.tres.
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
## Looking around: how far the camera's swung round the rig (radians, on
## top of its usual spot behind), and how far it's panned (meters, sideways
## and up). Seconds since you last looked around.
var orbit_yaw := 0.0
var orbit_pitch := 0.0
var pan := Vector2.ZERO
var _idle := 0.0
var _dragging := false
var _panning := false
var _orbiting := false  # The wheel's held down: the mouse looks around.


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
	if not current:
		return
	var tuning := GameState.tuning
	var motion := event as InputEventMouseMotion
	if motion != null:
		var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		if _panning:
			pan += Vector2(-motion.screen_relative.x, motion.screen_relative.y) * tuning.orbit_pan_meters
			pan = pan.limit_length(tuning.orbit_pan_max)
			_idle = 0.0
		elif (captured and _orbiting) or _dragging:
			# Mouse right swings the view right, mouse up looks up.
			look_around(-motion.screen_relative.x * deg_to_rad(tuning.orbit_mouse_degrees),
					motion.screen_relative.y * deg_to_rad(tuning.orbit_mouse_degrees))
		return
	var button := event as InputEventMouseButton
	if button == null:
		return
	match button.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if button.pressed:
				zoom_goal = maxf(zoom_goal / tuning.chase_zoom_step, tuning.chase_zoom_min)
		MOUSE_BUTTON_WHEEL_DOWN:
			if button.pressed:
				zoom_goal = minf(zoom_goal * tuning.chase_zoom_step, tuning.chase_zoom_max)
		MOUSE_BUTTON_RIGHT:
			_panning = button.pressed
		MOUSE_BUTTON_LEFT:
			# (Only drags when the mouse is free; captured, it just looks.)
			_dragging = button.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				return
		MOUSE_BUTTON_MIDDLE:
			_orbiting = button.pressed
			if not button.pressed:
				_idle = GameState.tuning.orbit_return_seconds  # Let go: ease straight back.
		_:
			return
	get_viewport().set_input_as_handled()


## Swings the camera round the rig by `yaw` (left/right) and `pitch`
## (up/down), in radians.
func look_around(yaw: float, pitch: float) -> void:
	var limit := deg_to_rad(GameState.tuning.orbit_pitch_limit)
	orbit_yaw = wrapf(orbit_yaw + yaw, -PI, PI)
	orbit_pitch = clampf(orbit_pitch + pitch, -limit, limit)
	_idle = 0.0


## Back behind the rig, no pan.
func reset_look() -> void:
	orbit_yaw = 0.0
	orbit_pitch = 0.0
	pan = Vector2.ZERO
	_idle = 0.0


func _process(delta: float) -> void:
	var tuning := GameState.tuning
	_zoom = lerpf(_zoom, zoom_goal, 1.0 - exp(-tuning.chase_zoom_response * delta))
	_update_look(delta)
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


## The right stick looks around too, and an untouched camera eases back.
func _update_look(delta: float) -> void:
	var tuning := GameState.tuning
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down", tuning.stick_deadzone)
	if stick.length() > 0.0:
		var turn := deg_to_rad(tuning.orbit_stick_degrees) * delta
		look_around(-stick.x * turn, stick.y * turn)
	_idle += delta
	if tuning.orbit_return_seconds > 0.0 and _idle > tuning.orbit_return_seconds and not _panning and not _dragging and not _orbiting:
		var ease_back := 1.0 - exp(-tuning.orbit_return_speed * delta)
		orbit_yaw = wrapf(lerp_angle(orbit_yaw, 0.0, ease_back), -PI, PI)
		orbit_pitch = lerpf(orbit_pitch, 0.0, ease_back)
		pan = pan.lerp(Vector2.ZERO, ease_back)


func _place(ship_position: Vector3, roll: float) -> void:
	var tuning := GameState.tuning
	# A view direction made of only heading and pitch, never roll: that's what
	# keeps the horizon level. Looking around swings it further round the rig.
	var behind := Basis.from_euler(Vector3(_pitch, _heading, 0.0))
	var view := behind * Basis.from_euler(Vector3(orbit_pitch, orbit_yaw, 0.0))
	# Looking around, aim at the rig itself (not ahead of it), and pan.
	var swung := clampf((absf(orbit_yaw) + absf(orbit_pitch)) / 0.6, 0.0, 1.0)
	var aim := ship_position + behind * Vector3(0.0, 0.0, -tuning.chase_look_ahead * (1.0 - swung))
	var shift := view.x * pan.x + view.y * pan.y
	global_position = ship_position + shift + view * Vector3(0.0, tuning.chase_height * _zoom, tuning.chase_distance * _zoom + _pullback)
	look_at(aim + shift, view.y)
	if roll != 0.0:
		rotate_object_local(Vector3.BACK, roll)
