class_name WhalePod
extends RoadsideThing
## A pod of space whales gliding slowly through the void, rolling gently as
## they swim, singing now and then. The Tidewater system's gimmick. Pure
## scenery: they're huge, slow and very polite.
##
## Each whale is the developer's Cosmic Leviathan model
## (art/models/space_whale.glb), turned nose-first and about WHALE_LENGTH
## long.


const SONG := preload("res://audio/generated/whale_song.wav")
const MODEL := preload("res://art/models/space_whale.glb")
## About how long a whale is, nose to tail, in meters (the model is 1 long).
const WHALE_LENGTH := 260.0

var _whales: Array[Node3D] = []
## Each whale's model, which sways as it swims.
var _bodies: Array[Node3D] = []
var _phase: Array[float] = []
var _time: float = 0.0
var _song: AudioStreamPlayer3D
var _next_song: float = 2.0


func _ready() -> void:
	var count := rng.randi_range(2, 4)
	var swim := travel.cross(Vector3.UP).normalized() * (1.0 if rng.randf() < 0.5 else -1.0)
	for i in count:
		var whale := Node3D.new()
		var size := rng.randf_range(0.8, 1.4)
		whale.position = Vector3(rng.randf_range(-300, 300), rng.randf_range(-120, 120), rng.randf_range(-300, 300))
		whale.scale = Vector3.ONE * size
		add_child(whale)
		whale.look_at(whale.global_position + swim, Vector3.UP)
		var body := MODEL.instantiate() as Node3D
		body.rotation.y = PI  # The model's nose points +Z; whales swim toward -Z.
		body.scale = Vector3.ONE * WHALE_LENGTH
		whale.add_child(body)
		_whales.append(whale)
		_bodies.append(body)
		_phase.append(rng.randf() * TAU)
	_song = EventKit.sound(self, SONG, 4.0, 4000.0)
	_song.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	show_on_radar("SPACE WHALES (POD OF %d)" % count, 250.0)


func _process(delta: float) -> void:
	_time += delta
	for i in _whales.size():
		var whale := _whales[i]
		whale.position += -whale.basis.z.normalized() * 12.0 * delta  # Gliding forward, slowly.
		if ship == null:
			whale.rotate_y(0.02 * delta)  # A pod that lives here swims in big lazy circles.
		whale.position.y += sin(_time * 0.3 + _phase[i]) * 3.0 * delta
		# A slow sway and roll as it swims (the model has no moving tail).
		_bodies[i].rotation.x = sin(_time * 0.8 + _phase[i]) * 0.06
		_bodies[i].rotation.z = sin(_time * 0.5 + _phase[i]) * 0.08
	_next_song -= delta
	if _next_song <= 0.0:
		_next_song = rng.randf_range(6.0, 14.0)
		_song.pitch_scale = rng.randf_range(0.75, 1.2)
		_song.play()
