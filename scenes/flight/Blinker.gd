extends Node3D
## Makes a light blink on and off, like the beacon on a truck's roof.


## Seconds for one full on-and-off cycle.
@export var period: float = 1.4
## How much of each cycle the light is on (0.3 = on for 30% of the time).
@export_range(0.0, 1.0, 0.05) var on_fraction: float = 0.3
## Shifts when this light blinks, so a row of lights doesn't blink in unison.
@export_range(0.0, 1.0, 0.05) var offset: float = 0.0

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	visible = fposmod(_time / period + offset, 1.0) < on_fraction
