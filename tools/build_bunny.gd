extends "res://tools/build_placeholder_models.gd"
## Builds the playable bunny, res://scenes/hub/BunnyVisual.tscn, from the
## developer's 3D model (res://assets/characters/bunny/bunny_source.obj,
## made in Meshy from her character sheet, with its painted texture).
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_bunny.gd
##
## WHAT IT DOES:
## 1. CUTS her into rigid parts, Mega Man Legends style: each leg (pants and
##    boot), the body (torso, vest, tail), each arm (sleeve and hand), the
##    head (head, cap, eyes) and each ear. The model is made of separate
##    pieces ("shells"), so each piece is sorted by where it sits.
## 2. POSES her: the T-pose arms swing down to her sides.
## 3. CHIBI-FIES her: a bigger head, a slightly shorter body, much shorter
##    legs and bigger boots (the numbers are in CHIBI below; tweak and re-run).
## 4. Turns her to face -Z (the game's "forward"), stands her on the floor,
##    sizes her to HEIGHT, and hangs each part on a pivot (hip, shoulder,
##    neck, ear root) named for BunnyAnimator.gd, which swings them.
##
## The texture is shrunk to 512 x 512 pixels and drawn with crisp pixels
## and the PS1 surface, so she sits in the world like the other models.
## To change her look, replace the .obj and texture (same names) and re-run.


const SOURCE_MESH := "res://assets/characters/bunny/bunny_source.obj"
const TEXTURE := preload("res://assets/characters/bunny/bunny_texture.png")
const OUTPUT := "res://scenes/hub/BunnyVisual.tscn"
const ANIMATOR := "res://scenes/hub/BunnyAnimator.gd"

## How tall she stands in the game, cap included, in meters.
const HEIGHT: float = 1.25
## The chibi recipe (in the model's own units, where she's 0.1 tall):
const CHIBI := {
	"head_scale": 1.45,  # The head, cap and ears get this much bigger.
	"torso_scale": Vector3(1.1, 0.88, 1.1),  # Wider, a little shorter.
	"leg_scale": Vector3(1.08, 0.58, 1.08),  # Much shorter legs.
	"boot_scale": 1.18,  # Big work boots.
	"arm_scale": 0.92,  # Slightly shorter arms.
	"arm_drop_degrees": 76.0,  # How far the T-pose arms swing down.
}
# Joints in the model's own units (it faces +Z there, feet at y = 0).
const HIP := Vector3(0.0, 0.05, 0.0)
const NECK := Vector3(0.0, 0.072, 0.0)
const SHOULDER_X: float = 0.012
const SHOULDER_Y: float = 0.066
const BOOT_TOP_Y: float = 0.017
const EAR_ROOT := Vector3(0.012, 0.085, -0.004)

## Part name -> [triangle corner positions, normals, uvs].
var _parts := {}


func _initialize() -> void:
	var source: Mesh = load(SOURCE_MESH)
	_cut(source)
	var figure := _assemble()
	_save(figure, OUTPUT)
	quit()


# --- 1. Cutting --------------------------------------------------------------------

func _cut(source: Mesh) -> void:
	var arrays := source.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		for i in positions.size():
			indices.append(i)
	# Group triangles into shells: triangles sharing a corner position.
	var parent := {}
	for corner in indices:
		var key := _key(positions[corner])
		if not parent.has(key):
			parent[key] = key
	for t in indices.size() / 3:
		var a := _key(positions[indices[t * 3]])
		for k in range(1, 3):
			_union(parent, a, _key(positions[indices[t * 3 + k]]))
	var shells := {}
	for t in indices.size() / 3:
		var root: String = _find(parent, _key(positions[indices[t * 3]]))
		if not shells.has(root):
			shells[root] = []
		(shells[root] as Array).append(t)
	for root: String in shells:
		var triangles: Array = shells[root]
		var box := AABB(positions[indices[triangles[0] * 3]], Vector3.ZERO)
		var center := Vector3.ZERO
		for t: int in triangles:
			for k in 3:
				var p := positions[indices[t * 3 + k]]
				box = box.expand(p)
				center += p
		center /= triangles.size() * 3.0
		for t: int in triangles:
			var triangle_center := Vector3.ZERO
			for k in 3:
				triangle_center += positions[indices[t * 3 + k]] / 3.0
			var part := _which_part(box, center, triangle_center)
			for k in 3:
				var corner := indices[t * 3 + k]
				_add(part, positions[corner], normals[corner] if not normals.is_empty() else Vector3.UP,
						uvs[corner] if not uvs.is_empty() else Vector2.ZERO)


## Which part a triangle belongs to, from its shell's box and center and its
## own center. (The model faces +Z here, so its +X side is her left.)
func _which_part(box: AABB, center: Vector3, triangle: Vector3) -> String:
	var side := "Left" if triangle.x > 0.0 else "Right"
	if box.end.y < 0.02:
		return "Boot" + side
	if box.position.y < 0.02:
		return "Leg" + side  # The pants: one shell, split down the middle.
	if absf(center.x) > 0.03:
		return "Hand" + side
	if box.size.x < 0.03 and absf(center.x) > 0.012 and center.y > 0.058:
		return "Sleeve" + side
	if center.z < -0.008 and center.y < 0.058:
		return "Tail"
	if box.end.y >= 0.099 and box.size.x > 0.04:
		# The cap and both ears are one shell: the ears hang low at the sides.
		if triangle.y < 0.083 and absf(triangle.x) > 0.009:
			return "Ear" + side
		return "Head"
	if center.y > 0.072:
		return "Head"
	return "Torso"


func _add(part: String, position: Vector3, normal: Vector3, uv: Vector2) -> void:
	if not _parts.has(part):
		_parts[part] = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array()]
	# (Packed arrays are copied when taken out, so append and put them back.)
	var data: Array = _parts[part]
	var points: PackedVector3Array = data[0]
	var normals: PackedVector3Array = data[1]
	var uvs: PackedVector2Array = data[2]
	points.append(position)
	normals.append(normal)
	uvs.append(uv)
	_parts[part] = [points, normals, uvs]


func _key(p: Vector3) -> String:
	return "%d,%d,%d" % [roundi(p.x * 1e6), roundi(p.y * 1e6), roundi(p.z * 1e6)]


func _find(parent: Dictionary, key: String) -> String:
	while parent[key] != key:
		parent[key] = parent[parent[key]]
		key = parent[key]
	return key


func _union(parent: Dictionary, a: String, b: String) -> void:
	var root_a := _find(parent, a)
	var root_b := _find(parent, b)
	if root_a != root_b:
		parent[root_a] = root_b


# --- 2 & 3. Posing and chibi-fying -------------------------------------------------

## Where a part's points go (in model units, still facing +Z), as a
## transform: the chibi scaling and the arm pose.
func _part_transform(part: String) -> Transform3D:
	var torso_scale: Vector3 = CHIBI.torso_scale
	var leg_scale: Vector3 = CHIBI.leg_scale
	var new_neck := HIP + (NECK - HIP) * torso_scale
	var sign_x := 1.0 if part.ends_with("Left") else -1.0
	if part == "Head" or part.begins_with("Ear"):
		return _scale_about(NECK, Vector3.ONE * float(CHIBI.head_scale), new_neck)
	if part == "Torso" or part == "Tail":
		return _scale_about(HIP, torso_scale, HIP)
	if part.begins_with("Leg"):
		return _scale_about(HIP, leg_scale, HIP)
	if part.begins_with("Boot"):
		var boot_top := Vector3(0.0135 * sign_x, BOOT_TOP_Y, 0.0)
		return _scale_about(boot_top, Vector3.ONE * float(CHIBI.boot_scale), HIP + (boot_top - HIP) * leg_scale)
	# Arms (sleeve and hand): drop to the side, a little shorter.
	var shoulder := Vector3(SHOULDER_X * sign_x, SHOULDER_Y, 0.0)
	var new_shoulder := HIP + (shoulder - HIP) * torso_scale
	var drop := Basis(Vector3.BACK, -deg_to_rad(CHIBI.arm_drop_degrees) * sign_x)
	var arm := Transform3D(drop.scaled(Vector3.ONE * float(CHIBI.arm_scale)), Vector3.ZERO)
	return Transform3D(Basis(), new_shoulder) * arm * Transform3D(Basis(), -shoulder)


## Scales points by `amount` around `center`, then moves that center to `to`.
func _scale_about(center: Vector3, amount: Vector3, to: Vector3) -> Transform3D:
	return Transform3D(Basis.from_scale(amount), to - center * amount)


## The joints each part swings from (model units, after chibi-fying).
func _pivot(part: String) -> Vector3:
	var torso_scale: Vector3 = CHIBI.torso_scale
	var sign_x := 1.0 if part.ends_with("Left") else -1.0
	match part:
		"LegLeft", "LegRight":
			return Vector3(0.009 * sign_x, HIP.y, 0.0)
		"ArmLeft", "ArmRight":
			return HIP + (Vector3(SHOULDER_X * sign_x, SHOULDER_Y, 0.0) - HIP) * torso_scale
		"Head":
			return HIP + (NECK - HIP) * torso_scale
		"EarLeft", "EarRight":
			return _part_transform("Head") * Vector3(EAR_ROOT.x * sign_x, EAR_ROOT.y, EAR_ROOT.z)
	return HIP


# --- 4. Assembling -------------------------------------------------------------------

func _assemble() -> Node3D:
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
	print("Bunny: %.2f heads tall" % (bounds.size.y / _head_height()))

	var figure := Node3D.new()
	figure.name = "BunnyVisual"
	figure.set_script(load(ANIMATOR))
	figure.set("ear_swing", -1.0)  # Her lop ears hang down: trail them backward.
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	material.set_shader_parameter("albedo_texture", TEXTURE)
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
	var carriers := {"LegLeft": "LegLeft", "BootLeft": "LegLeft", "LegRight": "LegRight", "BootRight": "LegRight",
			"Torso": "Body", "Tail": "Body", "SleeveLeft": "ArmLeft", "HandLeft": "ArmLeft",
			"SleeveRight": "ArmRight", "HandRight": "ArmRight", "Head": "Head", "EarLeft": "EarLeft", "EarRight": "EarRight"}
	for part: String in _parts:
		var joint_name: String = carriers[part]
		var joint_world := place * _pivot(joint_name)
		var to_pose := _part_transform(part)
		var mesh := _part_mesh(part, place * to_pose, joint_world, material)
		var instance := MeshInstance3D.new()
		instance.name = part + "Mesh"
		instance.mesh = mesh
		(nodes[joint_name] as Node3D).add_child(instance, true)
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


## How tall her head is (cap included), after chibi-fying, in model units.
func _head_height() -> float:
	var to_pose := _part_transform("Head")
	var low := INF
	var high := -INF
	for p in _parts["Head"][0] as PackedVector3Array:
		var q := to_pose * p
		low = minf(low, q.y)
		high = maxf(high, q.y)
	return high - low
