extends "res://tools/build_placeholder_models.gd"
## Builds the rig's crew from the developer's 3D models (.glb files from
## Meshy, in res://assets/characters/<folder>/source.glb), the same way
## tools/build_bunny.gd builds Jacki: each model is cut into rigid parts
## (legs, body, arms, head) hung on pivots that BunnyAnimator.gd swings,
## the T-pose arms are dropped to the sides, it's turned to face -Z, stood
## on the floor and sized. They're already chibi, so nothing is stretched.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_crew.gd
## The first time, it pulls each model's texture out into texture.png (shrunk
## to 512 pixels) and asks you to import and run it again.
##
## HOW THE CUTTING WORKS: these models are one solid piece, so each triangle
## goes to a part by where its middle is, using a few joint heights read off
## the model in its T-pose (model units: about 1 tall, centered on 0, facing
## +Z). Triangles behind `tail_z` (a tail) stay with the body. Add a
## character by adding an entry to CREW.


const ANIMATOR := "res://scenes/hub/BunnyAnimator.gd"
const ARM_DROP_DEGREES: float = 76.0

## One entry per crew model.
## neck: above this is the head. hip: below this are the legs.
## shoulder: (how far out the arms start, how high the shoulder joint is).
## arm_band: (lowest, highest) the T-pose arms reach.
## tail_z: anything further back than this is a tail (stays on the body).
const CREW: Array[Dictionary] = [
	{"name": "DottieVisual", "folder": "crew_a", "height": 1.15,
		"neck": 0.11, "hip": -0.18, "shoulder": Vector2(0.17, 0.05), "arm_band": Vector2(-0.1, 0.14), "tail_z": -0.12},
	{"name": "MoleVisual", "folder": "crew_b", "height": 0.95,
		"neck": 0.17, "hip": -0.2, "shoulder": Vector2(0.17, 0.12), "arm_band": Vector2(0.0, 0.2), "tail_z": -0.12},
	{"name": "DonkeyVisual", "folder": "crew_c", "height": 1.35,
		"neck": 0.18, "hip": -0.12, "shoulder": Vector2(0.18, 0.12), "arm_band": Vector2(0.03, 0.19), "tail_z": -0.1},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/hub/crew"))
	var waiting := false
	for entry in CREW:
		if not _extract_texture(entry):
			waiting = true
	if waiting:
		print("Textures extracted. Run:  godot --headless --path . --import  and then this script again.")
		quit()
		return
	for entry in CREW:
		_save(_build(entry), "res://scenes/hub/crew/%s.tscn" % entry["name"])
	quit()


## Saves the model's texture as a small PNG next to it (once). Returns
## whether it was already there and imported.
func _extract_texture(entry: Dictionary) -> bool:
	var folder := "res://assets/characters/%s" % entry["folder"]
	var png := folder + "/texture.png"
	if ResourceLoader.exists(png):
		return true
	var mesh := _source_mesh(entry)
	var material := mesh.surface_get_material(0) as BaseMaterial3D
	var image := (material.albedo_texture as Texture2D).get_image()
	if image.is_compressed():
		image.decompress()
	image.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	image.save_png(png)
	return false


func _source_mesh(entry: Dictionary) -> Mesh:
	var scene := (load("res://assets/characters/%s/source.glb" % entry["folder"]) as PackedScene).instantiate()
	var mesh := (scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	scene.free()
	return mesh


func _build(entry: Dictionary) -> Node3D:
	var arrays := _source_mesh(entry).surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		for i in positions.size():
			indices.append(i)
	# Sort every triangle into a part (with its points posed: arms dropped).
	var parts := {}
	for t in floori(indices.size() / 3.0):
		var middle := Vector3.ZERO
		for k in 3:
			middle += positions[indices[t * 3 + k]] / 3.0
		var part := _which_part(entry, middle)
		var pose := _pose(entry, part)
		for k in 3:
			var corner := indices[t * 3 + k]
			_add(parts, part, pose * positions[corner], (pose.basis * normals[corner]).normalized(), uvs[corner])
	# Stand it on the floor, facing -Z, at its height.
	var bounds := AABB()
	var first := true
	for part: String in parts:
		for p in parts[part][0] as PackedVector3Array:
			bounds = AABB(p, Vector3.ZERO) if first else bounds.expand(p)
			first = false
	var size: float = float(entry["height"]) / bounds.size.y
	var place := Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * size), Vector3(0.0, -bounds.position.y * size, 0.0))

	var figure := Node3D.new()
	figure.name = entry["name"]
	figure.set_script(load(ANIMATOR))
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	material.set_shader_parameter("albedo_texture", load("res://assets/characters/%s/texture.png" % entry["folder"]))
	material.set_shader_parameter("box_uv", false)
	var joints := {}
	for joint: String in ["LegLeft", "LegRight", "Body", "ArmLeft", "ArmRight", "Head"]:
		var node := Node3D.new()
		node.name = joint
		var parent: Node3D = figure if joint.begins_with("Leg") or joint == "Body" else joints["Body"]
		var parent_world := Vector3.ZERO if parent == figure else place * _pivot(entry, "Body")
		node.position = place * _pivot(entry, joint) - parent_world
		parent.add_child(node, true)
		joints[joint] = node
	for part: String in parts:
		var joint_world := place * _pivot(entry, part)
		var instance := MeshInstance3D.new()
		instance.name = part + "Mesh"
		instance.mesh = _part_mesh(parts[part], place, joint_world, material)
		(joints[part] as Node3D).add_child(instance, true)
	return figure


## Which part a triangle belongs to, from where its middle is (model units,
## facing +Z, so +X is the character's left).
func _which_part(entry: Dictionary, middle: Vector3) -> String:
	var side := "Left" if middle.x > 0.0 else "Right"  # Facing +Z, +X is the left.
	var shoulder: Vector2 = entry["shoulder"]
	var band: Vector2 = entry["arm_band"]
	if middle.z < float(entry["tail_z"]) and middle.y < float(entry["neck"]):
		return "Body"  # A tail.
	if absf(middle.x) > shoulder.x and middle.y > band.x and middle.y < band.y:
		return "Arm" + side
	if middle.y > float(entry["neck"]):
		return "Head"
	if middle.y < float(entry["hip"]):
		return "Leg" + side
	return "Body"


## Arms swing down from the T-pose to the sides; everything else stays put.
func _pose(entry: Dictionary, part: String) -> Transform3D:
	if not part.begins_with("Arm"):
		return Transform3D.IDENTITY
	var shoulder := _pivot(entry, part)
	var out := 1.0 if part.ends_with("Left") else -1.0  # Which way (in model x) this arm sticks out.
	var drop := Basis(Vector3.BACK, -deg_to_rad(ARM_DROP_DEGREES) * out)
	return Transform3D(Basis(), shoulder) * Transform3D(drop, Vector3.ZERO) * Transform3D(Basis(), -shoulder)


## The joint each part swings from (model units).
func _pivot(entry: Dictionary, part: String) -> Vector3:
	var shoulder: Vector2 = entry["shoulder"]
	var out := 1.0 if part.ends_with("Left") else -1.0
	if part.begins_with("Arm"):
		return Vector3(shoulder.x * out, shoulder.y, 0.0)
	if part.begins_with("Leg"):
		return Vector3(0.06 * out, float(entry["hip"]), 0.0)
	if part == "Head":
		return Vector3(0.0, float(entry["neck"]), 0.0)
	return Vector3(0.0, float(entry["hip"]), 0.0)


func _add(parts: Dictionary, part: String, position: Vector3, normal: Vector3, uv: Vector2) -> void:
	if not parts.has(part):
		parts[part] = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array()]
	# (Packed arrays are copied when taken out, so append and put them back.)
	var data: Array = parts[part]
	var points: PackedVector3Array = data[0]
	var normals: PackedVector3Array = data[1]
	var uvs: PackedVector2Array = data[2]
	points.append(position)
	normals.append(normal)
	uvs.append(uv)
	parts[part] = [points, normals, uvs]


func _part_mesh(data: Array, place: Transform3D, joint_world: Vector3, material: Material) -> ArrayMesh:
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in (data[0] as PackedVector3Array).size():
		points.append(place * (data[0][i] as Vector3) - joint_world)
		normals.append((place.basis * (data[1][i] as Vector3)).normalized())
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = data[2]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return mesh
