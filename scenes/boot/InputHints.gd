class_name InputHints
## Turns Input Map bindings into short, human-friendly text like
## "W / RT". The boot screen uses it to label every action; later it can
## power on-screen button prompts.


const JOY_BUTTON_NAMES: Dictionary = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_GUIDE: "Home",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad up",
	JOY_BUTTON_DPAD_DOWN: "D-pad down",
	JOY_BUTTON_DPAD_LEFT: "D-pad left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad right",
}


## Everything bound to an action, e.g. "A / Left / L-stick left".
static func for_action(action: StringName) -> String:
	var parts := PackedStringArray()
	for event in InputMap.action_get_events(action):
		var text := for_event(event)
		if not text.is_empty() and not parts.has(text):
			parts.append(text)
	return " / ".join(parts)


## A short name for one key, button or stick direction.
static func for_event(event: InputEvent) -> String:
	if event is InputEventKey:
		return _key_name(event as InputEventKey)
	if event is InputEventJoypadButton:
		var button := (event as InputEventJoypadButton).button_index
		return JOY_BUTTON_NAMES.get(button, "Button %d" % button)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return _axis_name(motion.axis, motion.axis_value)
	return event.as_text()


static func _key_name(event: InputEventKey) -> String:
	if event.physical_keycode == KEY_NONE:
		return OS.get_keycode_string(event.keycode)
	# Keys are bound by POSITION, so ask what's printed on THIS player's
	# keyboard in that spot (e.g. "Z" on a French keyboard instead of "W").
	# The windowless "headless" mode used for automated checks can't answer.
	if DisplayServer.get_name() != "headless":
		var printed_key := DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
		if printed_key != KEY_NONE:
			return OS.get_keycode_string(printed_key)
	return OS.get_keycode_string(event.physical_keycode)


static func _axis_name(axis: JoyAxis, direction: float) -> String:
	match axis:
		JOY_AXIS_LEFT_X:
			return "L-stick left" if direction < 0.0 else "L-stick right"
		JOY_AXIS_LEFT_Y:
			return "L-stick up" if direction < 0.0 else "L-stick down"
		JOY_AXIS_RIGHT_X:
			return "R-stick left" if direction < 0.0 else "R-stick right"
		JOY_AXIS_RIGHT_Y:
			return "R-stick up" if direction < 0.0 else "R-stick down"
		JOY_AXIS_TRIGGER_LEFT:
			return "LT"
		JOY_AXIS_TRIGGER_RIGHT:
			return "RT"
	return "Axis %d" % axis
