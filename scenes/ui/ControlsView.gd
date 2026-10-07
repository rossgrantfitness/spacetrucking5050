class_name ControlsView
extends CanvasLayer
## The controls card: every key and gamepad button, grouped into flying, on
## foot and anywhere. Opens from the pause menu ("Controls").
##
## The keys are read from the Input Map (Project Settings > Input Map), so
## if a binding changes there, this card changes with it.
##
## Use it with:
##     await ControlsView.open(get_tree())


signal closed

const TITLE_COLOR := Color(1.0, 0.85, 0.25)
const GROUP_COLOR := Color(1.0, 0.62, 0.82)
const KEY_COLOR := Color(0.62, 0.95, 1.0)

## What's on the card: a group heading, then [what it does, its action(s)].
## An entry can list several actions ("steer" = all four directions) or
## give its keys as plain text, [keyboard, gamepad], when they aren't in the
## Input Map.
const GROUPS: Array = [
	["FLYING", [
		["Steer", ["steer_left", "steer_right", "steer_up", "steer_down"]],
		["Steer with the mouse", ["Move the mouse", ""]],
		["Throttle lever up / down", ["throttle_up", "throttle_down"]],
		["Boost (at full throttle, hold)", ["boost"]],
		["Chart a course (autopilot)", ["chart_course"]],
		["Get up and walk the cabin", ["get_up"]],
		["Reply to a call", ["reply"]],
		["Pick a reply", ["Q R E  or  1 2 3", "D-pad"]],
		["Cockpit / chase camera", ["toggle_camera"]],
		["Zoom the chase camera", ["Mouse wheel", ""]],
		["Cinema camera (on autopilot)", ["cinema_camera"]],
		["Look around", ["look_left", "look_right", "look_up", "look_down"]],
		["Look around with the mouse", ["Hold the wheel + move", ""]],
		["Reset the camera (it stays put till then)", ["reset_camera"]],
		["Hide the HUD", ["toggle_hud"]],
	]],
	["ON FOOT", [
		["Walk", ["move_forward", "move_back", "move_left", "move_right"]],
		["Run (hold)", ["run"]],
		["Talk / use", ["interact"]],
	]],
	["ANYWHERE", [
		["Radio: next / previous station", ["radio_next", "radio_previous"]],
		["Radio on / off", ["radio_power"]],
		["Logbook", ["logbook"]],
		["Pause (this menu)", ["pause"]],
	]],
]

var _done: bool = false


## Shows the controls card and waits until it's closed.
static func open(tree: SceneTree) -> void:
	var card := ControlsView.new()
	tree.root.add_child(card)
	await card.closed
	card.queue_free()


## The keys (`gamepad` false) or buttons (true) for one line of the card,
## e.g. "A D Left Right" or "L-stick". Stick directions are shortened to
## just the stick, since the words say which way.
static func keys_for(what: Array, gamepad: bool) -> String:
	if not what.is_empty() and not InputMap.has_action(what[0]):
		return what[1] if gamepad else what[0]  # Plain text.
	var parts := PackedStringArray()
	for action: String in what:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			var is_pad := event is InputEventJoypadButton or event is InputEventJoypadMotion
			if is_pad != gamepad:
				continue
			var text := InputHints.for_event(event)
			if event is InputEventJoypadMotion and text.contains("-stick"):
				text = text.get_slice(" ", 0)  # "L-stick left" -> "L-stick"
			if not parts.has(text):
				parts.append(text)
	return " / ".join(parts)


func _ready() -> void:
	layer = 36  # Above the pause menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.05, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = MenuPanel.BOX_COLOR
	style.border_color = Color(0.85, 0.88, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(24.0)
	box.add_theme_stylebox_override("panel", style)
	center.add_child(box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	box.add_child(column)
	column.add_child(_label("CONTROLS", 30, TITLE_COLOR))
	# A scrolling list, so it fits small windows too.
	var scroller := ScrollContainer.new()
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.custom_minimum_size = Vector2(1100.0, 520.0)
	column.add_child(scroller)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 4)
	scroller.add_child(grid)
	grid.add_child(Control.new())
	grid.add_child(_label("KEYBOARD", 16, Color(0.7, 0.72, 0.85)))
	grid.add_child(_label("GAMEPAD", 16, Color(0.7, 0.72, 0.85)))
	for group: Array in GROUPS:
		grid.add_child(_label(group[0], 22, GROUP_COLOR))
		grid.add_child(Control.new())
		grid.add_child(Control.new())
		for line: Array in group[1]:
			grid.add_child(_label(line[0], 16, Color(0.95, 0.96, 1.0)))
			for gamepad: bool in [false, true]:
				var keys := _label(keys_for(line[1], gamepad), 16, KEY_COLOR)
				keys.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				grid.add_child(keys)
	var back := Button.new()
	back.text = "BACK"
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(_close)
	column.add_child(back)
	column.add_child(_label("Esc / B / E / A: back", 16, Color(0.7, 0.72, 0.85)))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	back.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") \
			or (event.is_action_pressed("interact") and not event.is_echo()):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if _done:
		return
	_done = true
	closed.emit()


func _label(words: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
