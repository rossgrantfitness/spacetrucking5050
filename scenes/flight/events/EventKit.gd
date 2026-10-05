class_name EventKit
## Little helpers for building the things you pass in space (signs,
## landmarks, whales, big ships...) out of chunky shapes in code, with the
## PS1 look. Like the model builders in tools/, but at runtime, so events can
## be made on the fly.


const SURFACE_SHADER := preload("res://shaders/psx_surface.gdshader")
const HULL := preload("res://textures/generated/hull_panels.png")
const FLARE := preload("res://textures/generated/flare.png")
const ROCK := preload("res://textures/generated/rock.png")

static var _cache := {}


## A PS1 surface: a color, optionally a texture (projected from the sides,
## tiling every `meters`), and optionally glowing (`brightness` above 0).
static func paint(color: Color, brightness: float = 0.0, texture: Texture2D = null, meters: float = 4.0) -> ShaderMaterial:
	var key := "%s %s %s %s" % [color, brightness, texture.resource_path if texture else "", meters]
	if _cache.has(key):
		return _cache[key]
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	material.set_shader_parameter("albedo", color)
	if texture != null:
		material.set_shader_parameter("albedo_texture", texture)
		material.set_shader_parameter("uv_scale", Vector2.ONE / meters)
		material.set_shader_parameter("box_uv", true)
	if brightness > 0.0:
		material.set_shader_parameter("emission", color)
		material.set_shader_parameter("emission_strength", brightness)
	_cache[key] = material
	return material


static func box(parent: Node3D, size: Vector3, where: Vector3, material: Material, turn: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, where, edged(material, size), turn)


## The same material with painted bevels and shadow switched on (the hand-
## painted Mega Man Legends look, see shaders/painted_edges.gdshaderinc),
## sized for a box this big. Things that glow stay clean.
static func edged(material: Material, size: Vector3) -> Material:
	var shaded := material as ShaderMaterial
	if shaded == null or shaded.shader != SURFACE_SHADER:
		return material
	var glow: Variant = shaded.get_shader_parameter("emission_strength")
	if glow != null and float(glow) > 0.0:
		return material
	var smallest := minf(size.x, minf(size.y, size.z))
	var width := 0.2 if smallest < 4.0 else (1.5 if smallest < 40.0 else 6.0)
	var key := "edged %d %s" % [shaded.get_instance_id(), width]
	if not _cache.has(key):
		var with_edges := shaded.duplicate() as ShaderMaterial
		with_edges.set_shader_parameter("painted_edges", true)
		with_edges.set_shader_parameter("edge_width", width)
		with_edges.set_shader_parameter("edge_pixels_per_meter", 4.0 / width)
		with_edges.set_shader_parameter("edge_floor_reach", width * 6.0)
		_cache[key] = with_edges
	return _cache[key]


static func cylinder(parent: Node3D, radius: float, height: float, where: Vector3, material: Material,
		turn: Vector3 = Vector3.ZERO, sides: int = 10) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	return _add(parent, mesh, where, material, turn)


static func ball(parent: Node3D, radius: float, where: Vector3, material: Material, stretch: Vector3 = Vector3.ONE,
		hemisphere: bool = false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * (1.0 if hemisphere else 2.0)
	mesh.is_hemisphere = hemisphere
	mesh.radial_segments = 10
	mesh.rings = 5
	var part := _add(parent, mesh, where, material)
	part.scale = stretch
	return part


static func torus(parent: Node3D, inner: float, outer: float, where: Vector3, material: Material, turn: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 24
	mesh.ring_segments = 8
	return _add(parent, mesh, where, material, turn)


## Glowing lettering, readable from its +Z side (or always facing you, with
## `faces_you`).
static func sign(parent: Node3D, text: String, meters_per_pixel: float, color: Color, where: Vector3,
		faces_you: bool = false) -> Label3D:
	var label := Label3D.new()
	if faces_you:
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	else:
		label.double_sided = false  # Not mirrored through the back of a two-sided sign.
	label.text = text
	label.font_size = 96
	label.pixel_size = meters_per_pixel
	label.outline_size = 16
	label.modulate = color
	label.outline_modulate = Color(0.2, 0.05, 0.25)
	label.position = where
	parent.add_child(label)
	return label


## A soft glow that always faces the camera (for lamps, suns, comet heads).
static func glow(parent: Node3D, size: float, where: Vector3, color: Color) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.disable_fog = true
	material.albedo_texture = FLARE
	material.albedo_color = color
	material.no_depth_test = false
	quad.material = material
	var part := _add(parent, quad, where, null)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return part


## A 3D sound that follows the thing around, with the Doppler effect on (it
## rises in pitch as it comes at you and drops as it passes).
static func sound(parent: Node3D, stream: AudioStream, loudness_db: float, reach: float) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = loudness_db
	player.unit_size = reach * 0.1
	player.max_distance = reach
	player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	player.bus = "Master"
	parent.add_child(player)
	return player


## An invisible solid box, so you can bonk into the thing.
static func solid(parent: Node3D, size: Vector3, where: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = where
	body.add_child(shape)
	parent.add_child(body)
	return body


static func _add(parent: Node3D, mesh: Mesh, where: Vector3, material: Material, turn: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = where
	part.rotation = turn
	if material != null:
		part.material_override = material
	parent.add_child(part)
	return part
