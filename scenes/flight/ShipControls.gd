class_name ShipControls
extends Node
## Reads the pilot's hands (keyboard, mouse and gamepad) and turns them into
## FlightControls for the ship.
##
## The mouse works like a "virtual thumbstick": moving the mouse pushes the
## stick, and it drifts back to center when you stop. Mouse and stick add
## together, then get smoothed a little so steering feels buttery.


var _controls := FlightControls.new()
var _mouse_stick := Vector2.ZERO
var _smoothed_steer := Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# The mouse only steers while it's captured (hidden and locked to the
	# game window), so clicking around in menus never yanks the ship.
	if not event is InputEventMouseMotion or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion := event as InputEventMouseMotion
	# screen_relative = how far the mouse moved in real screen pixels,
	# so the feel doesn't change when the window is resized.
	_mouse_stick += motion.screen_relative * GameState.tuning.mouse_sensitivity
	_mouse_stick = _mouse_stick.limit_length(1.0)


## Reads the controls for this physics step.
func read(delta: float) -> FlightControls:
	var tuning := GameState.tuning
	var stick := Input.get_vector("steer_left", "steer_right", "steer_up", "steer_down", tuning.stick_deadzone)
	_mouse_stick = _mouse_stick.lerp(Vector2.ZERO, 1.0 - exp(-tuning.mouse_recenter_speed * delta))
	var combined := (stick + _mouse_stick).limit_length(1.0)
	_smoothed_steer = _smoothed_steer.lerp(combined, 1.0 - exp(-tuning.steer_response * delta))

	_controls.steer = Vector2(_smoothed_steer.x, Settings.pitch_from_vertical_input(_smoothed_steer.y))
	# The "throttle" actions are now direct thrust: hold to burn forward or
	# backward, let go to coast.
	_controls.thrust = Input.get_action_strength("throttle_up") - Input.get_action_strength("throttle_down")
	_controls.boost = Input.is_action_pressed("boost")
	return _controls


## Where the mouse's virtual stick is right now (the HUD draws a reticle there).
func mouse_stick() -> Vector2:
	return _mouse_stick


## Lets go of everything, e.g. when the ship is reset to the start.
func clear() -> void:
	_mouse_stick = Vector2.ZERO
	_smoothed_steer = Vector2.ZERO
