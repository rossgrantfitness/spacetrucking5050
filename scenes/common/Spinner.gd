extends Node3D
## Turns slowly and forever around one of its own axes: a roulette wheel, a
## sign, a fan. Set `axis` and `speed` in the inspector.


## Which way it turns around (in its own space).
@export var axis := Vector3.UP
## How fast it turns, in radians per second.
@export var speed: float = 0.1


func _process(delta: float) -> void:
	rotate_object_local(axis.normalized(), speed * delta)
