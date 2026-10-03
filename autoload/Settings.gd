extends Node
## The player's comfort options: invert Y, camera roll, HUD on/off, screen
## shake, rumble, and later FOV, volume...
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

## Whether the camera shakes (boost kicks and bonks).
var screen_shake: bool = true

## Whether a gamepad rumbles when you bonk into things.
var rumble: bool = true


func _ready() -> void:
	load_settings()


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


func set_screen_shake(enabled: bool) -> void:
	screen_shake = enabled
	_changed()


func set_rumble(enabled: bool) -> void:
	rumble = enabled
	_changed()


func save_settings() -> void:
	SaveSystem.write_json(SETTINGS_PATH, {
		"version": SETTINGS_VERSION,
		"invert_y": invert_y,
		"camera_roll": camera_roll,
		"show_hud": show_hud,
		"screen_shake": screen_shake,
		"rumble": rumble,
	})


func load_settings() -> void:
	apply_saved_data(SaveSystem.read_json(SETTINGS_PATH))


## Copies values from a loaded settings file into memory. Anything missing
## (like on the very first launch) or of the wrong type (say, from a
## hand-edited file) keeps its current value.
func apply_saved_data(data: Dictionary) -> void:
	for option: String in ["invert_y", "camera_roll", "show_hud", "screen_shake", "rumble"]:
		var saved: Variant = data.get(option)
		if saved is bool:
			set(option, saved)


func _changed() -> void:
	save_settings()
	Events.settings_changed.emit()
