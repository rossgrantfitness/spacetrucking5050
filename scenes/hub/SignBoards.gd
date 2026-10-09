class_name SignBoards
extends RefCounted
## Every sign sits on something. Glowing lettering (Label3D) on its own
## looks like it's floating in the air, so when a room loads, this puts each
## sign that isn't already on a board onto one: a dark panel with a neon rim
## in the lettering's color. Lines of lettering that belong together (a name
## and the line under it, like "LILY'S PUMPS" over "FUEL · BOOST · SNACKS")
## share one board. A board with no wall right behind it hangs from the
## ceiling on two cables.
##
## Lettering that should float (a "Zzz", a "!") is left alone: anything that
## always faces the camera, and anything with the metadata `no_board` set
## to true (select the Label3D in the editor, then Inspector → Add Metadata).
## A sign that already has its own backing (a mesh named "...SignBack" or
## "...Backing" right behind it) is left alone too.


## Dark board face.
const FACE_COLOR := Color(0.07, 0.075, 0.13)
## Cables and brackets.
const METAL_COLOR := Color(0.28, 0.3, 0.36)
## How thick a board is, for its height (with a minimum, in meters).
const DEPTH_SHARE: float = 0.06
const MIN_DEPTH: float = 0.08
## How far behind a board we look for a wall, in meters.
const WALL_REACH: float = 1.2
## Longest cable up to the ceiling, in meters.
const MAX_CABLE: float = 8.0


## Puts every floating sign under `holders` onto a board. Wait one frame
## after the room is in the tree first (lettering is measured then).
static func mount_all(holders: Array[Node3D]) -> int:
	var labels: Array[Label3D] = []
	var meshes: Array[MeshInstance3D] = []
	for holder in holders:
		if holder == null or not holder.is_inside_tree():
			continue
		for node in holder.find_children("*", "Label3D", true, false):
			var label := node as Label3D
			if label.visible and label.billboard == BaseMaterial3D.BILLBOARD_DISABLED and not label.get_meta("no_board", false) \
					and not label.text.strip_edges().is_empty() and label.get_aabb().size.x > 0.0:
				labels.append(label)
		for node in holder.find_children("*", "MeshInstance3D", true, false):
			meshes.append(node as MeshInstance3D)
	var boards := 0
	for group in _group(labels):
		if _already_backed(group, meshes):
			continue
		_build_board(group, meshes, true)
		boards += 1
	return boards


## Out in space (landmarks like the world's biggest donut): every sign gets
## a board, held up by a strut back to the landmark it belongs to. Wait one
## frame after building the landmark first.
static func mount_in_space(holder: Node3D) -> int:
	var labels: Array[Label3D] = []
	if not holder.is_inside_tree():
		return 0
	for node in holder.find_children("*", "Label3D", true, false):
		var label := node as Label3D
		if label.visible and label.billboard == BaseMaterial3D.BILLBOARD_DISABLED and not label.get_meta("no_board", false) \
				and not label.text.strip_edges().is_empty() and label.get_aabb().size.x > 0.0:
			labels.append(label)
	var boards := 0
	for group in _group(labels):
		var board := _build_board(group, [], false)
		var target := board.to_local(holder.global_position)
		if target.length() > 1.0:
			var face := board.get_node("SignBoardFace") as MeshInstance3D
			var thick := clampf((face.mesh as BoxMesh).size.y * 0.12, 1.0, 14.0)
			var strut := _box(board, "Strut", Vector3(thick, thick, target.length()), target * 0.5, METAL_COLOR, false)
			strut.basis = Basis.looking_at(target.normalized(), Vector3.UP if absf(target.normalized().y) < 0.99 else Vector3.FORWARD)
		boards += 1
	return boards


## Sorts labels into signs: lettering facing the same way, close together,
## one above the other (or side by side) is one sign.
static func _group(labels: Array[Label3D]) -> Array:
	var groups: Array = []
	var taken := {}
	# Biggest lettering first, so it leads its group.
	var sorted := labels.duplicate()
	sorted.sort_custom(func(a: Label3D, b: Label3D) -> bool: return _height(a) > _height(b))
	for lead: Label3D in sorted:
		if taken.has(lead):
			continue
		var group: Array[Label3D] = [lead]
		taken[lead] = true
		var grew := true
		while grew:
			grew = false
			for other: Label3D in sorted:
				if taken.has(other):
					continue
				for member in group:
					if _belong_together(member, other):
						group.append(other)
						taken[other] = true
						grew = true
						break
		groups.append(group)
	return groups


static func _height(label: Label3D) -> float:
	return label.get_aabb().size.y * label.global_basis.get_scale().y


static func _belong_together(a: Label3D, b: Label3D) -> bool:
	var basis_a := a.global_basis.orthonormalized()
	if basis_a.z.dot(b.global_basis.orthonormalized().z) < 0.98:
		return false
	var offset := basis_a.inverse() * (b.global_position - a.global_position)
	if absf(offset.z) > 0.2:
		return false
	var rect_a := _rect_in(a, a)
	var rect_b := _rect_in(b, a)
	var gap := maxf(_height(a), _height(b)) * 0.6
	return rect_a.grow_individual(0.2, gap, 0.2, gap).intersects(rect_b)


## `label`'s lettering as a rectangle in `frame`'s flat x/y space.
static func _rect_in(label: Label3D, frame: Label3D) -> Rect2:
	var box := label.get_aabb()
	var to_frame := frame.global_transform.affine_inverse() * label.global_transform
	var rect := Rect2()
	for i in 4:
		var corner := box.position + Vector3(box.size.x if i % 2 == 1 else 0.0, box.size.y if i >= 2 else 0.0, 0.0)
		var flat := to_frame * corner
		if i == 0:
			rect = Rect2(Vector2(flat.x, flat.y), Vector2.ZERO)
		else:
			rect = rect.expand(Vector2(flat.x, flat.y))
	return rect


## The group's lettering, plus a margin, in the lead label's x/y space.
static func _board_rect(group: Array) -> Rect2:
	var lead: Label3D = group[0]
	var rect := _rect_in(lead, lead)
	for label: Label3D in group:
		rect = rect.merge(_rect_in(label, lead))
	var margin := maxf(_height(lead) * 0.3, 0.06)
	return rect.grow(margin)


static func _world_aabb(mesh: MeshInstance3D) -> AABB:
	return mesh.global_transform * mesh.get_aabb()


## Whether a backing panel already sits right behind the sign.
static func _already_backed(group: Array, meshes: Array[MeshInstance3D]) -> bool:
	var lead: Label3D = group[0]
	var rect := _board_rect(group)
	var middle := lead.global_transform * Vector3(rect.get_center().x, rect.get_center().y, 0.0)
	var back := -lead.global_basis.orthonormalized().z
	for mesh in meshes:
		var mesh_name := String(mesh.name)
		if not ("SignBack" in mesh_name or "Backing" in mesh_name):
			continue
		if _world_aabb(mesh).grow(0.02).intersects_segment(middle, middle + back * 0.5):
			return true
	return false


## Whether something solid (a wall, a machine) is right behind `point`.
static func _wall_behind(point: Vector3, back: Vector3, meshes: Array[MeshInstance3D]) -> bool:
	for mesh in meshes:
		if mesh.name.begins_with("SignBoard"):
			continue
		var box := _world_aabb(mesh)
		if box.size.x < 0.3 and box.size.z < 0.3:
			continue  # Too small to hang a sign on (a lamp, a pipe).
		if box.intersects_segment(point, point + back * WALL_REACH):
			return true
	return false


## How far up the ceiling (or a beam) is above `point`, or MAX_CABLE.
static func _ceiling_above(point: Vector3, meshes: Array[MeshInstance3D]) -> float:
	var nearest := MAX_CABLE
	for mesh in meshes:
		var box := _world_aabb(mesh)
		if box.position.y <= point.y + 0.05:
			continue
		if point.x < box.position.x or point.x > box.end.x or point.z < box.position.z or point.z > box.end.z:
			continue
		nearest = minf(nearest, box.position.y - point.y)
	return nearest


## Builds the board behind `group`'s lettering (with cables up to the
## ceiling when `may_hang` and there's no wall behind it). Returns it.
static func _build_board(group: Array, meshes: Array[MeshInstance3D], may_hang: bool) -> Node3D:
	var lead: Label3D = group[0]
	var rect := _board_rect(group)
	var holder := lead.get_parent() as Node3D
	var board := Node3D.new()
	board.name = "SignBoard"
	holder.add_child(board, true)
	# Just behind the lettering, facing the same way.
	var frame := lead.global_transform.orthonormalized()
	# (Room signs are a meter or so tall; signs in space, a hundred meters.)
	var depth := maxf(rect.size.y * DEPTH_SHARE, MIN_DEPTH)
	board.global_transform = frame.translated_local(Vector3(rect.get_center().x, rect.get_center().y, -depth * 0.5 - depth * 0.25))
	var rim := maxf(rect.size.y * 0.06, 0.03)
	var glow := lead.modulate
	_box(board, "Rim", Vector3(rect.size.x + rim * 2.0, rect.size.y + rim * 2.0, depth * 0.6), Vector3(0.0, 0.0, -depth * 0.3), Color(glow.r, glow.g, glow.b) * 0.8, true)
	_box(board, "Face", Vector3(rect.size.x, rect.size.y, depth), Vector3.ZERO, FACE_COLOR, false)
	# Nothing behind it? It hangs from the ceiling on two cables.
	var back := -frame.basis.z
	if not may_hang or _wall_behind(board.global_position, back, meshes):
		return board
	var top := rect.size.y * 0.5 + rim
	for side: float in [-1.0, 1.0]:
		var anchor := Vector3(side * rect.size.x * 0.38, top, 0.0)
		var length := _ceiling_above(board.global_transform * anchor, meshes)
		_box(board, "Cable", Vector3(0.03, length, 0.03), anchor + Vector3(0.0, length * 0.5, 0.0), METAL_COLOR, false)
		_box(board, "Bracket", Vector3(0.12, 0.06, depth * 1.4), anchor, METAL_COLOR, false)
	return board


static func _box(parent: Node3D, part_name: String, size: Vector3, where: Vector3, color: Color, glowing: bool) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if glowing:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	var part := MeshInstance3D.new()
	part.name = "SignBoard" + part_name
	part.mesh = mesh
	part.position = where
	parent.add_child(part, true)
	return part
