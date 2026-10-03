class_name SpeedLines
extends ColorRect
## Speed lines while boosting (and fading out while the boost speed bleeds
## off), never at normal speeds: if they showed at every high speed they'd be
## on all the time and stop meaning anything.
## The look lives in res://shaders/speed_lines.gdshader.


## The ship whose boost we watch. Set by FlightSandbox.
var ship: Ship
var _intensity := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Keep running while paused, so the lines can fade away behind the menu.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if ship == null:
		return
	var tuning := GameState.tuning
	# Full strength while boosting; afterwards they fade out as the extra
	# boost speed bleeds away.
	var boost_feel := maxf(ship.overspeed_ratio(), 1.0 if ship.flight.boosting else 0.0)
	var goal := 0.0 if get_tree().paused else tuning.speed_lines_strength * boost_feel
	_intensity = lerpf(_intensity, goal, 1.0 - exp(-tuning.speed_lines_response * delta))
	var lines := material as ShaderMaterial
	lines.set_shader_parameter("intensity", _intensity)
	lines.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
	visible = _intensity > 0.005
