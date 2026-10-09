extends "res://tools/build_placeholder_models.gd"
## Builds the playable Jacki, res://scenes/hub/JackiVisual.tscn, from the
## developer's Rocket Cap Rabbit model, cut into rigid parts that
## BunnyAnimator.gd swings, Mega Man Legends style: each leg (with its foot),
## the body, each arm (with its fist) and the head (with the cap and the lop
## ears). The same hand-made walk, bounce, breathing and poses the earlier
## Jacki had.
##
## Where to cut comes from art/models/jacki_rigged.glb (the model already
## skinned to a skeleton by tools/rig_jacki.py): each triangle goes with the
## bone that moves it most (thigh, shin and foot bones -> that leg; upper
## arm, forearm and fist -> that arm; neck and head -> the head; the rest ->
## the body), and each part swings from its bone's joint.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_jacki.gd


const SOURCE := "res://art/models/jacki_rigged.glb"
const OUTPUT := "res://scenes/hub/JackiVisual.tscn"
const ANIMATOR := "res://scenes/hub/BunnyAnimator.gd"

## How tall she stands in the game, cap included, in meters.
const HEIGHT: float = 1.25
## Which part each bone's triangles go to.
const PART_OF_BONE := {
	"UpperLeg.L": "LegLeft", "LowerLeg.L": "LegLeft", "Foot.L": "LegLeft",
	"UpperLeg.R": "LegRight", "LowerLeg.R": "LegRight", "Foot.R": "LegRight",
	"UpperArm.L": "ArmLeft", "LowerArm.L": "ArmLeft", "Fist.L": "ArmLeft",
	"UpperArm.R": "ArmRight", "LowerArm.R": "ArmRight", "Fist.R": "ArmRight",
	"Neck": "Head", "Head": "Head",
}
## The joint each part swings from (a bone's start).
const JOINT_BONE := {
	"LegLeft": "UpperLeg.L", "LegRight": "UpperLeg.R", "ArmLeft": "UpperArm.L",
	"ArmRight": "UpperArm.R", "Head": "Neck",
}

## Part name -> [corner positions, normals, uvs] (model units).
var _parts := {}
var _skeleton: Skeleton3D


func _initialize() -> void:
	var model := (load(SOURCE) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var source := model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var texture: Texture2D = null
	var original := source.get_active_material(0) as BaseMaterial3D
	if original != null:
		texture = original.albedo_texture
	_cut(source)
	var figure := _assemble(texture)
	root.remove_child(model)
	model.free()
	_save(figure, OUTPUT)
	quit()


# --- 1. Cutting ------------------------------------------------------------------------

func _cut(source: MeshInstance3D) -> void:
	var arrays := source.mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var per_corner := floori(bones.size() / float(positions.size()))
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		for i in positions.size():
			indices.append(i)
	for t in floori(indices.size() / 3.0):
		# Which part pulls on this triangle's corners hardest.
		var pull := {}
		for k in 3:
			var corner := indices[t * 3 + k]
			for b in per_corner:
				var bind_name := String(source.skin.get_bind_name(bones[corner * per_corner + b]))
				var part: String = PART_OF_BONE.get(bind_name, "Torso")
				pull[part] = float(pull.get(part, 0.0)) + weights[corner * per_corner + b]
		var best := "Torso"
		for part: String in pull:
			if float(pull[part]) > float(pull.get(best, 0.0)):
				best = part
		for k in 3:
			var corner := indices[t * 3 + k]
			_add(best, positions[corner], normals[corner] if not normals.is_empty() else Vector3.UP,
					uvs[corner] if not uvs.is_empty() else Vector2.ZERO)


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


## Where a part swings from (model units). The body swings from between
## the hips.
func _pivot(part: String) -> Vector3:
	if part == "Body":
		var left := _skeleton.get_bone_global_rest(_skeleton.find_bone("UpperLeg.L")).origin
		var right := _skeleton.get_bone_global_rest(_skeleton.find_bone("UpperLeg.R")).origin
		return (left + right) * 0.5
	return _skeleton.get_bone_global_rest(_skeleton.find_bone(JOINT_BONE[part])).origin


# --- 2. Assembling ---------------------------------------------------------------------

func _assemble(texture: Texture2D) -> Node3D:
	# Turn to face -Z (the model faces +Z), stand on the floor, size to HEIGHT.
	var bounds := AABB()
	var first := true
	for part: String in _parts:
		for p in _parts[part][0] as PackedVector3Array:
			if first:
				bounds = AABB(p, Vector3.ZERO)
				first = false
			bounds = bounds.expand(p)
	var size := HEIGHT / bounds.size.y
	var place := Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * size), Vector3(0.0, -bounds.position.y * size, 0.0))

	var figure := Node3D.new()
	figure.name = "JackiVisual"
	figure.set_script(load(ANIMATOR))
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	material.set_shader_parameter("albedo_texture", texture)
	material.set_shader_parameter("box_uv", false)

	var nodes := {}
	for joint: Array in [["LegLeft", ""], ["LegRight", ""], ["Body", ""], ["ArmLeft", "Body"], ["ArmRight", "Body"], ["Head", "Body"]]:
		var joint_name: String = joint[0]
		var parent_name: String = joint[1]
		var node := Node3D.new()
		node.name = joint_name
		# Joint positions are stored relative to the parent joint.
		var parent_world := Vector3.ZERO if parent_name.is_empty() else place * _pivot(parent_name)
		node.position = place * _pivot(joint_name) - parent_world
		(figure if parent_name.is_empty() else nodes[parent_name] as Node3D).add_child(node, true)
		nodes[joint_name] = node
	for part: String in _parts:
		var joint_name := "Body" if part == "Torso" else part
		var instance := MeshInstance3D.new()
		instance.name = part + "Mesh"
		instance.mesh = _part_mesh(part, place, place * _pivot(joint_name), material)
		(nodes[joint_name] as Node3D).add_child(instance, true)
	# Her right hand, for things she holds (Snack.gd): the bottom of the fist.
	var fist := _skeleton.get_bone_global_rest(_skeleton.find_bone("Fist.R")).origin
	var hand := Marker3D.new()
	hand.name = "Hand"
	hand.position = place * fist - place * _pivot("ArmRight")
	(nodes["ArmRight"] as Node3D).add_child(hand, true)
	print("Jacki: %d parts, %.2f m tall" % [_parts.size(), HEIGHT])
	return figure


## One part's mesh, with its points relative to the joint that carries it.
func _part_mesh(part: String, to_world: Transform3D, joint_world: Vector3, material: Material) -> ArrayMesh:
	var data: Array = _parts[part]
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in (data[0] as PackedVector3Array).size():
		points.append(to_world * (data[0][i] as Vector3) - joint_world)
		normals.append((to_world.basis * (data[1][i] as Vector3)).normalized())
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = data[2]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return mesh
