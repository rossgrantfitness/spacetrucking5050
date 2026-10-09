class_name ShipControls
extends Node
## Reads the pilot's hands (keyboard, mouse and gamepad) and turns them into
## FlightControls for the ship.
##
## Steering is the mouse, the left stick, A / D and the arrow keys, or
## I J K L. Newtonian flight adds rolling (Z / X or U / O, or LB / B on a
## gamepad) and strafing: hold Left Ctrl and the steering keys (or mouse)
## slide the rig sideways and up/down instead of turning it. The mouse works like a "virtual thumbstick": moving it pushes the
## stick, and it drifts back to center when you stop. While the middle mouse
## button (the wheel) is held, the mouse looks around the rig instead (see
## ChaseCamera). Mouse and stick add together, then get smoothed a little so
## steering feels buttery.
##
## The throttle is a LEVER (see "Throttle" in tuning.tres): W / right
## trigger pushes it up and it stays where you leave it; the engines speed
## the rig up or slow it down to the lever's speed and hold it there.
##
## S / left trigger is the REVERSE THRUSTERS: while held they fire against
## the nose (and the lever eases down toward idle). Moving forward, they
## slow her down; sitting still, they push her backwards. They're much
## weaker than the main engines (the rig's retro_thrust). Let go and the
## lever takes over again.
##
## Boost spools up while held, and only lights at full throttle (or
## whenever the cruise autopilot is driving: boosting doesn't switch it off).


## Where the throttle lever is: 1 = full (top speed), 0 = idle (the rig
## slows to a stop).
var lever: float = 0.0
## How hard the reverse thrusters are firing right now, 0 to 1 (S held).
var retro: float = 0.0
## True while the boost button is held (even if boost can't light yet).
var wants_boost: bool = false
## True while the pilot holds boost but the lever isn't at full (the HUD
## says so).
var boost_blocked: bool = false
## On while the pilot is out of the seat (walking around the cabin on
## autopilot): the controls ignore the keyboard, mouse and gamepad.
var hands_free: bool = false
## The rig whose speed the lever is matched against (set by Ship).
var max_speed: float = 55.0
## The rig's speed along its nose, for matching (set by Ship each step).
var forward_speed: float = 0.0
## Newtonian flight, and whether Flight Assist is on (set by Ship each step).
## With it off, the lever is raw thrust instead of a speed to hold.
var newtonian: bool = false
var flight_assist: bool = true

var _controls := FlightControls.new()
var _smoothed_steer := Vector2.ZERO
var _mouse_stick := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# The mouse only steers while it's captured (hidden and locked to the
	# game window), so clicking around in menus never yanks the ship; and not
	# while the wheel's held down (then it looks around).
	if hands_free or not event is InputEventMouseMotion or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or get_viewport().get_camera_3d() is CinemaCamera:
		return  # Looking around (or flying the cinema camera), not steering.
	var motion := event as InputEventMouseMotion
	# screen_relative = how far the mouse moved in real screen pixels,
	# so the feel doesn't change when the window is resized.
	_mouse_stick += motion.screen_relative * GameState.tuning.mouse_sensitivity
	_mouse_stick = _mouse_stick.limit_length(1.0)


## Reads the controls for this physics step.
func read(delta: float) -> FlightControls:
	var tuning := GameState.tuning
	if hands_free:
		_controls.steer = Vector2.ZERO
		_controls.roll = 0.0
		_controls.strafe = Vector2.ZERO
		_controls.thrust = _engine_thrust(tuning)
		_controls.boost = false
		_controls.touched = false
		_controls.throttle_push = 0.0
		boost_blocked = false
		wants_boost = false
		retro = 0.0
		return _controls
	var stick := Input.get_vector("steer_left", "steer_right", "steer_up", "steer_down", tuning.stick_deadzone)
	_mouse_stick = _mouse_stick.lerp(Vector2.ZERO, 1.0 - exp(-GameState.tuning.mouse_recenter_speed * delta))
	var combined := (stick + _mouse_stick).limit_length(1.0)
	_smoothed_steer = _smoothed_steer.lerp(combined, 1.0 - exp(-tuning.steer_response * delta))

	_controls.steer = Vector2(_smoothed_steer.x, Settings.pitch_from_vertical_input(_smoothed_steer.y))
	_controls.roll = 0.0
	_controls.strafe = Vector2.ZERO
	if newtonian:
		_controls.roll = Input.get_axis("roll_left", "roll_right")
		if Input.is_action_pressed("strafe_mode"):
			# Holding Ctrl: the same keys (and mouse) slide the rig instead.
			_controls.strafe = Vector2(_smoothed_steer.x, -_smoothed_steer.y)
			_controls.steer = Vector2.ZERO
	# Move the lever while the throttle keys (or triggers) are held; S also
	# fires the reverse thrusters.
	var push := Input.get_action_strength("throttle_up") - Input.get_action_strength("throttle_down")
	_controls.throttle_push = push
	lever = move_lever(lever, push * tuning.throttle_lever_speed * delta)
	retro = Input.get_action_strength("throttle_down")
	_controls.thrust = with_retro(_engine_thrust(tuning), retro)
	wants_boost = Input.is_action_pressed("boost")
	boost_blocked = wants_boost and tuning.boost_needs_full_throttle and lever < 0.95
	_controls.boost = wants_boost and not boost_blocked
	_controls.touched = absf(push) > 0.1 or wants_boost or combined.length() > 0.3 or absf(_controls.roll) > 0.3
	return _controls


## The thrust for the lever: a speed to reach and hold, or (Newtonian
## flight with Flight Assist off) the raw push itself.
func _engine_thrust(tuning: Tuning) -> float:
	if newtonian and not flight_assist:
		return lever
	return thrust_for(lever, forward_speed, max_speed, tuning)


## Moves the lever by `amount`, between idle (0) and full ahead (1). (No
## reverse on the lever: backing up is the reverse thrusters, S.)
static func move_lever(position: float, amount: float) -> float:
	return clampf(position + amount, 0.0, 1.0)


## The engine thrust with the reverse thrusters (`retro_strength`, 0 to 1)
## firing: while they fire, they win, pushing against the nose.
static func with_retro(engine_thrust: float, retro_strength: float) -> float:
	if retro_strength >= 0.1:
		return -retro_strength
	return engine_thrust


## The engine thrust (-1 to 1) that gets the rig to the lever's speed and
## holds it there. At full lever it keeps pushing into the engines' limiter,
## which only sips fuel.
static func thrust_for(lever_position: float, going: float, top_speed: float, tuning: Tuning) -> float:
	if lever_position >= 0.99:
		return 1.0
	var wanted := lever_position * top_speed
	return clampf((wanted - going) / tuning.throttle_band, -1.0, 1.0)


## The steering being given right now, after smoothing (x = right, y = nose
## up). The cockpit's steering wheel follows it.
func current_steer() -> Vector2:
	return _controls.steer


## Where the mouse's virtual stick is right now (the HUD draws a little
## diamond there).
func mouse_stick() -> Vector2:
	return _mouse_stick


## Lets go of everything, e.g. when the ship is reset to the start (the
## throttle lever goes back to idle).
func clear() -> void:
	_mouse_stick = Vector2.ZERO
	_smoothed_steer = Vector2.ZERO
	lever = 0.0
	retro = 0.0
