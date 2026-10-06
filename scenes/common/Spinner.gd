extends Node3D
## Turns round and round, slowly (a radar dish, a sign). Nothing else.


## Turns per second.
@export var turns_per_second: float = 0.25


func _process(delta: float) -> void:
	rotate_y(TAU * turns_per_second * delta)
