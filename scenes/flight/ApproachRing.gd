class_name ApproachRing
extends Node3D
## A big glowing ring floating in front of a docking bay. Fly through it and
## the autopilot takes over and docks you (see FlightSandbox.gd). It pulses
## gently, with lights chasing around it toward the bay.
##
## The ring faces along its own Z axis: fly through it along -Z (put it in
## front of the bay, rotated so its -Z points at the bay).


const SURFACE_SHADER := preload("res://shaders/psx_surface.gdshader")

## How big the hole is (radius, in meters). Generous: docking should be easy.
@export var radius: float = 60.0
@export var color: Color = Color(0.35, 0.95, 1.0)
## How many chasing lights go around it.
@export var light_count: int = 12

var _glow := ShaderMaterial.new()
var _lights: Array[MeshInstance3D] = []
var _time: float = 0.0


func _ready() -> void:
	_glow.shader = SURFACE_SHADER
	_glow.set_shader_parameter("albedo", color)
	_glow.set_shader_parameter("emission", color)
	_glow.set_shader_parameter("emission_strength", 1.5)
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = radius
	torus.outer_radius = radius + 5.0
	torus.rings = 32
	torus.ring_segments = 4
	torus.material = _glow
	ring.mesh = torus
	ring.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	add_child(ring)
	var bulb := BoxMesh.new()
	bulb.size = Vector3.ONE * 6.0
	for i in light_count:
		var light := MeshInstance3D.new()
		light.mesh = bulb
		var material := ShaderMaterial.new()
		material.shader = SURFACE_SHADER
		material.set_shader_parameter("albedo", Color.WHITE)
		material.set_shader_parameter("emission", Color(1.0, 0.85, 0.3))
		material.set_shader_parameter("emission_strength", 0.0)
		light.material_override = material
		var angle := TAU * i / light_count
		light.position = Vector3(cos(angle), sin(angle), 0.0) * (radius + 2.5)
		add_child(light)
		_lights.append(light)


func _process(delta: float) -> void:
	_time += delta
	_glow.set_shader_parameter("emission_strength", 1.2 + 0.5 * sin(_time * 2.5))
	# A light runs around the ring, again and again.
	var lead := fposmod(_time * 8.0, float(light_count))
	for i in _lights.size():
		var behind := fposmod(lead - i, float(light_count))
		var strength := maxf(0.0, 2.5 - behind * 0.8)
		(_lights[i].material_override as ShaderMaterial).set_shader_parameter("emission_strength", strength)


## Whether `point` (in the world) is passing through the ring's hole.
func is_inside(point: Vector3) -> bool:
	return hole_contains(to_local(point), radius)


## Whether a spot measured from the ring's middle is in its hole (within
## 25 m in front or behind, and inside the radius).
static func hole_contains(local: Vector3, hole_radius: float) -> bool:
	return absf(local.z) < 25.0 and Vector2(local.x, local.y).length() < hole_radius


## The direction you fly through it (toward the bay), in the world.
func through_direction() -> Vector3:
	return -global_basis.z
