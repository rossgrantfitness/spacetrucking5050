extends Node3D
## The title screen: the way into the game, plus an optional "is everything
## plugged in?" check (hidden until you click "test your keys and gamepad").
##
## The check proves that the 3D renderer works on this computer, the tuning
## file and player settings load, and every keyboard, mouse and gamepad
## input reaches the game. (The full list of controls is in the Esc menu.) "Press Start" carries on your saved game
## (or wakes you up in your apartment for a new one); the small buttons below
## start over, or jump straight into flying.


## Friendly names for Godot's three renderers.
const RENDERER_NAMES: Dictionary = {
	"forward_plus": "Forward+",
	"mobile": "Mobile",
	"gl_compatibility": "Compatibility",
}
const FLIGHT_SCENE: String = "res://scenes/flight/FlightSandbox.tscn"
const CHIP_IDLE_COLOR := Color(1.0, 1.0, 1.0, 0.08)
const CHIP_LIT_COLOR := Color(1.0, 0.62, 0.28, 0.95)

@onready var _crate: Node3D = $Crate
@onready var _steer_stick: StickView = %SteerStick
@onready var _steer_caption: Label = %SteerCaption
@onready var _mouse_stick: StickView = %MouseStick
@onready var _mouse_caption: Label = %MouseCaption
@onready var _chips_box: Container = %Chips
@onready var _device_label: Label = %DeviceLabel
@onready var _invert_y_toggle: CheckButton = %InvertY
@onready var _saved_note: Label = %SavedNote
@onready var _system_info: Label = %SystemInfo
@onready var _start_button: Button = %StartFlying
@onready var _fly_button: Button = %FlySandbox
@onready var _new_game_button: Button = %NewGame
@onready var _input_check_button: Button = %InputCheck
@onready var _input_panel: Control = %InputPanel

var _time := 0.0
var _crate_home_height := 0.0
var _last_device := "nothing yet"
var _steer_smoothed := Vector2.ZERO
## The mouse acts like a virtual thumbstick: moving the mouse pushes this around.
var _mouse_virtual_stick := Vector2.ZERO
var _mouse_smoothed := Vector2.ZERO
## Action name -> the chip background we light up while it's pressed.
var _chip_styles: Dictionary = {}
var _saved_note_tween: Tween
var _starting: bool = false  # Already on our way into the game.


func _ready() -> void:
	_crate_home_height = _crate.position.y
	_show_system_info()
	_build_action_chips()
	_refresh_device_label()
	_saved_note.modulate.a = 0.0

	# Show the saved setting first, THEN start listening, so loading the
	# screen doesn't count as "changing" the setting.
	_invert_y_toggle.button_pressed = Settings.invert_y
	_invert_y_toggle.toggled.connect(Settings.set_invert_y)
	Events.settings_changed.connect(_on_settings_changed)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_start_button.pressed.connect(_start_game)
	_new_game_button.pressed.connect(_new_game)
	_new_game_button.visible = SaveSystem.has_save()
	if SaveSystem.has_save():
		_start_button.text = "PRESS START TO CONTINUE  (Enter / gamepad Start / click here)"
	_fly_button.pressed.connect(_start_flying)
	_input_check_button.pressed.connect(_toggle_input_check)
	_add_window_options()


func _process(delta: float) -> void:
	_time += delta
	_float_crate()
	_start_button.modulate.a = 0.7 + 0.3 * sin(_time * 3.0)  # A gentle "press start" pulse.

	var tuning := GameState.tuning
	# "1 - exp(-speed * delta)" is a smoothing trick that feels the same
	# whether the game runs at 30 or 240 frames per second.
	var catch_up := 1.0 - exp(-tuning.steer_response * delta)

	var steer := Input.get_vector("steer_left", "steer_right", "steer_up", "steer_down", tuning.stick_deadzone)
	_steer_smoothed = _steer_smoothed.lerp(steer, catch_up)
	_steer_stick.show_input(steer, _steer_smoothed, tuning.stick_deadzone)
	_steer_caption.text = _describe_steering(_steer_smoothed)

	var recenter := 1.0 - exp(-tuning.mouse_recenter_speed * delta)
	_mouse_virtual_stick = _mouse_virtual_stick.lerp(Vector2.ZERO, recenter)
	_mouse_smoothed = _mouse_smoothed.lerp(_mouse_virtual_stick, catch_up)
	_mouse_stick.show_input(_mouse_virtual_stick, _mouse_smoothed, 0.0)
	_mouse_caption.text = _describe_steering(_mouse_smoothed)

	for action: StringName in _chip_styles:
		var style: StyleBoxFlat = _chip_styles[action]
		style.bg_color = CHIP_IDLE_COLOR.lerp(CHIP_LIT_COLOR, Input.get_action_strength(action))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# screen_relative = how far the mouse moved in real screen pixels,
		# so the feel doesn't change when the window is resized.
		var motion := event as InputEventMouseMotion
		_mouse_virtual_stick += motion.screen_relative * GameState.tuning.mouse_sensitivity
		_mouse_virtual_stick = _mouse_virtual_stick.limit_length(1.0)
		_set_last_device("keyboard & mouse")
	elif event is InputEventKey or event is InputEventMouseButton:
		_set_last_device("keyboard & mouse")
	elif event is InputEventJoypadButton:
		_set_last_device("gamepad")
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5:
		_set_last_device("gamepad")


func _unhandled_input(event: InputEvent) -> void:
	# "Press Start": Enter on a keyboard, or the Start button on a gamepad.
	# (Not Space or A: those are for trying out boost on the input check.)
	var key := event as InputEventKey
	var button := event as InputEventJoypadButton
	var enter_pressed := key != null and key.pressed and not key.echo and key.keycode in [KEY_ENTER, KEY_KP_ENTER]
	var start_pressed := button != null and button.pressed and button.button_index == JOY_BUTTON_START
	if enter_pressed or start_pressed:
		_start_game()


## Carries on the saved game in the room you were last in, or starts a
## new one.
func _start_game() -> void:
	if _starting:
		return
	_starting = true
	if GameState.load_game() and not GameState.current_room.is_empty():
		LoadingScreen.go(get_tree(), GameState.current_room, "start")
	else:
		_new_game()


## Forgets the save and starts the opening: at the wheel, just after a
## delivery, on the way to the truck stop to collect the check.
func _new_game() -> void:
	_starting = true
	SaveSystem.delete_save()
	GameState.new_game()
	GameState.show_date_card = true
	LoadingScreen.go(get_tree(), FLIGHT_SCENE, "flight")


## Shows or hides the input check (and the system info under it).
func _toggle_input_check() -> void:
	_input_panel.visible = not _input_panel.visible
	_system_info.visible = _input_panel.visible


func _start_flying() -> void:
	GameState.load_game()
	LoadingScreen.go(get_tree(), FLIGHT_SCENE, "flight")


## Turns a steering input into words, respecting the invert Y setting.
func _describe_steering(stick: Vector2) -> String:
	var parts := PackedStringArray()
	var pitch := Settings.pitch_from_vertical_input(stick.y)
	if pitch > 0.2:
		parts.append("nose up")
	elif pitch < -0.2:
		parts.append("nose down")
	if stick.x < -0.2:
		parts.append("turn left")
	elif stick.x > 0.2:
		parts.append("turn right")
	if parts.is_empty():
		return "straight ahead"
	return ", ".join(parts)


## A lazy spin with a gentle bob, like it's drifting in zero-g.
func _float_crate() -> void:
	_crate.rotation = Vector3(sin(_time * 0.7) * 0.18, _time * 0.45, sin(_time * 0.5) * 0.1)
	_crate.position.y = _crate_home_height + sin(_time * 1.3) * 0.05


func _build_action_chips() -> void:
	for action: StringName in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue  # Godot's built-in menu actions, not ours.
		var style := StyleBoxFlat.new()
		style.bg_color = CHIP_IDLE_COLOR
		style.set_corner_radius_all(8)
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		style.content_margin_top = 3.0
		style.content_margin_bottom = 4.0
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", style)
		var lines := VBoxContainer.new()
		lines.add_theme_constant_override("separation", -2)
		lines.add_child(_make_label(String(action).capitalize(), 16, Color.WHITE))
		lines.add_child(_make_label(InputHints.for_action(action), 16, Color(1.0, 1.0, 1.0, 0.6)))
		chip.add_child(lines)
		_chips_box.add_child(chip)
		_chip_styles[action] = style


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _show_system_info() -> void:
	var method := RenderingServer.get_current_rendering_method()
	var renderer: String = RENDERER_NAMES.get(method, method)
	var gpu := RenderingServer.get_video_adapter_name()
	if gpu.is_empty():
		gpu = "no GPU (headless)"
	var tuning := GameState.tuning
	_system_info.text = "Godot %s  ·  %s renderer  ·  %s\nTuning loaded (stick deadzone %.2f, steer response %.1f)  ·  Settings file: %s" % [
		Engine.get_version_info()["string"],
		renderer,
		gpu,
		tuning.stick_deadzone,
		tuning.steer_response,
		ProjectSettings.globalize_path(Settings.SETTINGS_PATH),
	]


func _set_last_device(device_name: String) -> void:
	if device_name == _last_device:
		return
	_last_device = device_name
	_refresh_device_label()


func _refresh_device_label() -> void:
	var pads := Input.get_connected_joypads()
	var pad_text := "no gamepad plugged in"
	if not pads.is_empty():
		pad_text = "gamepad: " + Input.get_joy_name(pads[0])
		if pads.size() > 1:
			pad_text += " (+%d more)" % (pads.size() - 1)
	_device_label.text = "Last used: %s   ·   %s" % [_last_device, pad_text]


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_device_label()


## Flash a little "Saved!" note so it's obvious the setting stuck.
func _on_settings_changed() -> void:
	if _saved_note_tween:
		_saved_note_tween.kill()
	_saved_note.modulate.a = 1.0
	_saved_note_tween = create_tween()
	_saved_note_tween.tween_interval(1.2)
	_saved_note_tween.tween_property(_saved_note, "modulate:a", 0.0, 0.8)


var _fullscreen_button: Button
var _ui_size_button: Button


## Fullscreen on/off and the menu and HUD size, under the input check button.
func _add_window_options() -> void:
	_fullscreen_button = _input_check_button.duplicate(0) as Button
	_fullscreen_button.name = "Fullscreen"
	_fullscreen_button.unique_name_in_owner = false
	_input_check_button.add_sibling(_fullscreen_button)
	_fullscreen_button.pressed.connect(Settings.toggle_fullscreen)
	_ui_size_button = _input_check_button.duplicate(0) as Button
	_ui_size_button.name = "UiSize"
	_ui_size_button.unique_name_in_owner = false
	_fullscreen_button.add_sibling(_ui_size_button)
	_ui_size_button.pressed.connect(func() -> void: Settings.set_ui_size((Settings.ui_size + 1) % Settings.UI_SCALES.size()))
	_show_window_options()
	Events.settings_changed.connect(_show_window_options)


func _show_window_options() -> void:
	_fullscreen_button.text = "FULLSCREEN: %s  (F11 / Alt+Enter, any time)" % ("ON" if Settings.fullscreen else "OFF")
	_ui_size_button.text = "MENU AND HUD SIZE: %s" % Settings.UI_SIZE_NAMES[Settings.ui_size]
