class_name SkyBody
extends Node3D
## A huge faraway thing (a planet, a sun) sitting at its TRUE spot in space,
## which can be hundreds of kilometers away, much farther than the cameras
## can see. Each frame it's drawn closer, at a fixed distance in the same
## direction, and shrunk to match, so it looks exactly the right size. Fly
## toward it and it slowly grows; fly away and it shrinks behind you.
##
## Give it a `texture` and it builds its own ball (a planet, or a glowing
## sun with a halo). Or give it child models built at a radius of 1 meter
## (this script scales them) using res://shaders/psx_sky.gdshader, so the
## distance haze doesn't wash them out.


## Where it really is, in the world (meters).
@export var true_position := Vector3(0.0, 0.0, -100000.0)
## How big it really is (its radius, in meters).
@export var true_radius: float = 10000.0
## How fast it turns, in radians per second (just for looks).
@export var spin: float = 0.0
## Which solar system it belongs to, and whether it's that system's sun
## (suns light up the ships; see FlightSandbox.gd).
@export var system_id: String = "home"
@export var is_sun: bool = false

@export_group("Look")
## The surface picture, wrapped around the ball (leave empty if you put your
## own models inside instead).
@export var texture: Texture2D
## Multiplies the picture's colors.
@export var tint: Color = Color.WHITE
## How colorful it is: 1 = as painted, lower = more muted (0 = gray).
@export_range(0.0, 1.0, 0.05) var saturation: float = 1.0
## How many times the picture wraps around (x) and from pole to pole (y).
@export var uv_scale := Vector2(2.0, 1.0)
## How fast the clouds drift around it (just for looks).
@export var drift_speed: float = 0.002
## Glow on its dark side (suns glow all over).
@export_range(0.0, 2.0, 0.01) var night_glow: float = 0.15
## A model to use instead of the painted ball (like the developer's Cinder
## Moon): any size, it's centered and scaled to the radius, and drawn with
## the sky shader using the model's own picture (tinted by `tint`).
@export var model: PackedScene
## Planets: a flat ring around it, reaching out this many times its radius
## (0 = no ring).
@export var ring_size: float = 0.0
@export var ring_color: Color = Color(0.95, 0.85, 0.75)
@export var ring_tilt := Vector3(0.35, 0.0, 0.3)

const SKY_SHADER := preload("res://shaders/psx_sky.gdshader")
const FLARE_TEXTURE := preload("res://textures/generated/flare.png")

## The nearest sky body is drawn this far out, the next one a bit farther,
## and so on, so nearer bodies always cover farther ones. All of them stay
## inside the nebula backdrop (10.5 km) and in front of the stars (9 km).
const NEAREST_DRAW: float = 6000.0
const DRAW_STEP: float = 500.0

var _angle: float = 0.0


func _ready() -> void:
	add_to_group("sky_bodies")
	# We move every frame ourselves; Godot's motion smoothing would lag.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if model != null:
		_build_model()
	elif texture != null:
		_build_ball()


## The ball itself (radius 1), plus a halo for suns or a ring for planets.
func _build_ball() -> void:
	var material := ShaderMaterial.new()
	material.shader = SKY_SHADER
	material.set_shader_parameter("albedo", tint)
	material.set_shader_parameter("albedo_texture", texture)
	material.set_shader_parameter("uv_scale", uv_scale)
	material.set_shader_parameter("drift_speed", drift_speed)
	material.set_shader_parameter("night_glow", night_glow)
	material.set_shader_parameter("saturation", saturation)
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	sphere.material = material
	var ball := MeshInstance3D.new()
	ball.name = "Ball"
	ball.mesh = sphere
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ball)
	if is_sun:
		# A soft glow around the sun, always facing you.
		var halo := MeshInstance3D.new()
		halo.name = "Halo"
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * 7.0
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		glow.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		glow.albedo_texture = FLARE_TEXTURE
		glow.albedo_color = Color(tint, 1.0)
		glow.disable_fog = true
		glow.no_depth_test = false
		quad.material = glow
		halo.mesh = quad
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(halo)
	if ring_size > 0.0:
		var ring_material := ShaderMaterial.new()
		ring_material.shader = SKY_SHADER
		ring_material.set_shader_parameter("albedo", ring_color)
		ring_material.set_shader_parameter("night_glow", 0.3)
		ring_material.set_shader_parameter("saturation", saturation)
		var torus := TorusMesh.new()
		torus.inner_radius = 1.3
		torus.outer_radius = maxf(ring_size, 1.4)
		torus.rings = 32
		torus.ring_segments = 4
		torus.material = ring_material
		var ring := MeshInstance3D.new()
		ring.name = "Ring"
		ring.mesh = torus
		ring.rotation = ring_tilt
		ring.scale = Vector3(1.0, 0.02, 1.0)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)


## The model, centered and scaled to radius 1, its pictures moved onto the
## sky shader (so the distance haze doesn't wash it out).
func _build_model() -> void:
	var look := model.instantiate() as Node3D
	look.name = "Model"
	var meshes := look.find_children("*", "MeshInstance3D", true, false)
	var box := AABB()
	for i in meshes.size():
		var part := meshes[i] as MeshInstance3D
		var piece := _local_to(look, part) * part.get_aabb()
		box = piece if i == 0 else box.merge(piece)
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in part.mesh.get_surface_count():
			var source := part.get_active_material(surface) as BaseMaterial3D
			var material := ShaderMaterial.new()
			material.shader = SKY_SHADER
			material.set_shader_parameter("albedo", tint)
			if source != null and source.albedo_texture != null:
				material.set_shader_parameter("albedo_texture", source.albedo_texture)
			material.set_shader_parameter("night_glow", night_glow)
			material.set_shader_parameter("saturation", saturation)
			part.set_surface_override_material(surface, material)
	var size := maxf(box.size[box.size.max_axis_index()], 0.001)
	look.scale = Vector3.ONE * 2.0 / size
	look.position = -box.get_center() * look.scale
	add_child(look)


## `node`'s transform relative to `top` (works before they're in the tree).
static func _local_to(top: Node3D, node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var walker: Node = node
	while walker != null and walker != top:
		if walker is Node3D:
			result = (walker as Node3D).transform * result
		walker = walker.get_parent()
	return result


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	_angle += spin * delta
	var eye := camera.global_position
	var to_body := true_position - eye
	var distance := maxf(to_body.length(), 1.0)
	var draw := minf(distance, NEAREST_DRAW + DRAW_STEP * _rank(eye))
	global_transform = Transform3D(Basis(Vector3.UP, _angle).scaled(Vector3.ONE * true_radius * draw / distance),
			eye + to_body / distance * draw)


## How big it looks from `eye`, as an angle (radians, center to edge).
func apparent_size(eye: Vector3) -> float:
	return atan(true_radius / maxf(eye.distance_to(true_position), 1.0))


## Which way the light comes from, from `eye` (for suns).
func direction_from(eye: Vector3) -> Vector3:
	return (true_position - eye).normalized()


## How many other sky bodies are nearer to `eye` than this one.
func _rank(eye: Vector3) -> int:
	var mine := eye.distance_squared_to(true_position)
	var nearer := 0
	for other: SkyBody in get_tree().get_nodes_in_group("sky_bodies"):
		if other != self and eye.distance_squared_to(other.true_position) < mine:
			nearer += 1
	return nearer
