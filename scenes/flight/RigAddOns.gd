class_name RigAddOns
extends RefCounted
## Upgrades you can SEE: bolt-on parts on the outside of your rig, like the
## chrome on a real big rig. Each upgrade with an `add_on` (see
## res://data/upgrades/) gets its part fitted here, sized to whatever rig
## you're driving (they're placed by the model's own size, so they fit all
## of them):
##   bumpers     chrome bars across the front and the back (Bumper Bars)
##   radar_dish  a spinning dish on a mast on the roof (Long-Range Radar)
##   horns       two chrome horn trumpets on the roof (Air Horn)
##   light_bar   a row of amber roof lights (Roof Light Bar)
##   racks       an open rack of crates on top of the cargo (Stacking Racks)
##   solar_fins  gold sails along the sides (Solar Sail Trim)
##   stacks      twin chrome exhaust stacks (Hot-Rod Injectors)
## Called by Ship.apply_look after the paint goes on (so the chrome stays chrome).


const SURFACE_SHADER := preload("res://shaders/psx_surface.gdshader")
const CHROME := Color(0.82, 0.85, 0.9)
const DARK := Color(0.16, 0.17, 0.2)
const AMBER := Color(1.0, 0.62, 0.15)
const GOLD := Color(1.0, 0.8, 0.3)


## Fits the parts for `add_ons` (names from the list above) to the model
## under `pivot`, replacing any fitted before.
static func fit(pivot: Node3D, add_ons: PackedStringArray) -> void:
	var old := pivot.get_node_or_null("AddOns")
	if old != null:
		pivot.remove_child(old)
		old.queue_free()
	if add_ons.is_empty():
		return
	var points := hull_points(pivot)
	if points.size() < 3:
		return
	var box := _slice(points, -INF, INF)
	var length := box.size.z
	# The hull in three slices, front to back: the nose, the cab (the front
	# third, where the roof gear goes), the middle (the cargo), the tail.
	var parts := {
		"whole": box,
		"nose": _slice(points, box.position.z, box.position.z + length * 0.1),
		"cab": _slice(points, box.position.z, box.position.z + length * 0.3),
		"middle": _slice(points, box.position.z + length * 0.35, box.position.z + length * 0.75),
		"tail": _slice(points, box.end.z - length * 0.1, box.end.z)}
	var holder := Node3D.new()
	holder.name = "AddOns"
	pivot.add_child(holder)
	for add_on in add_ons:
		match add_on:
			"bumpers":
				_bumpers(holder, parts)
			"radar_dish":
				_radar_dish(holder, parts)
			"horns":
				_horns(holder, parts)
			"light_bar":
				_light_bar(holder, parts)
			"racks":
				_racks(holder, parts)
			"solar_fins":
				_solar_fins(holder, parts)
			"stacks":
				_stacks(holder, parts)


## Every corner of the hull's triangles, in `pivot`'s space (the ship faces
## -Z, so the front has the smallest z).
static func hull_points(pivot: Node3D) -> PackedVector3Array:
	var points := PackedVector3Array()
	for node in pivot.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if part.mesh == null or part.top_level or _skip(part, pivot):
			continue
		var to_pivot := pivot.global_transform.affine_inverse() * part.global_transform if part.is_inside_tree() else _local_to(pivot, part)
		for corner in part.mesh.get_faces():
			points.append(to_pivot * corner)
	return points


## The model's size and place in `pivot`'s space.
static func hull_box(pivot: Node3D) -> AABB:
	return _slice(hull_points(pivot), -INF, INF)


## The box around the hull's points between `z_from` and `z_to`. Sideways
## and up-down, it ignores the outermost few percent of points, so a crane
## arm, an antenna or a wide engine pod doesn't throw the fit off.
static func _slice(points: PackedVector3Array, z_from: float, z_to: float) -> AABB:
	var xs := PackedFloat32Array()
	var ys := PackedFloat32Array()
	var z_low := INF
	var z_high := -INF
	for p in points:
		if p.z < z_from or p.z > z_to:
			continue
		xs.append(p.x)
		ys.append(p.y)
		z_low = minf(z_low, p.z)
		z_high = maxf(z_high, p.z)
	if xs.is_empty():
		return AABB()
	xs.sort()
	ys.sort()
	var low := Vector3(_at(xs, 0.04), _at(ys, 0.04), z_low)
	var high := Vector3(_at(xs, 0.96), _at(ys, 0.8), z_high)
	return AABB(low, high - low)


## The value `share` of the way through sorted `values` (0.5 = the middle one).
static func _at(values: PackedFloat32Array, share: float) -> float:
	return values[clampi(roundi(share * (values.size() - 1)), 0, values.size() - 1)]


## Whether `part` isn't part of the hull: an add-on, an engine flame, flare
## or trail, or an old model on its way out.
static func _skip(part: Node, pivot: Node3D) -> bool:
	var walk: Node = part
	while walk != null and walk != pivot:
		if walk.is_queued_for_deletion() or walk.name == "AddOns":
			return true
		var script := walk.get_script() as Script
		if script != null and script.get_global_name() in [&"EngineExhaust", &"EngineTrail", &"EngineFlare"]:
			return true
		walk = walk.get_parent()
	return false


## A node's transform relative to `ancestor`, without needing the scene tree.
static func _local_to(ancestor: Node3D, node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var walk: Node = node
	while walk != null and walk != ancestor:
		if walk is Node3D:
			result = (walk as Node3D).transform * result
		walk = walk.get_parent()
	return result


static func _bumpers(holder: Node3D, parts: Dictionary) -> void:
	var nose: AABB = parts["nose"]
	var tail: AABB = parts["tail"]
	var whole: AABB = parts["whole"]
	var unit := whole.size.z * 0.01  # (About 30 cm on a 30 m rig.)
	var bar := Vector3(nose.size.x * 0.95, unit * 2.0, unit * 1.8)
	var low := nose.position.y + nose.size.y * 0.3
	var front := nose.position.z + unit * 1.2
	_box(holder, bar, Vector3(nose.get_center().x, low, front), CHROME)
	_box(holder, bar * Vector3(0.85, 0.6, 1.0), Vector3(nose.get_center().x, low + unit * 3.5, front + unit * 0.4), CHROME)
	for side: float in [-0.3, 0.3]:
		_box(holder, Vector3(unit * 1.2, unit * 5.0, unit * 3.0), Vector3(nose.get_center().x + side * nose.size.x, low + unit * 1.5, front + unit * 1.0), DARK)
	# A lower bar at the back, under the engines.
	_box(holder, Vector3(tail.size.x * 0.7, unit * 1.8, unit * 1.8), Vector3(tail.get_center().x, tail.position.y + unit * 1.0, tail.end.z + unit * 0.6), CHROME)


static func _radar_dish(holder: Node3D, parts: Dictionary) -> void:
	var cab: AABB = parts["cab"]
	var size := cab.size.x * 0.3
	var where := Vector3(cab.get_center().x, cab.end.y, cab.position.z + cab.size.z * 0.75)
	_cylinder(holder, size * 0.06, size * 0.8, where + Vector3(0.0, size * 0.4, 0.0), DARK)
	var spinner := Node3D.new()
	spinner.name = "DishSpinner"
	spinner.set_script(load("res://scenes/common/Spinner.gd"))
	spinner.position = where + Vector3(0.0, size * 0.85, 0.0)
	holder.add_child(spinner)
	var dish := SphereMesh.new()
	dish.radius = size * 0.55
	dish.height = size * 0.4
	dish.is_hemisphere = true
	dish.radial_segments = 10
	dish.rings = 3
	dish.material = _paint(CHROME)
	var part := MeshInstance3D.new()
	part.mesh = dish
	part.rotation = Vector3(deg_to_rad(-120.0), 0.0, 0.0)  # Tipped up and back, like a satellite dish.
	spinner.add_child(part)
	_box(spinner, Vector3.ONE * size * 0.1, Vector3(0.0, size * 0.15, -size * 0.3), AMBER, true)


static func _horns(holder: Node3D, parts: Dictionary) -> void:
	var cab: AABB = parts["cab"]
	var length := cab.size.z * 0.3
	var radius := length * 0.14
	for side: float in [-1.0, 1.0]:
		var where := Vector3(cab.get_center().x + side * cab.size.x * 0.3, cab.end.y + radius * 1.4, cab.position.z + cab.size.z * 0.45)
		var trumpet := CylinderMesh.new()
		trumpet.top_radius = radius  # The bell, pointing forward (see the turn below).
		trumpet.bottom_radius = radius * 0.3
		trumpet.height = length * (1.0 if side < 0.0 else 0.8)
		trumpet.radial_segments = 8
		trumpet.rings = 1
		trumpet.material = _paint(CHROME)
		var part := MeshInstance3D.new()
		part.mesh = trumpet
		part.position = where
		part.rotation = Vector3(-PI / 2.0, 0.0, 0.0)  # Lying along the rig: its top (the bell) to the front.
		holder.add_child(part)
		_box(holder, Vector3(radius * 0.6, radius * 1.4, radius * 0.6), where - Vector3(0.0, radius * 1.1, 0.0), DARK)


static func _light_bar(holder: Node3D, parts: Dictionary) -> void:
	var cab: AABB = parts["cab"]
	var unit := cab.size.z * 0.03
	var width := cab.size.x * 0.75
	var y := cab.end.y + unit * 0.6
	var z := cab.position.z + cab.size.z * 0.3
	_box(holder, Vector3(width, unit * 0.6, unit * 1.0), Vector3(cab.get_center().x, y, z), DARK)
	for i in 6:
		var x := cab.get_center().x - width * 0.42 + width * 0.84 * i / 5.0
		_box(holder, Vector3(width * 0.1, unit * 0.9, unit * 0.9), Vector3(x, y + unit * 0.6, z - unit * 0.1), AMBER, true)


## Stacking racks: an open frame on top of the cargo with crates strapped
## in, so the load stacks higher.
static func _racks(holder: Node3D, parts: Dictionary) -> void:
	var middle: AABB = parts["middle"]
	var length := middle.size.z * 0.8
	var width := middle.size.x * 0.7
	var height := middle.size.y * 0.22
	var y := middle.end.y + height * 0.5
	var z := middle.get_center().z
	var colors: Array[Color] = [Color(0.85, 0.45, 0.2), Color(0.3, 0.55, 0.75), Color(0.75, 0.7, 0.3), Color(0.5, 0.7, 0.45)]
	var bar := minf(width, length) * 0.04
	for k in 4:
		# Four crates, two by two.
		var crate := Vector3(width * 0.44, height * 0.85, length * 0.44)
		_box(holder, crate, Vector3(middle.get_center().x + (-0.25 if k % 2 == 0 else 0.25) * width, y - height * 0.07,
				z + (-0.25 if k < 2 else 0.25) * length), colors[k])
	for x_side: float in [-0.5, 0.5]:
		_box(holder, Vector3(bar, bar, length), Vector3(middle.get_center().x + x_side * width, y + height * 0.5, z), DARK)
		for z_side: float in [-0.5, 0.0, 0.5]:
			_box(holder, Vector3(bar, height, bar), Vector3(middle.get_center().x + x_side * width, y, z + z_side * length), DARK)


static func _solar_fins(holder: Node3D, parts: Dictionary) -> void:
	var middle: AABB = parts["middle"]
	var length := middle.size.z * 0.6
	var reach := middle.size.x * 0.4
	for side: float in [-1.0, 1.0]:
		var x := (middle.end.x if side > 0.0 else middle.position.x) + side * reach * 0.48
		var fin := _box(holder, Vector3(reach, middle.size.y * 0.02, length), Vector3(x, middle.get_center().y + middle.size.y * 0.1, middle.get_center().z), GOLD, true)
		fin.rotation.z = side * deg_to_rad(12.0)  # Swept up a little, like wings.
		for k in 4:
			_box(fin, Vector3(reach * 1.01, middle.size.y * 0.025, length * 0.02), Vector3(0.0, 0.0, -length * 0.38 + length * 0.25 * k), DARK)


static func _stacks(holder: Node3D, parts: Dictionary) -> void:
	var cab: AABB = parts["cab"]
	var height := cab.size.y * 0.55
	var radius := cab.size.x * 0.045
	for side: float in [-1.0, 1.0]:
		var where := Vector3(cab.get_center().x + side * cab.size.x * 0.42, cab.end.y + height * 0.35, cab.end.z - cab.size.z * 0.1)
		_cylinder(holder, radius, height, where, CHROME)
		_cylinder(holder, radius * 1.2, height * 0.06, where + Vector3(0.0, height * 0.5, 0.0), DARK)


static func _paint(color: Color, glowing: bool = false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("box_uv", false)
	if glowing:
		material.set_shader_parameter("emission", color)
		material.set_shader_parameter("emission_strength", 1.6)
	return material


static func _box(parent: Node3D, size: Vector3, where: Vector3, color: Color, glowing: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _paint(color, glowing)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = where
	parent.add_child(part)
	return part


static func _cylinder(parent: Node3D, radius: float, height: float, where: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	mesh.material = _paint(color)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = where
	parent.add_child(part)
	return part
