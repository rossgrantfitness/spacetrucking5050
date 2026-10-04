class_name EngineFlare
extends MeshInstance3D
## A star-shaped lens flare on an engine nozzle that grows and flickers with
## the ship's speed, the way late-90s PlayStation racers did it.
##
## Put this on a marker at an engine nozzle, inside a ship that has
## speed_ratio() and trail_color() functions (like EngineTrail).


const FLARE_SHADER := preload("res://shaders/engine_flare.gdshader")
const FLARE_TEXTURE := preload("res://textures/generated/flare.png")

## The flare's size when cruising at top speed, in meters.
@export var size_at_top_speed: float = 9.0

var _source: Node3D
var _material := ShaderMaterial.new()
var _time := 0.0


func _ready() -> void:
	_source = EngineTrail.find_source(self)
	var quad := QuadMesh.new()
	mesh = quad
	_material.shader = FLARE_SHADER
	_material.set_shader_parameter("flare_texture", FLARE_TEXTURE)
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _source != null:
		_material.set_shader_parameter("color", _source.call("trail_color"))


func _process(delta: float) -> void:
	if _source == null:
		return
	_time += delta
	var speed := clampf(float(_source.call("speed_ratio")), 0.0, 2.0)
	# A little flicker, so the engine feels alive.
	var flicker := 1.0 + 0.06 * sin(_time * 37.0) + 0.04 * sin(_time * 23.0)
	var grow := (0.35 + 0.65 * minf(speed, 1.0) + 0.5 * maxf(speed - 1.0, 0.0)) * flicker
	scale = Vector3.ONE * size_at_top_speed * grow
	_material.set_shader_parameter("brightness", clampf(0.5 + speed * 0.7, 0.0, 1.6))


## Picks up the ship's trail color again (after a paint job).
func refresh_color() -> void:
	if _source != null:
		_material.set_shader_parameter("color", _source.call("trail_color"))
