extends "res://tools/build_placeholder_models.gd"
## Builds the playable bunny, res://scenes/hub/BunnyVisual.tscn, from the
## developer's 3D model of Jacki (res://art/models/jacki_rabbit.glb, made in
## Meshy, already chibi: big head, short legs, big feet, lop ears down her
## back, T-pose).
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_bunny.gd
##
## WHAT IT DOES:
## 1. CUTS her into rigid parts, Mega Man Legends style, by where each
##    triangle sits (the model is one piece): each leg (and foot), the body,
##    each arm (whatever sticks out sideways at shoulder height), and the
##    head (with the cap and the lop ears down her back: cut separately,
##    the ears tore at the seam, so they move with the head).
## 2. POSES her: the T-pose arms swing down to her sides.
## 3. Turns her to face -Z (the game's "forward"), stands her on the floor,
##    sizes her to HEIGHT, and hangs each part on a pivot (hip, shoulder,
##    neck, ear root) named for BunnyAnimator.gd, which swings them.
##
## Her texture is drawn with crisp pixels and the PS1 surface, so she sits in
## the world like the other models. To change her look, replace the .glb
## (same name) and re-run; if the new model's proportions differ, adjust the
## joint numbers below (they're in the model's own units, where she's 1 tall,
## centered, feet at y = -0.5, facing +Z).


const SOURCE := "res://art/models/jacki_rabbit.glb"
const OUTPUT := "res://scenes/hub/BunnyVisual.tscn"
const ANIMATOR := "res://scenes/hub/BunnyAnimator.gd"

## How tall she stands in the game, cap included, in meters.
const HEIGHT: float = 1.25
## How far the T-pose arms swing down (degrees).
const ARM_DROP_DEGREES: float = 72.0
## Joints, in the model's own units.
const HIP_Y: float = -0.22  # Below this: legs.
const LEG_X: float = 0.075  # Each leg swings from here (left/right of center).
const SHOULDER := Vector3(0.125, 0.06, 0.0)  # Arms start sideways of this.
const ARM_BAND := Vector2(-0.14, 0.17)  # Arms live between these heights.
const NECK_Y: float = 0.11  # Above this: the head (and cap).
const EAR_BACK_Z: float = -0.07  # Behind this and out to the side: the
const EAR_SIDE_X: float = 0.13  # lop ears, hanging by her shoulders (they go with the head).
const EAR_ROOT := Vector3(0.11, 0.22, -0.14)  # Where the ears hang from.

## Part name -> [triangle corner positions, normals, uvs].
var _parts := {}


func _initialize() -> void:
	var model := (load(SOURCE) as PackedScene).instantiate() as Node3D
	var source := model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var texture: Texture2D = null
	var original := source.get_active_material(0) as BaseMaterial3D
	if original != null:
		texture = original.albedo_texture
	_cut(source.mesh, source.transform)
	var figure := _assemble(texture)
	model.free()
	_save(figure, OUTPUT)
	quit()


# --- 1. Cutting --------------------------------------------------------------------

func _cut(source: Mesh, to_model: Transform3D) -> void:
	var arrays := source.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		for i in positions.size():
			indices.append(i)
	for t in floori(indices.size() / 3.0):
		var center := Vector3.ZERO
		for k in 3:
			center += to_model * positions[indices[t * 3 + k]] / 3.0
		var part := _which_part(center)
		for k in 3:
			var corner := indices[t * 3 + k]
			_add(part, to_model * positions[corner], to_model.basis * normals[corner] if not normals.is_empty() else Vector3.UP,
					uvs[corner] if not uvs.is_empty() else Vector2.ZERO)


## Which part a triangle belongs to, from its center. (The model faces +Z,
## so its +X side is her left.)
func _which_part(c: Vector3) -> String:
	var side := "Left" if c.x > 0.0 else "Right"
	if c.z < EAR_BACK_Z and c.y > -0.2 and absf(c.x) > EAR_SIDE_X:
		return "Head"  # The lop ears ride on the head in one piece (cut, they tear).
	if c.y < HIP_Y:
		return "Leg" + side
	if absf(c.x) > SHOULDER.x and c.y > ARM_BAND.x and c.y < ARM_BAND.y:
		return "Arm" + side
	if c.y > NECK_Y:
		return "Head"
	return "Torso"


func _add(part: String, position: Vector3, normal: Vector3, uv: Vector2) -> void:
	if not _parts.has(part):
		_parts[part] = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array()]
	# (Packed arrays are copied when taken out, so append and put them back.)
	var data: Array = _parts[part]
	var points: PackedVector3Array = data[0]
	var part_normals: PackedVector3Array = data[1]
	var part_uvs: PackedVector2Array = data[2]
	points.append(position)
	part_normals.append(normal)
	part_uvs.append(uv)
	_parts[part] = [points, part_normals, part_uvs]


# --- 2. Posing ---------------------------------------------------------------------

## Where a part's points go (model units, still facing +Z): only the arms
## move, swinging down from the shoulder.
func _part_transform(part: String) -> Transform3D:
	if not part.begins_with("Arm"):
		return Transform3D.IDENTITY
	var sign_x := 1.0 if part.ends_with("Left") else -1.0
	var shoulder := Vector3(SHOULDER.x * sign_x, SHOULDER.y, SHOULDER.z)
	var drop := Basis(Vector3.BACK, -deg_to_rad(ARM_DROP_DEGREES) * sign_x)
	return Transform3D(Basis(), shoulder) * Transform3D(drop, Vector3.ZERO) * Transform3D(Basis(), -shoulder)


## The joints each part swings from (model units).
func _pivot(joint: String) -> Vector3:
	var sign_x := 1.0 if joint.ends_with("Left") else -1.0
	match joint:
		"LegLeft", "LegRight":
			return Vector3(LEG_X * sign_x, HIP_Y, 0.0)
		"ArmLeft", "ArmRight":
			return Vector3(SHOULDER.x * sign_x, SHOULDER.y, SHOULDER.z)
		"Head":
			return Vector3(0.0, NECK_Y, 0.0)
		"EarLeft", "EarRight":
			return Vector3(EAR_ROOT.x * sign_x, EAR_ROOT.y, EAR_ROOT.z)
	return Vector3(0.0, HIP_Y, 0.0)


# --- 3. Assembling -------------------------------------------------------------------

func _assemble(texture: Texture2D) -> Node3D:
	# Final placement: turn to face -Z, stand on the floor, size to HEIGHT.
	var bounds := AABB()
	var first := true
	for part: String in _parts:
		var to_pose := _part_transform(part)
		for p in _parts[part][0] as PackedVector3Array:
			var q := to_pose * p
			if first:
				bounds = AABB(q, Vector3.ZERO)
				first = false
			bounds = bounds.expand(q)
	var size := HEIGHT / bounds.size.y
	var turn := Basis(Vector3.UP, PI)
	var place := Transform3D(turn.scaled(Vector3.ONE * size), Vector3(0.0, -bounds.position.y * size, 0.0))

	var figure := Node3D.new()
	figure.name = "BunnyVisual"
	figure.set_script(load(ANIMATOR))
	figure.set("ear_swing", -1.0)  # Her lop ears hang down: trail them backward.
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	material.set_shader_parameter("albedo_texture", texture)
	material.set_shader_parameter("box_uv", false)

	var nodes := {}
	var joints := [["LegLeft", ""], ["LegRight", ""], ["Body", ""], ["ArmLeft", "Body"], ["ArmRight", "Body"],
			["Head", "Body"], ["EarLeft", "Body/Head"], ["EarRight", "Body/Head"]]
	for joint: Array in joints:
		var joint_name: String = joint[0]
		var node := Node3D.new()
		node.name = joint_name
		var parent_path: String = joint[1]
		var parent: Node3D = figure if parent_path.is_empty() else nodes[parent_path]
		# Joint positions are stored relative to the parent joint.
		var world := place * _pivot(joint_name)
		var parent_world := Vector3.ZERO if parent_path.is_empty() else place * _pivot(parent_path.get_file())
		node.position = world - parent_world
		parent.add_child(node, true)
		nodes[joint_name if parent_path.is_empty() else parent_path + "/" + joint_name] = node
		nodes[joint_name] = node
	# Which joint carries each cut part.
	var carriers := {"LegLeft": "LegLeft", "LegRight": "LegRight", "Torso": "Body", "ArmLeft": "ArmLeft",
			"ArmRight": "ArmRight", "Head": "Head", "EarLeft": "EarLeft", "EarRight": "EarRight"}
	for part: String in _parts:
		var joint_name: String = carriers[part]
		var joint_world := place * _pivot(joint_name)
		var mesh := _part_mesh(part, place * _part_transform(part), joint_world, material)
		var instance := MeshInstance3D.new()
		instance.name = part + "Mesh"
		instance.mesh = mesh
		(nodes[joint_name] as Node3D).add_child(instance, true)
	print("Bunny: %d parts, %.2f m tall" % [_parts.size(), HEIGHT])
	return figure


## One part's mesh, with its points relative to the joint that carries it.
func _part_mesh(part: String, to_world: Transform3D, joint_world: Vector3, material: Material) -> ArrayMesh:
	var data: Array = _parts[part]
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var normal_basis := to_world.basis.inverse().transposed()
	for i in (data[0] as PackedVector3Array).size():
		points.append(to_world * (data[0][i] as Vector3) - joint_world)
		normals.append((normal_basis * (data[1][i] as Vector3)).normalized())
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = data[2]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return mesh
