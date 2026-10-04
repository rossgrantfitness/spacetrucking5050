extends SceneTree
## Writes the game's DEFAULT controls into project.godot's Input Map.
##
## You normally never need this: the controls are already saved in the project,
## and you can change them in the editor under
## Project > Project Settings > Input Map.
## Running this script again resets the actions listed below to these
## defaults (any extra actions you added yourself are left alone).
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/setup_input_map.gd
##
## Why some things are missing on purpose:
## - The mouse steers the ship, but mouse MOVEMENT can't be an Input Map
##   action, so that's handled in code using Tuning's mouse settings.
## - Menus use Godot's built-in "ui_" actions (arrows/Enter/Esc, D-pad/A/B),
##   which already cover keyboard and gamepad.


# How far a stick or trigger must move before an action counts as "pressed".
# (Analog steering uses Tuning's stick_deadzone instead, for smoothness.)
const STICK: float = 0.2
const TRIGGER: float = 0.1
const BUTTON: float = 0.5  # Godot's default; it doesn't matter for buttons.


func _init() -> void:
	# --- Flying ---------------------------------------------------------
	_action("steer_left", STICK, [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("steer_right", STICK, [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("steer_up", STICK, [_key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("steer_down", STICK, [_key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("throttle_up", TRIGGER, [_key(KEY_W), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_action("throttle_down", TRIGGER, [_key(KEY_S), _axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_action("boost", BUTTON, [_key(KEY_SPACE), _button(JOY_BUTTON_A)])
	_action("toggle_camera", BUTTON, [_key(KEY_C), _button(JOY_BUTTON_Y)])
	_action("radio_next", BUTTON, [_key(KEY_E), _button(JOY_BUTTON_DPAD_RIGHT)])
	_action("radio_previous", BUTTON, [_key(KEY_Q), _button(JOY_BUTTON_DPAD_LEFT)])
	_action("toggle_hud", BUTTON, [_key(KEY_H), _button(JOY_BUTTON_DPAD_DOWN)])
	# A developer helper: lights up every HUD warning so the look can be
	# checked. Keyboard only.
	_action("hud_demo", BUTTON, [_key(KEY_F9)])
	_action("look_left", STICK, [_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action("look_right", STICK, [_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action("look_up", STICK, [_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_action("look_down", STICK, [_axis(JOY_AXIS_RIGHT_Y, 1.0)])

	# --- Walking around the base ----------------------------------------
	_action("move_forward", STICK, [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_back", STICK, [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("move_left", STICK, [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", STICK, [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("interact", BUTTON, [_key(KEY_E), _button(JOY_BUTTON_A)])

	# --- Anywhere ---------------------------------------------------------
	_action("pause", BUTTON, [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)])

	var error := ProjectSettings.save()
	print("Input map saved to project.godot: ", error_string(error))
	quit(0 if error == OK else 1)


func _action(action_name: String, deadzone: float, events: Array) -> void:
	ProjectSettings.set_setting("input/" + action_name, {"deadzone": deadzone, "events": events})


# Keys use their PHYSICAL position, so on a French AZERTY keyboard "W" is still
# the key in the top-left letter row, where a QWERTY player expects it.
func _key(physical_key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.device = -1  # -1 = any keyboard
	event.physical_keycode = physical_key
	return event


func _button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = -1  # -1 = any gamepad, not just the first one plugged in
	event.button_index = button
	return event


func _axis(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = direction
	return event
