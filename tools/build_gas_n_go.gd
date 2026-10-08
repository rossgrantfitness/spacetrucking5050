extends SceneTree
## Puts the developer's fuel station model, "Fuel Stop in the Sky"
## (res://art/models/gas_n_go_station.glb), into Gas-N-Go 47 out in space,
## res://scenes/flight/GasNGo.tscn:
##   - takes out the old placeholder canopy, pumps, kiosk and sign pole;
##   - stands the model BESIDE the lane (the lane runs along Z through the
##     place, between its two approach rings), its long deck along the lane
##     and its DRIVE-THRU FUEL sign facing you as you pull in. It's slid out
##     sideways until nothing of it is in the lane, so you never clip it;
##   - covers the model's garbled lettering (the AI-made sign came out as
##     "DRIV... FUEL", "RU", "SERHERE") with clean boards in the game's own
##     sign lettering;
##   - gives it a collision copy of its own triangles so you bonk off it.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_gas_n_go.gd
## (Safe to run again: it rebuilds the scene's contents each time. The
## placeholder station comes back with tools/build_world.gd.)

const STATION := "res://scenes/flight/GasNGo.tscn"
const MODEL := "res://art/models/gas_n_go_station.glb"
## How long the station is along the lane, in meters.
const LENGTH := 300.0
## How high the model's middle sits (the dock point, where you stop, is at
## y = -15; this puts the deck a little below your keel).
const HEIGHT := -30.0
## The lane to keep clear: half its width, its top and bottom, half its
## length (the approach rings are 350 m out each way).
const LANE_HALF_WIDTH := 18.0
const LANE_TOP := 6.0
const LANE_BOTTOM := -34.0
const LANE_HALF_LENGTH := 340.0

## The signs to cover, in the model's own units on its front (+Z) face:
## [left, bottom, right, top], the words, and the letters' size (pixels per
## model unit; smaller = bigger letters).
const SIGNS := [
	[Vector4(-0.155, 0.095, 0.075, 0.215), "GAS-N-GO 47\nDRIVE-THRU FUEL", 0.00028],
	[Vector4(-0.295, 0.105, -0.165, 0.215), "PAY\nHERE", 0.00024],
]
const BOARD_COLOR := Color(0.13, 0.12, 0.14)
const TRIM_COLOR := Color(0.55, 0.45, 0.3)
const LETTER_COLOR := Color(1.0, 0.72, 0.28)


func _initialize() -> void:
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	var body := station.get_node("Collision") as StaticBody3D
	for node in station.get_children() + body.get_children():
		if node != body:
			node.get_parent().remove_child(node)
			node.free()
	var model := (load(MODEL) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	var size := _bounds(model)
	var scale := LENGTH / size.size.x
	# A quarter turn: the model's long side (its X) runs along the lane (Z),
	# and its front (+Z, the sign) faces the lane (-X).
	model.rotation.y = -PI * 0.5
	model.scale = Vector3.ONE * scale
	model.position = Vector3(0.0, HEIGHT, 0.0)
	_add_signs(model)
	# Slide it out sideways until the lane is clear.
	var points := _points(model)
	var side := 0.0
	while side < 400.0 and _blocks_lane(points, side):
		side += 2.0
	model.position.x = side
	station.add_child(model)
	model.owner = station
	for child in model.get_children():
		if child.name.begins_with("CleanSign"):
			_own(child, station)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		if String(mesh.name).begins_with("Board"):
			continue
		var instance := mesh as MeshInstance3D
		var shape := CollisionShape3D.new()
		shape.name = "ModelShape"
		var to_station := model.transform * _transform_in(model, instance)
		var faces := instance.mesh.get_faces()
		for i in faces.size():
			faces[i] = to_station * faces[i]
		var triangles := ConcavePolygonShape3D.new()
		triangles.set_faces(faces)
		shape.shape = triangles
		body.add_child(shape, true)
		shape.owner = station
	var scene := PackedScene.new()
	var error := scene.pack(station)
	if error == OK:
		error = ResourceSaver.save(scene, STATION)
	print("%s: %s (station %.0f m beside the lane)" % [STATION, error_string(error), side])
	station.free()
	quit()


## A clean board over each garbled sign, on the model's front face.
func _add_signs(model: Node3D) -> void:
	var faces := PackedVector3Array()
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		var to_model := _transform_in(model, instance)
		for corner in instance.mesh.get_faces():
			faces.append(to_model * corner)
	for i in SIGNS.size():
		var rect: Vector4 = SIGNS[i][0]
		# The sign's surface: the front-most point of the model inside it.
		var front := -INF
		for p in faces:
			if p.x > rect.x and p.x < rect.z and p.y > rect.y and p.y < rect.w:
				front = maxf(front, p.z)
		if front == -INF:
			continue
		var holder := Node3D.new()
		holder.name = "CleanSign%d" % (i + 1)
		holder.position = Vector3((rect.x + rect.z) * 0.5, (rect.y + rect.w) * 0.5, front + 0.004)
		model.add_child(holder)
		var width := rect.z - rect.x
		var height := rect.w - rect.y
		_board(holder, "BoardTrim", Vector3(width + 0.01, height + 0.01, 0.006), Vector3(0.0, 0.0, -0.002), TRIM_COLOR)
		_board(holder, "Board", Vector3(width, height, 0.006), Vector3.ZERO, BOARD_COLOR)
		var label := Label3D.new()
		label.name = "Words"
		label.text = SIGNS[i][1]
		label.font_size = 96
		label.pixel_size = SIGNS[i][2]
		label.outline_size = 16
		label.modulate = LETTER_COLOR
		label.outline_modulate = Color(0.2, 0.08, 0.02)
		label.double_sided = false
		label.position = Vector3(0.0, 0.0, 0.0045)
		label.set_meta("no_board", true)  # (It's on a board already.)
		holder.add_child(label)


func _board(parent: Node3D, node_name: String, size: Vector3, where: Vector3, color: Color) -> void:
	var box := BoxMesh.new()
	box.size = size
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.roughness = 0.9
	box.material = paint
	var part := MeshInstance3D.new()
	part.name = node_name
	part.mesh = box
	part.position = where
	parent.add_child(part)


func _own(node: Node, owner_node: Node) -> void:
	node.owner = owner_node
	for child in node.get_children():
		_own(child, owner_node)


## Every corner of the model (not the boards), in the station's space with
## the model at the lane (side = 0).
func _points(model: Node3D) -> PackedVector3Array:
	var points := PackedVector3Array()
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		if String(mesh.name).begins_with("Board"):
			continue
		var instance := mesh as MeshInstance3D
		var to_station := model.transform * _transform_in(model, instance)
		for corner in instance.mesh.get_faces():
			points.append(to_station * corner)
	return points


func _blocks_lane(points: PackedVector3Array, side: float) -> bool:
	for p in points:
		if absf(p.x + side) < LANE_HALF_WIDTH and p.y < LANE_TOP and p.y > LANE_BOTTOM and absf(p.z) < LANE_HALF_LENGTH:
			return true
	return false


## The box around every mesh in `model` (in the model's own space).
func _bounds(model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var part := _transform_in(model, mesh) * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


## `node`'s transform relative to `top` (works outside the scene tree).
func _transform_in(top: Node3D, node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var walker: Node = node
	while walker != null and walker != top:
		if walker is Node3D:
			result = (walker as Node3D).transform * result
		walker = walker.get_parent()
	return result
