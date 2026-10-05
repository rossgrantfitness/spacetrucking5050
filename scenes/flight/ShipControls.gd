class_name ShipControls
extends Node
## Reads the pilot's hands (keyboard, mouse and gamepad) and turns them into
## FlightControls for the ship.
##
## The mouse works like a "virtual thumbstick": moving the mouse pushes the
## stick, and it drifts back to center when you stop. Mouse and stick add
## together, then get smoothed a little so steering feels buttery.
##
## The throttle is a LEVER (see "Throttle" in tuning.tres): W / right
## trigger pushes it up, S / left trigger pulls it down, and it stays where
## you leave it. The engines then speed the rig up or slow it down to the
## lever's speed and hold it there. Boost spools up while held, and only
## lights at full throttle.


## Where the throttle lever is: 1 = full (top speed), 0 = idle (the rig
## slows to a stop), below 0 = reverse.
var lever: float = 0.0
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

var _controls := FlightControls.new()
var _mouse_stick := Vector2.ZERO
var _smoothed_steer := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# The mouse only steers while it's captured (hidden and locked to the
	# game window), so clicking around in menus never yanks the ship.
	if hands_free or not event is InputEventMouseMotion or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
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
		_controls.thrust = thrust_for(lever, forward_speed, max_speed, tuning)
		_controls.boost = false
		_controls.touched = false
		_controls.throttle_push = 0.0
		boost_blocked = false
		return _controls
	var stick := Input.get_vector("steer_left", "steer_right", "steer_up", "steer_down", tuning.stick_deadzone)
	_mouse_stick = _mouse_stick.lerp(Vector2.ZERO, 1.0 - exp(-tuning.mouse_recenter_speed * delta))
	var combined := (stick + _mouse_stick).limit_length(1.0)
	_smoothed_steer = _smoothed_steer.lerp(combined, 1.0 - exp(-tuning.steer_response * delta))

	_controls.steer = Vector2(_smoothed_steer.x, Settings.pitch_from_vertical_input(_smoothed_steer.y))
	# Move the lever while the throttle keys (or triggers) are held.
	var push := Input.get_action_strength("throttle_up") - Input.get_action_strength("throttle_down")
	_controls.throttle_push = push
	lever = clampf(lever + push * tuning.throttle_lever_speed * delta, -tuning.reverse_lever, 1.0)
	_controls.thrust = thrust_for(lever, forward_speed, max_speed, tuning)
	var wants_boost := Input.is_action_pressed("boost")
	boost_blocked = wants_boost and tuning.boost_needs_full_throttle and lever < 0.95
	_controls.boost = wants_boost and not boost_blocked
	_controls.touched = absf(push) > 0.1 or wants_boost or combined.length() > 0.3
	return _controls


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


## Where the mouse's virtual stick is right now (the HUD draws a reticle there).
func mouse_stick() -> Vector2:
	return _mouse_stick


## Lets go of everything, e.g. when the ship is reset to the start (the
## throttle lever goes back to idle).
func clear() -> void:
	_mouse_stick = Vector2.ZERO
	_smoothed_steer = Vector2.ZERO
	lever = 0.0
