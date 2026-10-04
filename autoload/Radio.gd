extends Node
## The cockpit radio: stations, DJs, fake ads, and the player's own music.
##
## For now (before M4) the radio has stations but no music: each station
## "plays" placeholder song titles and surreal ads from its data file in
## res://data/radio/, which the HUD's radio ticker scrolls. Flip stations in
## flight with Q / E (D-pad left / right) for a burst of tuning static.
##
## M4 adds the music itself, DJs, ambient music when the radio is off, and
## a custom station: players will drop their own .ogg or .mp3 files into
## user://radio/custom/.
##
## There is deliberately no streaming-service integration (see CLAUDE.md).


## Emitted when the player tunes to another station.
signal station_changed

const STATIC := preload("res://audio/generated/static.wav")

## The stations on the dial (see res://data/radio/lineup.tres).
var lineup: RadioLineup = preload("res://data/radio/lineup.tres")
## Which station is tuned in.
var station_index: int = 0
## How clear the signal is, 1 = crystal, 0 = nothing but static. Solar
## storms (M5) will lower it.
var signal_strength: float = 1.0

# Stations keep broadcasting while you're away, like real radio: what's on
# air depends on how long the game has been running.
var _clock: float = 0.0
var _static: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_static = AudioStreamPlayer.new()
	_static.stream = STATIC
	_static.volume_db = -12.0
	add_child(_static)


func _process(delta: float) -> void:
	_clock += delta


func station() -> RadioStation:
	return lineup.stations[station_index]


## What's on air right now: "ARTIST - TITLE", or "AD: ..." for an ad.
func now_playing() -> String:
	return station().on_air(_clock + station_index * 37.0)


func next_station() -> void:
	_tune(1)


func previous_station() -> void:
	_tune(-1)


func _tune(step: int) -> void:
	station_index = posmod(station_index + step, lineup.stations.size())
	_static.pitch_scale = randf_range(0.9, 1.15)
	_static.play()
	station_changed.emit()
