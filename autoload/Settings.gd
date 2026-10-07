extends Node
## The player's comfort options: invert Y, camera roll, HUD on/off, screen
## shake, rumble, volumes, and the window: fullscreen or windowed, the
## window's size and place, and how big the menus and HUD are.
##
## These belong to the PLAYER, not to one save slot, so they live in their
## own little file, user://settings.json, and save themselves on every change.
##
## (Not to be confused with res://data/tuning.tres, which holds the
## developer's feel numbers like steering speed. Players don't see tuning.)


const SETTINGS_PATH: String = "user://settings.json"
## Bump this if the layout of settings.json ever changes.
const SETTINGS_VERSION: int = 1

## false: push the stick (or mouse) UP to point the nose UP. "The ship goes
##        where it points." This is the default.
## true:  push UP to point the nose DOWN, like a real plane's control stick.
var invert_y: bool = false

## false: the camera stays level while the rig leans into turns (default;
##        much kinder to motion-sensitive players).
## true:  the chase camera leans along with the rig.
var camera_roll: bool = false

## Whether the corner gauges and the station marker are shown while flying.
var show_hud: bool = true

## PRO DOCKING. false (default): fly through a station's ring and the
## autopilot docks you. true: you park in the loading bay yourself, for a
## tip from the dock crew (bigger if you back in, like a real trucker).
var pro_docking: bool = false

## Whether the camera shakes (boost kicks and bonks).
var screen_shake: bool = true

## Whether a gamepad rumbles when you bonk into things.
var rumble: bool = true

## How loud the radio (and the ambient music when it's off) is, 0 to 1.
var radio_volume: float = 0.8
## How loud the sound effects are (the engine, boost, bonks, everything
## that isn't music or voices), 0 to 1. A bit under the music by default:
## cruising with the radio on is the heart of the game.
var sfx_volume: float = 0.7
## How loud the characters' gibberish voices are, 0 to 1.
var voice_volume: float = 0.9

## The window. The game starts the way you left it (windowed the first
## time). Windowed, you can drag the window to any size: the game fills it,
## no black bars (wide windows show more to the sides). F11 or Alt+Enter
## flips between windowed and fullscreen (borderless: quick to switch, and
## friendly to other monitors).
var fullscreen: bool = false
## The window's size and place when windowed (remembered between sessions;
## zero = not set yet, use the default 1280 x 720, centered).
var window_size := Vector2i.ZERO
var window_position := Vector2i.ZERO
var has_window_position: bool = false
## How big menus, text and the HUD are: 0 small, 1 medium, 2 large.
var ui_size: int = 1

## The smallest the window can be dragged.
const MIN_WINDOW_SIZE := Vector2i(640, 360)
## How much each UI size scales menus, text and the HUD.
const UI_SCALES: Array[float] = [0.8, 1.0, 1.25]
const UI_SIZE_NAMES: Array[String] = ["SMALL", "MEDIUM", "LARGE"]

## The mixer channels (buses) the sound effects and voices play through.
## Music has its own ("Radio" and "Ambient", made by the Radio).
const SFX_BUS: String = "SFX"
const VOICE_BUS: String = "Voice"


func _ready() -> void:
	_make_bus(SFX_BUS)
	_make_bus(VOICE_BUS)
	load_settings()
	_apply_volumes()
	process_mode = Node.PROCESS_MODE_ALWAYS  # (F11 works in paused menus too.)
	_apply_window.call_deferred()
	get_tree().root.size_changed.connect(_on_window_resized)
	get_tree().node_added.connect(_fit_camera)
	# Every sound that isn't sent anywhere in particular is a sound effect:
	# route it through the SFX channel, so the slider controls it.
	get_tree().node_added.connect(_route_sound)


## Turns an up/down input (stick, arrow keys or mouse) into a nose direction,
## respecting invert Y. Returns a positive number for "nose up" and a negative
## number for "nose down".
## Note: Godot reports pushing a stick UP as a NEGATIVE number, hence the flip.
func pitch_from_vertical_input(vertical: float) -> float:
	var nose_up := -vertical
	return -nose_up if invert_y else nose_up


func set_invert_y(enabled: bool) -> void:
	invert_y = enabled
	_changed()


func set_camera_roll(enabled: bool) -> void:
	camera_roll = enabled
	_changed()


func set_show_hud(enabled: bool) -> void:
	show_hud = enabled
	_changed()


func set_pro_docking(enabled: bool) -> void:
	pro_docking = enabled
	_changed()


func set_screen_shake(enabled: bool) -> void:
	screen_shake = enabled
	_changed()


func set_rumble(enabled: bool) -> void:
	rumble = enabled
	_changed()


func set_radio_volume(volume: float) -> void:
	radio_volume = clampf(volume, 0.0, 1.0)
	_changed()


func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)
	_apply_volumes()
	_changed()


func set_voice_volume(volume: float) -> void:
	voice_volume = clampf(volume, 0.0, 1.0)
	_apply_volumes()
	_changed()


## Fullscreen on or off (borderless fullscreen).
func set_fullscreen(enabled: bool) -> void:
	if not enabled and fullscreen:
		fullscreen = false
		_apply_window()
	else:
		_remember_window()
		fullscreen = enabled
		_apply_window()
	_changed()


func toggle_fullscreen() -> void:
	set_fullscreen(not fullscreen)


## How big menus, text and the HUD are (0 small, 1 medium, 2 large).
func set_ui_size(size: int) -> void:
	ui_size = clampi(size, 0, UI_SCALES.size() - 1)
	_apply_ui_scale()
	_changed()


## The UI size as a number: how much bigger than usual (1 = medium).
func ui_scale() -> float:
	return UI_SCALES[clampi(ui_size, 0, UI_SCALES.size() - 1)]


## F11, or Alt+Enter: fullscreen on / off, anywhere in the game.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F11 or (key.alt_pressed and key.keycode in [KEY_ENTER, KEY_KP_ENTER]):
		get_viewport().set_input_as_handled()
		toggle_fullscreen()


## Puts the window the way the settings say: fullscreen, or windowed at the
## remembered size and place (kept on screen), never smaller than the minimum.
func _apply_window() -> void:
	_apply_ui_scale()
	if DisplayServer.get_name() == "headless":
		return  # (The automated tests have no window.)
	var window := get_window()
	window.min_size = MIN_WINDOW_SIZE
	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
		return
	window.mode = Window.MODE_WINDOWED
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	if window_size.x >= MIN_WINDOW_SIZE.x and window_size.y >= MIN_WINDOW_SIZE.y:
		window.size = Vector2i(mini(window_size.x, usable.size.x), mini(window_size.y, usable.size.y))
	var spot_ok := false
	if has_window_position:
		for i in DisplayServer.get_screen_count():
			if DisplayServer.screen_get_usable_rect(i).grow(-40).has_point(window_position + Vector2i(40, 40)):
				spot_ok = true
	if spot_ok:
		window.position = window_position
	else:
		window.position = usable.position + Vector2i((Vector2(usable.size - window.size) * 0.5).round())


func _apply_ui_scale() -> void:
	get_tree().root.content_scale_factor = ui_scale()


## Remembers the window's size and place (when windowed) for next time.
func _remember_window() -> void:
	if DisplayServer.get_name() == "headless" or fullscreen:
		return
	var window := get_window()
	if window.mode != Window.MODE_WINDOWED:
		return
	window_size = window.size
	window_position = window.position
	has_window_position = true


var _resize_save_timer: SceneTreeTimer


func _on_window_resized() -> void:
	# Tall windows: cameras keep their width (see _fit_camera).
	for camera in get_tree().root.find_children("*", "Camera3D", true, false):
		_fit_camera(camera)
	# Remember the new size a moment after the dragging stops.
	if _resize_save_timer == null or _resize_save_timer.time_left <= 0.0:
		_resize_save_timer = get_tree().create_timer(1.0, true)
		_resize_save_timer.timeout.connect(func() -> void:
			_remember_window()
			save_settings())


## Cameras show the same width of the world whatever the window's shape...
## in a wide window they keep their height (and show more to the sides);
## in a tall one they keep their width (and show more above and below),
## instead of shrinking to a slit.
func _fit_camera(node: Node) -> void:
	var camera := node as Camera3D
	if camera == null or camera.get_viewport() != get_tree().root:
		return
	var size := get_tree().root.get_visible_rect().size
	camera.keep_aspect = Camera3D.KEEP_WIDTH if size.y > size.x else Camera3D.KEEP_HEIGHT


var _window_check: float = 0.0


## Every couple of seconds: if the window's been moved or resized (windowed),
## remember where it is now.
func _process(delta: float) -> void:
	_window_check += delta
	if _window_check < 2.0 or DisplayServer.get_name() == "headless" or fullscreen:
		return
	_window_check = 0.0
	var window := get_window()
	if window.mode == Window.MODE_WINDOWED and (window.position != window_position or window.size != window_size):
		_remember_window()
		save_settings()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_remember_window()
		save_settings()


func _apply_volumes() -> void:
	for bus: Array in [[SFX_BUS, sfx_volume], [VOICE_BUS, voice_volume]]:
		var index := AudioServer.get_bus_index(bus[0])
		if index != -1:
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(float(bus[1]), 0.0001)))


func _make_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _route_sound(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		if node.get("bus") == &"Master":
			node.set("bus", SFX_BUS)


## Off: settings changes aren't written to disk (smoke tests flip switches
## without touching the player's own choices).
var keep_changes: bool = true


func save_settings() -> void:
	if not keep_changes:
		return
	SaveSystem.write_json(SETTINGS_PATH, {
		"version": SETTINGS_VERSION,
		"invert_y": invert_y,
		"camera_roll": camera_roll,
		"show_hud": show_hud,
		"pro_docking": pro_docking,
		"screen_shake": screen_shake,
		"rumble": rumble,
		"radio_volume": radio_volume,
		"sfx_volume": sfx_volume,
		"voice_volume": voice_volume,
		"fullscreen": fullscreen,
		"window_size": [window_size.x, window_size.y],
		"window_position": [window_position.x, window_position.y],
		"has_window_position": has_window_position,
		"ui_size": ui_size,
	})


func load_settings() -> void:
	apply_saved_data(SaveSystem.read_json(SETTINGS_PATH))


## Copies values from a loaded settings file into memory. Anything missing
## (like on the very first launch) or of the wrong type (say, from a
## hand-edited file) keeps its current value.
func apply_saved_data(data: Dictionary) -> void:
	for option: String in ["invert_y", "camera_roll", "show_hud", "pro_docking", "screen_shake", "rumble", "fullscreen"]:
		var saved: Variant = data.get(option)
		if saved is bool:
			set(option, saved)
	for option: String in ["radio_volume", "sfx_volume", "voice_volume"]:
		var volume: Variant = data.get(option)
		if volume is float or volume is int:
			set(option, clampf(float(volume), 0.0, 1.0))
	var size: Variant = data.get("window_size")
	if size is Array and (size as Array).size() == 2:
		window_size = Vector2i(int(size[0]), int(size[1]))
	var spot: Variant = data.get("window_position")
	if spot is Array and (spot as Array).size() == 2 and data.get("has_window_position") == true:
		window_position = Vector2i(int(spot[0]), int(spot[1]))
		has_window_position = true
	var ui: Variant = data.get("ui_size")
	if ui is int or ui is float:
		ui_size = clampi(int(ui), 0, UI_SCALES.size() - 1)
	_apply_volumes()


func _changed() -> void:
	save_settings()
	Events.settings_changed.emit()
