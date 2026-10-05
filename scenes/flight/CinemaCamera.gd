class_name CinemaCamera
extends Camera3D
## The cinematic camera (V / R3 while the autopilot drives). Two modes:
##
## - DIRECTOR: picks shots by itself and cuts to a new one every 7-10
##   seconds: a slow orbit, a tracking shot alongside the rig, a fly-by
##   (the camera waits up ahead and the rig whooshes past), a low hero shot
##   from the front, a wide telephoto shot, and a high shot from behind.
## - FREE: you hold the camera. The stick / keys / mouse swing it around the
##   rig, the throttle keys / triggers / mouse wheel zoom in and out.
##
## In both, the horizon stays level (no motion sickness), and the camera
## rides along with the rig, so it never gets left behind.
##
## FlightSandbox turns it on and off. While it's on, the stick and mouse
## don't steer the rig, so looking around can't knock off the autopilot.
## The numbers live in res://data/tuning.tres, under "Cinematic camera".


enum Mode { DIRECTOR, FREE }
enum Shot { ORBIT, TRACKING, FLYBY, HERO, WIDE, TAIL }

## How wide each director shot sees (degrees). WIDE is a long lens far away,
## which squashes the rig against the stars.
const SHOT_FOV: Dictionary = {
	Shot.ORBIT: 55.0, Shot.TRACKING: 50.0, Shot.FLYBY: 60.0,
	Shot.HERO: 62.0, Shot.WIDE: 24.0, Shot.TAIL: 64.0,
}

## The rig to film.
var target: Ship
var mode: Mode = Mode.DIRECTOR
var shot: Shot = Shot.ORBIT

## The direction the rig is traveling, smoothed and kept level-ish, so the
## shots don't jerk around when it wiggles.
var _forward := Vector3.FORWARD
var _shot_time: float = 0.0
var _shot_length: float = 8.0
## Which side of the rig the shot is on (+1 right, -1 left).
var _side: float = 1.0
## Where the camera waits during a fly-by (a fixed spot in space).
var _flyby_spot := Vector3.ZERO
var _orbit_angle: float = 0.0
# Free mode: the camera's angle around the rig and how far away it is.
var _yaw: float = 0.0
var _pitch: float = 0.2
var _distance: float = 40.0
var _mouse := Vector2.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# We place the camera ourselves from the rig's smoothed position.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rng.randomize()


## Takes over the view, in director mode.
func start() -> void:
	_forward = _travel_direction()
	mode = Mode.DIRECTOR
	_next_shot()
	_film(0.0)
	make_current()


## Switches to holding the camera yourself, starting from where it is now
## (so the view doesn't jump).
func take_over() -> void:
	if mode == Mode.FREE:
		return
	mode = Mode.FREE
	var offset := global_position - _rig_position()
	_distance = clampf(offset.length(), GameState.tuning.cinema_min_distance, GameState.tuning.cinema_max_distance)
	var frame := _frame()
	var flat := Vector2(offset.dot(frame.x), offset.dot(frame.z))
	_yaw = atan2(flat.x, flat.y)
	_pitch = clampf(asin(clampf(offset.normalized().dot(Vector3.UP), -1.0, 1.0)), -1.3, 1.3)
	fov = 60.0


func _unhandled_input(event: InputEvent) -> void:
	if not current or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		_mouse += motion.screen_relative
		return
	var wheel := event as InputEventMouseButton
	if wheel != null and wheel.pressed and wheel.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		take_over()
		_distance *= 0.9 if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not current or target == null:
		_mouse = Vector2.ZERO
		return
	var travel := _travel_direction()
	_forward = _forward.slerp(travel, 1.0 - exp(-1.5 * delta)).normalized()
	var hands := _hands()
	var zooming := absf(Input.get_action_strength("throttle_down") - Input.get_action_strength("throttle_up")) > 0.3
	if mode == Mode.DIRECTOR and (hands.length() > 0.3 or zooming or _mouse.length() > 6.0):
		take_over()  # Touch the stick or the mouse and the camera is yours.
	if mode == Mode.FREE:
		_steer_by_hand(hands, delta)
	_mouse = Vector2.ZERO
	_film(delta)


## The stick (either one) and the steering keys, as one push.
func _hands() -> Vector2:
	var dead := GameState.tuning.stick_deadzone
	var left := Input.get_vector("steer_left", "steer_right", "steer_up", "steer_down", dead)
	var right := Input.get_vector("look_left", "look_right", "look_up", "look_down", dead)
	return (left + right).limit_length(1.0)


func _steer_by_hand(hands: Vector2, delta: float) -> void:
	var tuning := GameState.tuning
	var turn := deg_to_rad(tuning.cinema_free_turn) * delta
	var mouse_turn := deg_to_rad(tuning.cinema_mouse_turn)
	_yaw -= hands.x * turn + _mouse.x * mouse_turn
	_pitch = clampf(_pitch + hands.y * turn + _mouse.y * mouse_turn, -1.3, 1.3)
	var zoom := Input.get_action_strength("throttle_down") - Input.get_action_strength("throttle_up")
	_distance *= exp(zoom * tuning.cinema_zoom_speed * delta)
	_distance = clampf(_distance, tuning.cinema_min_distance, tuning.cinema_max_distance)


# --- Placing the camera -----------------------------------------------------------

## Puts the camera where this frame's shot wants it and points it at the rig.
func _film(delta: float) -> void:
	var rig := _rig_position()
	var frame := _frame()
	var ahead := -frame.z
	var right := frame.x
	var look_at_spot := rig
	if mode == Mode.FREE:
		var around := Basis(Vector3.UP, _yaw) * frame.z
		var flat := around * cos(_pitch) + Vector3.UP * sin(_pitch)
		global_position = rig + flat * _distance
		_aim(rig)
		return
	_shot_time += delta
	if _shot_time > _shot_length:
		_next_shot()
	var t := _shot_time
	match shot:
		Shot.ORBIT:
			_orbit_angle += deg_to_rad(GameState.tuning.cinema_orbit_speed) * delta * _side
			global_position = rig + (Basis(Vector3.UP, _orbit_angle) * frame.z) * 42.0 + Vector3.UP * 8.0
		Shot.TRACKING:
			# Alongside, slowly sliding from the cab back toward the engines.
			global_position = rig + right * _side * 38.0 + Vector3.UP * 3.0 + ahead * (8.0 - t * 1.5)
			look_at_spot = rig + ahead * 4.0
		Shot.FLYBY:
			global_position = _flyby_spot
		Shot.HERO:
			# Low and in front, slowly backing away as the rig bears down.
			global_position = rig + ahead * (26.0 + t * 2.0) + right * _side * 7.0 - Vector3.UP * 5.0
		Shot.WIDE:
			global_position = rig + right * _side * 190.0 + Vector3.UP * 35.0 - ahead * 30.0
		Shot.TAIL:
			global_position = rig - ahead * 58.0 + Vector3.UP * 20.0 + right * _side * 6.0
			look_at_spot = rig + ahead * 30.0
	_aim(look_at_spot)


func _aim(spot: Vector3) -> void:
	var view := spot - global_position
	if view.length_squared() < 0.01:
		return
	# Looking almost straight up or down: use the rig's nose as "up" so
	# look_at doesn't spin.
	var up := Vector3.UP if absf(view.normalized().dot(Vector3.UP)) < 0.98 else _forward
	look_at(spot, up)


## Cuts to a new director shot (never the same one twice in a row).
func _next_shot() -> void:
	var tuning := GameState.tuning
	var choices: Array[Shot] = [Shot.ORBIT, Shot.TRACKING, Shot.FLYBY, Shot.HERO, Shot.WIDE, Shot.TAIL]
	choices.erase(shot)
	if target.flight.speed() < 8.0:
		choices.erase(Shot.FLYBY)  # Too slow to whoosh past anything.
	set_shot(choices[_rng.randi_range(0, choices.size() - 1)])
	_shot_length = _rng.randf_range(tuning.cinema_shot_min, maxf(tuning.cinema_shot_max, tuning.cinema_shot_min))


## Starts a particular director shot. Public so the tests can try each one.
func set_shot(new_shot: Shot) -> void:
	shot = new_shot
	_shot_time = 0.0
	_side = 1.0 if _rng.randf() < 0.5 else -1.0
	fov = SHOT_FOV[shot]
	var rig := _rig_position()
	var frame := _frame()
	_orbit_angle = _rng.randf_range(0.0, TAU)
	if shot == Shot.FLYBY:
		# Wait up ahead, a little off to the side, for about 4 seconds of
		# travel: the rig grows, whooshes past, and shrinks away.
		var lead := clampf(target.flight.speed() * 4.0, 60.0, 900.0)
		_flyby_spot = rig - frame.z * lead + frame.x * _side * 16.0 + Vector3.UP * 4.0


## A level frame that travels with the rig: z points backward along its
## travel (flattened if it climbs steeply), x to its right, y straight up.
func _frame() -> Basis:
	var back := -_forward
	var flat := Vector3(back.x, 0.0, back.z)
	if flat.length_squared() < 0.0001:
		flat = Vector3.BACK
	flat = flat.normalized()
	return Basis(Vector3.UP.cross(flat).normalized(), Vector3.UP, flat)


func _rig_position() -> Vector3:
	return target.get_global_transform_interpolated().origin


## Which way the rig is moving (or pointing, if it's barely moving).
func _travel_direction() -> Vector3:
	var velocity := target.flight.velocity
	if velocity.length() > 3.0:
		return velocity.normalized()
	return -target.global_basis.z
