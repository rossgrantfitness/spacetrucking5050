class_name WhalePod
extends RoadsideThing
## A pod of space whales gliding slowly through the void, tails beating,
## glowing spots along their sides, singing now and then. The Tidewater
## system's gimmick. Pure scenery: they're huge, slow and very polite.


const SONG := preload("res://audio/generated/whale_song.wav")

var _whales: Array[Node3D] = []
var _tails: Array[Node3D] = []
var _phase: Array[float] = []
var _time: float = 0.0
var _song: AudioStreamPlayer3D
var _next_song: float = 2.0


func _ready() -> void:
	var count := rng.randi_range(2, 4)
	var skin := EventKit.paint(Color(0.28, 0.42, 0.62), 0.0, EventKit.HULL, 60.0)
	var belly := EventKit.paint(Color(0.75, 0.85, 0.9))
	var spots := EventKit.paint(Color(0.45, 1.0, 0.9), 2.0)
	var swim := travel.cross(Vector3.UP).normalized() * (1.0 if rng.randf() < 0.5 else -1.0)
	for i in count:
		var whale := Node3D.new()
		var size := rng.randf_range(0.8, 1.4)
		whale.position = Vector3(rng.randf_range(-300, 300), rng.randf_range(-120, 120), rng.randf_range(-300, 300))
		whale.scale = Vector3.ONE * size
		add_child(whale)
		whale.look_at(whale.global_position + swim, Vector3.UP)
		EventKit.ball(whale, 40.0, Vector3.ZERO, skin, Vector3(1.0, 0.85, 3.2))
		EventKit.ball(whale, 30.0, Vector3(0.0, -12.0, -20.0), belly, Vector3(1.0, 0.6, 2.6))
		for side: float in [-1.0, 1.0]:
			EventKit.box(whale, Vector3(60.0, 4.0, 22.0), Vector3(side * 50.0, -10.0, -30.0), skin, Vector3(0.0, side * 0.4, side * 0.3))
			for k in 4:
				EventKit.box(whale, Vector3(4.0, 4.0, 4.0), Vector3(side * 38.0, 6.0, -60.0 + k * 30.0), spots)
		var tail := Node3D.new()
		tail.position = Vector3(0.0, 0.0, 120.0)
		whale.add_child(tail)
		EventKit.box(tail, Vector3(110.0, 4.0, 30.0), Vector3(0.0, 0.0, 15.0), skin)
		_whales.append(whale)
		_tails.append(tail)
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
		_tails[i].rotation.x = sin(_time * 0.8 + _phase[i]) * 0.35
	_next_song -= delta
	if _next_song <= 0.0:
		_next_song = rng.randf_range(6.0, 14.0)
		_song.pitch_scale = rng.randf_range(0.75, 1.2)
		_song.play()
