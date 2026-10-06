class_name EngineExhaust
extends Node3D
## The flame out the back of an engine nozzle: two glowing cones (a wide
## colored flame and a white-hot core, see shaders/engine_plume.gdshader)
## that stretch with the throttle and roar out long and blue-white on boost,
## plus a stream of pixel sparks. It flickers, and a little flash pops when
## boost kicks in.
##
## The ship adds one to every "Nozzle" marker on its model (Ship.gd), so a
## new rig model only needs Nozzle markers on the backs of its engines.


const PLUME_SHADER := preload("res://shaders/engine_plume.gdshader")

## How wide the nozzle is (meters across the flame's start).
@export var radius: float = 1.2
## How long the flame is at full throttle (meters); boost stretches it.
@export var length: float = 9.0

var _ship: Ship
var _outer := ShaderMaterial.new()
var _inner := ShaderMaterial.new()
var _outer_cone: MeshInstance3D
var _inner_cone: MeshInstance3D
var _sparks: CPUParticles3D
var _power := 0.0
var _boost := 0.0
var _kick := 0.0
var _was_boosting := false


func _ready() -> void:
	_ship = EngineTrail.find_source(self) as Ship
	_outer_cone = _cone("Flame", radius, _outer, false)
	_inner_cone = _cone("Core", radius * 0.45, _inner, true)
	_sparks = _make_sparks()
	refresh_color()


## Picks up the ship's trail color again (after a paint job).
func refresh_color() -> void:
	if _ship == null:
		return
	var color := _ship.trail_color()
	_outer.set_shader_parameter("color", color)
	_inner.set_shader_parameter("color", color.lightened(0.4))
	var sparks_mesh := _sparks.mesh as QuadMesh
	(sparks_mesh.material as StandardMaterial3D).albedo_color = color.lightened(0.5)


func _process(delta: float) -> void:
	if _ship == null:
		return
	var flight := _ship.flight
	# How hard the engines are working: the throttle, plus a little for speed.
	var working := clampf(maxf(flight.thrust, 0.0) * 0.8 + _ship.speed_ratio() * 0.25, 0.0, 1.0)
	if _ship.out_of_control or flight.fuel <= 0.0:
		working *= 0.3
	_power = lerpf(_power, working, 1.0 - exp(-8.0 * delta))
	_boost = lerpf(_boost, 1.0 if flight.boosting else 0.0, 1.0 - exp(-6.0 * delta))
	if flight.boosting and not _was_boosting:
		_kick = 1.0  # Boost kicking in: a big flash.
	_was_boosting = flight.boosting
	_kick = maxf(_kick - delta * 3.0, 0.0)
	var stretch := 0.25 + _power * 0.75 + _boost * 1.3 + _kick * 0.8
	# A lively, ragged flame: its length and width jitter a little.
	var now := Time.get_ticks_msec() * 0.001
	stretch *= 1.0 + 0.08 * sin(now * 53.0) * sin(now * 17.0)
	var wobble := 1.0 + 0.07 * sin(now * 41.0 + radius)
	_place(_outer_cone, length * stretch, (1.0 + _kick * 0.5 + _boost * 0.15) * wobble)
	_place(_inner_cone, length * stretch * 0.55, 1.0 + _kick * 0.3)
	for material: ShaderMaterial in [_outer, _inner]:
		material.set_shader_parameter("power", clampf(_power + _kick, 0.0, 1.5))
		material.set_shader_parameter("boost", _boost)
	_sparks.emitting = _power > 0.15 or _boost > 0.1
	_sparks.initial_velocity_min = 20.0 + 40.0 * _power + 60.0 * _boost
	_sparks.initial_velocity_max = _sparks.initial_velocity_min * 1.6


## Stretches a cone to `flame_length`, its wide end at the nozzle, pointing back.
func _place(cone: MeshInstance3D, flame_length: float, width: float) -> void:
	cone.scale = Vector3(width, flame_length, width)
	cone.position = Vector3(0.0, 0.0, flame_length * 0.5)


func _cone(cone_name: String, cone_radius: float, material: ShaderMaterial, is_core: bool) -> MeshInstance3D:
	material.shader = PLUME_SHADER
	material.set_shader_parameter("core", is_core)
	var mesh := CylinderMesh.new()
	mesh.top_radius = cone_radius  # +Y end: the nozzle.
	mesh.bottom_radius = cone_radius * 0.15
	mesh.height = 1.0  # Stretched to the flame's length by scale.
	mesh.radial_segments = 8  # Chunky, PS1 style.
	mesh.rings = 1
	mesh.cap_top = false
	mesh.cap_bottom = false
	var cone := MeshInstance3D.new()
	cone.name = cone_name
	cone.mesh = mesh
	cone.material_override = material
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Turn the cylinder's +Y (the nozzle end) to point forward (-Z), so the
	# flame trails out behind.
	cone.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	add_child(cone)
	return cone


## Little square sparks shooting out the back (left behind in space, so
## they streak away as the rig flies on).
func _make_sparks() -> CPUParticles3D:
	var sparks := CPUParticles3D.new()
	sparks.name = "Sparks"
	sparks.amount = 28
	sparks.lifetime = 0.6
	sparks.local_coords = false
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = radius * 0.5
	sparks.direction = Vector3(0.0, 0.0, 1.0)
	sparks.spread = 7.0
	sparks.gravity = Vector3.ZERO
	sparks.scale_amount_min = 0.5
	sparks.scale_amount_max = 1.2
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 0.9, 1.0))
	fade.set_color(1, Color(1.0, 0.6, 0.2, 0.0))
	sparks.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.35, 0.35)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = material
	sparks.mesh = quad
	add_child(sparks)
	return sparks
