class_name EngineHum
extends Node
## The ship's engine hum: four seamless sound loops playing together, with
## their pitch and volume bent every frame to follow the ship. Faster = higher
## and louder, turning = a little wobble, boosting = an extra growl. Place it
## as a child of a Ship.
##
## The loops are ordinary .wav files in res://audio/generated/ (made from pure
## math by tools/generate_engine_sounds.gd), so they can be swapped for real
## recordings any time.


## How quickly the sound glides to match the ship (higher = snappier).
const GLIDE: float = 8.0
## How many times per second the pitch wobbles while turning.
const WOBBLE_RATE: float = 4.5

## The four layers of the hum.
const LAYER_SOUNDS := {
	"drone": preload("res://audio/generated/engine_drone.wav"),
	"whine": preload("res://audio/generated/engine_whine.wav"),
	"air": preload("res://audio/generated/engine_air.wav"),
	"growl": preload("res://audio/generated/engine_growl.wav"),
}

var _ship: Ship
var _layers: Dictionary = {}  # Layer name -> its AudioStreamPlayer.
var _gains: Dictionary = {}  # Layer name -> current volume, 0 to 1.
var _pitch := 1.0
var _time := 0.0


func _ready() -> void:
	_ship = get_parent() as Ship
	# Keep running while paused, so the hum can fade out softly instead of
	# cutting off with a click.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for layer_name: String in LAYER_SOUNDS:
		var player := AudioStreamPlayer.new()
		player.name = layer_name.capitalize()
		player.stream = LAYER_SOUNDS[layer_name]
		player.volume_db = -80.0
		add_child(player)
		player.play()
		_layers[layer_name] = player
		_gains[layer_name] = 0.0


func _process(delta: float) -> void:
	if _ship == null:
		return
	_time += delta
	var tuning := GameState.tuning
	var flight := _ship.flight
	var speed := clampf(_ship.speed_ratio(), 0.0, 1.6)
	var effort := maxf(flight.throttle, minf(speed, 1.0))
	var paused := get_tree().paused

	# How loud each layer wants to be right now (0 to 1).
	var wanted := {
		"drone": 0.35 + 0.4 * effort + (0.1 if flight.boosting else 0.0),
		"whine": 0.3 * minf(speed, 1.3),
		"air": tuning.engine_whoosh * speed,
		"growl": 0.35 if flight.boosting else 0.0,
	}
	var glide := 1.0 - exp(-GLIDE * delta)
	var wanted_pitch := _ship.ship_data.engine_pitch * lerpf(tuning.engine_idle_pitch, tuning.engine_top_pitch, speed)
	_pitch = lerpf(_pitch, wanted_pitch, glide)
	var wobble := 1.0 + tuning.engine_turn_wobble * absf(flight.turn_amount(_ship.ship_data)) * sin(TAU * WOBBLE_RATE * _time)

	for layer_name: String in _layers:
		var goal: float = 0.0 if paused else wanted[layer_name]
		_gains[layer_name] = lerpf(_gains[layer_name], goal, glide)
		var player: AudioStreamPlayer = _layers[layer_name]
		player.pitch_scale = clampf(_pitch * wobble, 0.05, 4.0)
		player.volume_db = linear_to_db(maxf(_gains[layer_name], 0.0001)) + tuning.engine_volume_db
