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

## How loud the radio (and the ambient music when it's off) is, 0 to 1.
var radio_volume: float = 0.8
## How loud the sound effects are (the engine, boost, bonks, everything
## that isn't music or voices), 0 to 1. A bit under the music by default:
## cruising with the radio on is the heart of the game.
var sfx_volume: float = 0.7
## How loud the characters' gibberish voices are, 0 to 1.
var voice_volume: float = 0.9

## The mixer channels (buses) the sound effects and voices play through.
## Music has its own ("Radio" and "Ambient", made by the Radio).
const SFX_BUS: String = "SFX"
const VOICE_BUS: String = "Voice"


func _ready() -> void:
	_make_bus(SFX_BUS)
	_make_bus(VOICE_BUS)
	load_settings()
	_apply_volumes()
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


func save_settings() -> void:
	SaveSystem.write_json(SETTINGS_PATH, {
		"version": SETTINGS_VERSION,
		"invert_y": invert_y,
		"camera_roll": camera_roll,
		"show_hud": show_hud,
		"screen_shake": screen_shake,
		"rumble": rumble,
		"radio_volume": radio_volume,
		"sfx_volume": sfx_volume,
		"voice_volume": voice_volume,
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
	for option: String in ["radio_volume", "sfx_volume", "voice_volume"]:
		var volume: Variant = data.get(option)
		if volume is float or volume is int:
			set(option, clampf(float(volume), 0.0, 1.0))
	_apply_volumes()


func _changed() -> void:
	save_settings()
	Events.settings_changed.emit()
