extends Node
## The player's comfort options (invert Y, and later: camera roll, screen
## shake, FOV, rumble, HUD, volume...).
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
	save_settings()
	Events.settings_changed.emit()


func save_settings() -> void:
	SaveSystem.write_json(SETTINGS_PATH, {
		"version": SETTINGS_VERSION,
		"invert_y": invert_y,
	})


func load_settings() -> void:
	apply_saved_data(SaveSystem.read_json(SETTINGS_PATH))


## Copies values from a loaded settings file into memory. Anything missing
## (like on the very first launch) or of the wrong type (say, from a
## hand-edited file) keeps its current value.
func apply_saved_data(data: Dictionary) -> void:
	var saved_invert_y: Variant = data.get("invert_y")
	if saved_invert_y is bool:
		invert_y = saved_invert_y
