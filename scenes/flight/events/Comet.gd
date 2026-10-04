class_name Comet
extends RoadsideThing
## A comet streaking across the sky in the distance: a blazing head and a
## long glowing tail pointing away from the sun, with a soft whoosh.


const WHOOSH := preload("res://audio/generated/whoosh.wav")

var _velocity := Vector3.ZERO
var _travelled: float = 0.0


func _ready() -> void:
	var across := travel.cross(Vector3.UP).normalized() * (1.0 if rng.randf() < 0.5 else -1.0)
	var heading := (across + Vector3.UP * rng.randf_range(-0.3, 0.3)).normalized()
	global_position -= heading * 4000.0
	_velocity = heading * 450.0
	look_at(global_position + heading, Vector3.UP)
	EventKit.ball(self, 30.0, Vector3.ZERO, EventKit.paint(Color(0.85, 1.0, 1.0), 2.5))
	EventKit.glow(self, 260.0, Vector3.ZERO, Color(0.7, 1.0, 1.0))
	# The tail: a string of fading glows trailing behind (+Z).
	for i in 14:
		var fade := 1.0 - i / 14.0
		EventKit.glow(self, 220.0 * (0.6 + fade * 0.5), Vector3(0.0, 0.0, 60.0 + i * 70.0), Color(0.55, 0.85, 1.0, 0.6 * fade))
	var whoosh := EventKit.sound(self, WHOOSH, 2.0, 6000.0)
	whoosh.play()
	show_on_radar("COMET (NAMELESS, TAKEN)", 60.0)


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_travelled += _velocity.length() * delta


func is_done() -> bool:
	return _travelled > 8000.0
