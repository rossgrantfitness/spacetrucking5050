extends SceneTree
## Builds Jacki's room (the rig's sleeper cabin) from the developer's
## "Orbital Hideaway" diorama (res://art/models/jacki_room.glb), as the
## apartment's Set: res://scenes/hub/sets/JackiRoomSet.tscn.
##
## The room is drawn LIVE (not pre-painted like the other rooms): one fixed
## isometric camera looks into it like a doll's house with two walls off
## (see Apartment.tscn, whose HubRoom has `live_set` on). This tool:
##   - scales the model up (SCALE) and stands its floor at y = 0, centered;
##   - makes collision she can't walk through: the walls, bed, desk, crates
##     (the model's own triangles, but only from knee height up, so the
##     clutter on the floor doesn't snag her), a flat floor, and the edges
##     of the floor where the open sides drop away (gaps at the two steps,
##     where the doors are);
##   - adds a "SpaceView" panel in the window (the live view of space goes
##     there in flight) and lights: the hanging lantern, the pink desk lamp,
##     starlight through the window.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_jacki_room.gd

const SOURCE := "res://art/models/jacki_room.glb"
const OUTPUT := "res://scenes/hub/sets/JackiRoomSet.tscn"
## Meters per model unit (the model is about 1 unit across): the bed comes
## out about 2.2 m long.
const SCALE := 6.4
## Collision only from this high above the floor (meters): lower bits of
## the model (rugs, cables, crumbs) are walked over.
const KNEE := 0.35
## The floor she walks on, in meters (half its size each way), and where
## the steps out are: the left side's (-X) and the front's (+Z) middles.
const FLOOR_HALF := Vector2(2.25, 2.25)
const STEP_HALF_WIDTH := 0.55
## The window in the right wall (+X): its middle and size, in meters.
const WINDOW_CENTER := Vector3(2.2, 1.85, -0.75)
const WINDOW_SIZE := Vector2(2.3, 1.25)


func _initialize() -> void:
	var set_root := Node3D.new()
	set_root.name = "JackiRoomSet"
	var model := (load(SOURCE) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	var faces := _faces(model)
	var box := AABB(faces[0], Vector3.ZERO)
	for p in faces:
		box = box.expand(p)
	var floor_y := _floor_height(faces, box)
	model.scale = Vector3.ONE * SCALE
	model.position = Vector3(-box.get_center().x, -floor_y, -box.get_center().z) * SCALE
	set_root.add_child(model)
	model.owner = set_root
	# Collision.
	var body := StaticBody3D.new()
	body.name = "Collision"
	set_root.add_child(body)
	body.owner = set_root
	var solid := PackedVector3Array()
	for t in range(0, faces.size(), 3):
		var a := model.transform * faces[t]
		var b := model.transform * faces[t + 1]
		var c := model.transform * faces[t + 2]
		if maxf(a.y, maxf(b.y, c.y)) > KNEE:
			solid.append_array([a, b, c])
	var mesh_shape := ConcavePolygonShape3D.new()
	mesh_shape.set_faces(solid)
	_shape(body, "ModelShape", mesh_shape, Vector3.ZERO, set_root)
	_box(body, "Floor", Vector3(FLOOR_HALF.x * 2.0 + 1.0, 0.4, FLOOR_HALF.y * 2.0 + 1.0), Vector3(0.0, -0.2, 0.0), set_root)
	# The open sides' edges, with a gap at each step.
	var edge_x := -FLOOR_HALF.x - 0.15
	var edge_z := FLOOR_HALF.y + 0.15
	for side: float in [-1.0, 1.0]:
		var length := FLOOR_HALF.y - STEP_HALF_WIDTH + 0.3
		_box(body, "EdgeLeft%d" % (1 if side < 0.0 else 2), Vector3(0.3, 3.0, length), Vector3(edge_x, 1.5, side * (STEP_HALF_WIDTH + length * 0.5)), set_root)
		length = FLOOR_HALF.x - STEP_HALF_WIDTH + 0.3
		_box(body, "EdgeFront%d" % (1 if side < 0.0 else 2), Vector3(length, 3.0, 0.3), Vector3(side * (STEP_HALF_WIDTH + length * 0.5), 1.5, edge_z), set_root)
	# Behind the steps (so she can't walk off into space past the exits).
	_box(body, "PastLeftStep", Vector3(0.3, 3.0, STEP_HALF_WIDTH * 2.0 + 0.6), Vector3(edge_x - 1.0, 1.5, 0.0), set_root)
	_box(body, "PastFrontStep", Vector3(STEP_HALF_WIDTH * 2.0 + 0.6, 3.0, 0.3), Vector3(0.0, 1.5, edge_z + 1.0), set_root)
	# The window's live view goes here (HubRoom.has_window / _show_window_feed).
	var view_box := BoxMesh.new()
	view_box.size = Vector3(WINDOW_SIZE.x, WINDOW_SIZE.y, 0.02)
	var view := MeshInstance3D.new()
	view.name = "SpaceView"
	view.mesh = view_box
	view.visible = false  # Just marks the spot; the live view is drawn in front.
	view.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), WINDOW_CENTER)
	set_root.add_child(view)
	view.owner = set_root
	# Lights.
	_light(set_root, "Lantern", Vector3(0.9, 2.2, -1.9), Color(1.0, 0.65, 0.3), 2.2, 5.0)
	_light(set_root, "DeskLamp", Vector3(1.9, 1.3, 1.6), Color(1.0, 0.35, 0.9), 1.3, 3.0)
	_light(set_root, "Starlight", Vector3(1.4, 1.9, -0.75), Color(0.45, 0.6, 1.0), 1.2, 4.0)
	_light(set_root, "Fill", Vector3(-0.5, 2.6, 0.8), Color(0.9, 0.85, 1.0), 0.8, 6.0)
	var scene := PackedScene.new()
	var error := scene.pack(set_root)
	if error == OK:
		error = ResourceSaver.save(scene, OUTPUT)
	print("%s: %s (floor at %.3f model units, %d collision triangles)" % [OUTPUT, error_string(error), floor_y, floori(solid.size() / 3.0)])
	set_root.free()
	quit()


## Every triangle corner of the model, in its own units.
func _faces(model: Node3D) -> PackedVector3Array:
	var faces := PackedVector3Array()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var to_model := Transform3D.IDENTITY
		var walker: Node = mesh
		while walker != null and walker != model:
			if walker is Node3D:
				to_model = (walker as Node3D).transform * to_model
			walker = walker.get_parent()
		for corner in mesh.mesh.get_faces():
			faces.append(to_model * corner)
	return faces


## The floor's height: the most common height of the flat, upward-facing
## bits around the middle of the room (the rug and the deck plates).
func _floor_height(faces: PackedVector3Array, box: AABB) -> float:
	var votes := {}
	var middle := box.get_center()
	for t in range(0, faces.size(), 3):
		var a := faces[t]
		var b := faces[t + 1]
		var c := faces[t + 2]
		var center := (a + b + c) / 3.0
		if absf(center.x - middle.x) > 0.25 or absf(center.z - middle.z) > 0.25:
			continue
		if center.y < box.position.y + box.size.y * 0.2:
			continue  # (The underside of the base is flat too.)
		var normal := (b - a).cross(c - a)
		if normal.length() < 1e-9 or absf(normal.normalized().y) < 0.95:
			continue
		var bucket := roundi(center.y * 200.0)
		votes[bucket] = float(votes.get(bucket, 0.0)) + normal.length()
	var best := 0
	var most := -1.0
	for bucket: int in votes:
		if votes[bucket] > most:
			most = votes[bucket]
			best = bucket
	return best / 200.0


func _shape(body: StaticBody3D, node_name: String, shape: Shape3D, where: Vector3, owner_node: Node) -> void:
	var holder := CollisionShape3D.new()
	holder.name = node_name
	holder.shape = shape
	holder.position = where
	body.add_child(holder)
	holder.owner = owner_node


func _box(body: StaticBody3D, node_name: String, size: Vector3, where: Vector3, owner_node: Node) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	_shape(body, node_name, shape, where, owner_node)


func _light(parent: Node3D, node_name: String, where: Vector3, color: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = where
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.set_meta("paint_shadows", false)  # (Live: no shadow maps, keep it light.)
	parent.add_child(light)
	light.owner = parent
