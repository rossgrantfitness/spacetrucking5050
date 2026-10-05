class_name Explosion
extends Node3D
## The rig blowing up: a white flash, a fireball that swells and fades, a
## shockwave ring racing outward, and chunks of hull tumbling away. Built
## from chunky shapes in code (EventKit), PS1 style. Cleans itself up.


## How long it lasts before it removes itself, in seconds.
const LIFETIME: float = 7.0
const DEBRIS_COUNT: int = 22

var _time: float = 0.0
var _flash: MeshInstance3D
var _fireballs: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _debris: Array[MeshInstance3D] = []
var _debris_velocity: Array[Vector3] = []
var _debris_spin: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_flash = EventKit.glow(self, 45.0, Vector3.ZERO, Color(1.0, 0.97, 0.85))
	var fire_colors: Array[Color] = [Color(1.0, 0.85, 0.3), Color(1.0, 0.5, 0.15), Color(1.0, 0.25, 0.1)]
	for i in 3:
		var ball := EventKit.ball(self, 3.0 - i * 0.6, Vector3(_rng.randf_range(-3, 3), _rng.randf_range(-3, 3), _rng.randf_range(-3, 3)),
				EventKit.paint(fire_colors[i], 2.4))
		_fireballs.append(ball)
	_ring = EventKit.torus(self, 9.5, 10.0, Vector3.ZERO, EventKit.paint(Color(1.0, 0.6, 0.35), 1.4), Vector3(_rng.randf() * 0.6, 0.0, _rng.randf() * 0.6))
	var hull_colors: Array[Color] = [Color(0.55, 0.57, 0.62), Color(0.95, 0.75, 0.2), Color(0.2, 0.2, 0.24), Color(1.0, 0.5, 0.2)]
	for i in DEBRIS_COUNT:
		var size := Vector3(_rng.randf_range(0.6, 3.0), _rng.randf_range(0.3, 1.5), _rng.randf_range(0.6, 3.5))
		var chunk := EventKit.box(self, size, Vector3.ZERO, EventKit.paint(hull_colors[i % hull_colors.size()], 0.4 if i % 4 == 3 else 0.0))
		_debris.append(chunk)
		var direction := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized()
		_debris_velocity.append(direction * _rng.randf_range(15.0, 55.0))
		_debris_spin.append(Vector3(_rng.randf_range(-6, 6), _rng.randf_range(-6, 6), _rng.randf_range(-6, 6)))


func _process(delta: float) -> void:
	_time += delta
	# The flash: huge for a blink, then gone.
	_flash.scale = Vector3.ONE * maxf(1.0 - _time * 3.0, 0.0) * (1.0 + _time * 4.0)
	_flash.visible = _time < 0.35
	# The fireball swells, then shrinks away.
	var swell := 1.0 + 3.0 * (1.0 - exp(-_time * 4.0))
	var fade := clampf(1.0 - (_time - 0.6) / 1.4, 0.0, 1.0)
	for i in _fireballs.size():
		_fireballs[i].scale = Vector3.ONE * swell * fade * (1.0 + 0.15 * sin(_time * 30.0 + i))
		_fireballs[i].visible = fade > 0.0
	# The shockwave races outward and thins out.
	_ring.scale = Vector3.ONE * (1.0 + _time * 10.0)
	_ring.visible = _time < 0.9
	# Chunks of hull tumble away, slowly losing speed.
	for i in _debris.size():
		_debris[i].position += _debris_velocity[i] * delta
		_debris_velocity[i] *= exp(-0.3 * delta)
		var spin := _debris_spin[i]
		_debris[i].rotate(spin.normalized(), spin.length() * delta)
	if _time > LIFETIME:
		queue_free()
