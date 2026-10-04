class_name JellySwarm
extends RoadsideThing
## A cosmic jellyfish migration: dozens of soft glowing jellies drifting
## and pulsing across the lane. Drift through slowly and enjoy it (they're
## ghostly: you pass right through them).


var _jellies: Array[Node3D] = []
var _phase: Array[float] = []
var _sizes: Array[float] = []
var _time: float = 0.0
var _drift := Vector3.ZERO


func _ready() -> void:
	var colors: Array[Color] = [Color(1.0, 0.55, 0.9), Color(0.55, 0.95, 1.0), Color(0.75, 0.6, 1.0), Color(0.5, 1.0, 0.75)]
	_drift = travel.cross(Vector3.UP).normalized() * 6.0
	for i in 36:
		var jelly := Node3D.new()
		jelly.position = Vector3(rng.randf_range(-500, 500), rng.randf_range(-220, 220), rng.randf_range(-600, 600))
		var size := rng.randf_range(0.6, 1.8)
		jelly.scale = Vector3.ONE * size
		add_child(jelly)
		var color := colors[i % colors.size()]
		EventKit.ball(jelly, 14.0, Vector3.ZERO, EventKit.paint(color, 1.3), Vector3(1.0, 0.7, 1.0), true)
		for k in 5:
			var angle := TAU * k / 5.0
			EventKit.box(jelly, Vector3(1.2, 30.0, 1.2), Vector3(cos(angle) * 7.0, -16.0, sin(angle) * 7.0), EventKit.paint(color, 0.8))
		EventKit.glow(jelly, 70.0, Vector3.ZERO, Color(color, 0.5))
		_jellies.append(jelly)
		_phase.append(rng.randf() * TAU)
		_sizes.append(size)
	show_on_radar("JELLYFISH MIGRATION", 500.0)


func _process(delta: float) -> void:
	_time += delta
	position += _drift * delta
	for i in _jellies.size():
		var pulse := 1.0 + 0.12 * sin(_time * 1.6 + _phase[i])
		_jellies[i].scale = Vector3(pulse, 1.0 / pulse, pulse) * _sizes[i]  # Squish and stretch.
		_jellies[i].position.y += sin(_time * 0.7 + _phase[i]) * 2.0 * delta
