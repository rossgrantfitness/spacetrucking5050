extends "res://tools/build_hub.gd"
## Builds the newer rooms inside the rig, off the hallway:
##     GALLEY      (door "GALLEY")  - kitchen, dining table, couch, TV, arcade
##     ENGINE ROOM (door "ENGINE")  - Chang Ma's engine, workbench and cot
##     CARGO BAY   (door "CARGO")   - Clem's forklift, containers and crates
## Each gets its set (res://scenes/hub/sets/<Room>Set.tscn, pre-rendered like
## the others) and, the first time, its room scene (res://scenes/hub/<Room>.tscn)
## with cameras, a door back to the hallway, and CrewSpots: named markers
## where crew members can be (see data/crew/ and scenes/hub/ShipLife.gd).
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_rig_rooms.gd
##
## The sets are rebuilt every time. The room scenes are only written if
## they don't exist yet, so cameras and spots you move in the editor are
## safe. (Delete a room scene to have it rebuilt from here.)


const ROOM_SCRIPT := "res://scenes/hub/HubRoom.gd"
const SHOT_SCRIPT := "res://scenes/hub/RoomShot.gd"
const EXIT_SCRIPT := "res://scenes/hub/RoomExit.gd"
const PSX_SCRIPT := "res://scenes/common/PSXScreen.gd"
const PAUSE_SCENE := "res://scenes/ui/PauseMenu.tscn"


func _initialize() -> void:
	_animator_script = load(ANIMATOR_PATH)
	_build_room("Galley", _build_galley(), Vector3(8.0, 3.0, 6.0), Vector3(2.8, 0.0, 3.0), "FromGalley",
		[["Wide", Vector3(3.6, 2.6, 2.6), Vector3(-1.2, 0.6, -0.6), 64.0, Vector3(0.0, 1.4, 0.0), Vector3(8.2, 3.0, 6.2)],
		["TowardDoor", Vector3(-3.5, 2.5, -2.4), Vector3(1.8, 0.6, 1.6), 62.0, Vector3(2.4, 1.4, 1.8), Vector3(3.4, 3.0, 2.6)]],
		{"Coffee": [-2.6, 0.0, -1.95, 0.0], "Stove": [-0.6, 0.0, -1.95, 0.0], "Fridge": [2.0, 0.0, -1.7, 0.4],
		"TableNorth": [-1.2, 0.0, -0.6, PI], "TableSouth": [-1.2, 0.0, 1.2, 0.0], "TableEast": [0.0, 0.0, 0.3, PI / 2.0],
		"CouchLeft": [-3.3, 0.0, 0.7, -PI / 2.0], "CouchRight": [-3.3, 0.0, 1.9, -PI / 2.0],
		"Arcade": [3.3, 0.0, 0.3, 0.0], "Middle": [1.4, 0.0, 0.6, -0.4], "FindUnderTable": [-1.6, 0.0, 0.3, 0.0]},
		Color(0.4, 0.33, 0.3), true)
	_build_room("EngineRoom", _build_engine_room(), Vector3(7.0, 3.6, 6.0), Vector3(2.3, 0.0, 3.0), "FromEngine",
		[["Wide", Vector3(3.0, 3.0, 2.6), Vector3(-1.0, 0.8, -1.0), 64.0, Vector3(0.0, 1.6, 0.0), Vector3(7.2, 3.6, 6.2)],
		["TowardDoor", Vector3(3.0, 3.3, -2.5), Vector3(0.4, 0.4, 2.4), 64.0, Vector3(1.8, 1.6, 1.8), Vector3(3.4, 3.6, 2.6)]],
		{"Engine": [-0.8, 0.0, -0.35, 0.0], "Bench": [2.2, 0.0, -0.6, -PI / 2.0], "Cot": [-2.9, 0.42, 1.6, PI / 2.0],
		"Gauges": [-2.6, 0.0, -1.4, PI / 2.0], "Drum": [0.9, 0.0, 1.5, 0.6], "FindBehindEngine": [-2.7, 0.0, -2.5, 0.0]},
		Color(0.3, 0.32, 0.3), false)
	_build_room("CargoBay", _build_cargo_bay(), Vector3(10.0, 5.0, 8.0), Vector3(3.8, 0.0, 4.0), "FromCargo",
		[["Wide", Vector3(4.4, 3.9, 3.5), Vector3(-1.2, 1.0, -1.2), 66.0, Vector3(0.0, 2.0, 0.0), Vector3(10.2, 4.0, 8.2)],
		["TowardDoor", Vector3(-1.6, 4.3, -3.4), Vector3(3.0, 0.6, 2.8), 62.0, Vector3(3.0, 2.0, 2.4), Vector3(4.2, 4.0, 3.4)]],
		{"Forklift": [2.0, 0.0, 0.0, -0.5], "ForkliftFix": [3.3, 0.0, -1.0, PI / 2.0], "Clipboard": [0.3, 0.0, -2.6, 0.0],
		"OnCrate": [-1.4, 1.0, 2.6, 0.0], "Crates": [-1.2, 0.0, 1.0, -0.6], "FindBetweenCrates": [-2.6, 0.0, 1.0, 0.0]},
		Color(0.32, 0.32, 0.38), false)
	quit()


## Saves the set, and the room scene the first time.
func _build_room(room_name: String, set_root: Node3D, size: Vector3, door: Vector3, hallway_spawn: String,
		shots: Array, spots: Dictionary, ambient: Color, radio: bool) -> void:
	var set_path := "res://scenes/hub/sets/%sSet.tscn" % room_name
	_save(set_root, set_path)
	var room_path := "res://scenes/hub/%s.tscn" % room_name
	if ResourceLoader.exists(room_path):
		print("%s: kept (delete it to rebuild it)" % room_path)
		return
	var room := Node3D.new()
	room.name = room_name
	room.set_script(load(ROOM_SCRIPT))
	room.set("default_spawn", "FromHallway")
	room.set("radio_speakers", radio)
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = 0.6
	environment.environment = env
	room.add_child(environment)
	var set_node := (ResourceLoader.load(set_path, "", ResourceLoader.CACHE_MODE_REPLACE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	set_node.name = "Set"
	room.add_child(set_node)
	var shots_node := _group(room, "Shots")
	for shot: Array in shots:
		var shot_node := Node3D.new()
		shot_node.name = shot[0]
		shot_node.set_script(load(SHOT_SCRIPT))
		shots_node.add_child(shot_node)
		var camera := Camera3D.new()
		camera.name = "Camera"
		camera.fov = shot[3]
		camera.near = 0.1
		camera.far = 100.0
		camera.transform = Transform3D(Basis.looking_at(shot[2] - shot[1], Vector3.UP), shot[1])
		shot_node.add_child(camera)
		var zone := Area3D.new()
		zone.name = "Zone"
		shot_node.add_child(zone)
		var zone_shape := CollisionShape3D.new()
		zone_shape.name = "Shape"
		var box := BoxShape3D.new()
		box.size = shot[5]
		zone_shape.shape = box
		zone_shape.position = shot[4]
		zone.add_child(zone_shape)
	var spawns := _group(room, "Spawns")
	_marker(spawns, "FromHallway", door + Vector3(0.0, 0.0, -0.8), 0.0)
	var exits := _group(room, "Exits")
	var exit := Area3D.new()
	exit.name = "HallwayDoor"
	exit.set_script(load(EXIT_SCRIPT))
	exit.set("target_scene", "res://scenes/hub/Hallway.tscn")
	exit.set("target_spawn", hallway_spawn)
	exit.position = door + Vector3(0.0, 1.0, -0.25)
	exits.add_child(exit)
	var exit_shape := CollisionShape3D.new()
	exit_shape.name = "Shape"
	var exit_box := BoxShape3D.new()
	exit_box.size = Vector3(1.1, 2.0, 0.5)
	exit_shape.shape = exit_box
	exit.add_child(exit_shape)
	_group(room, "People")
	var things := _group(room, "Things")
	if room_name == "CargoBay":
		var sign_label := Label3D.new()
		sign_label.name = "CargoSign"
		sign_label.text = "IN THE BACK: NOTHING. YET."
		sign_label.font_size = 64
		sign_label.pixel_size = 0.006
		sign_label.modulate = Color(1.0, 0.8, 0.3)
		sign_label.outline_size = 12
		sign_label.position = Vector3(0.0, 4.3, -size.z * 0.5 + 0.1)
		things.add_child(sign_label)
	var crew_spots := _group(room, "CrewSpots")
	for spot_name: String in spots:
		var spot: Array = spots[spot_name]
		_marker(crew_spots, spot_name, Vector3(spot[0], spot[1], spot[2]), spot[3])
	var psx := CanvasLayer.new()
	psx.name = "PSXScreen"
	psx.layer = 0
	psx.set_script(load(PSX_SCRIPT))
	room.add_child(psx)
	var pause := (load(PAUSE_SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	pause.name = "PauseMenu"
	pause.set("flying", false)
	room.add_child(pause)
	_save_room(room, room_path)
	print("%s: built (%d m x %d m)" % [room_path, size.x, size.z])


func _group(parent: Node, group_name: String) -> Node3D:
	var node := Node3D.new()
	node.name = group_name
	parent.add_child(node)
	return node


func _marker(parent: Node, marker_name: String, where: Vector3, facing_y: float) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = where
	marker.rotation = Vector3(0.0, facing_y, 0.0)
	parent.add_child(marker)


## Saves a room scene, keeping instanced scenes (the set, the pause menu)
## as instances rather than copying their insides.
func _save_room(room: Node, path: String) -> void:
	_claim_shallow(room, room)
	var scene := PackedScene.new()
	var error := scene.pack(room)
	if error == OK:
		error = ResourceSaver.save(scene, path)
	print("%s: %s" % [path, error_string(error)])
	room.free()


func _claim_shallow(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		if child.scene_file_path.is_empty():
			_claim_shallow(child, scene_root)


## The four walls, floor and ceiling, a door to the hallway (on the +Z wall),
## and the usual neon trim. Returns [set_root, body].
func _rig_room(set_name: String, size: Vector3, door_x: float, wall: Material, floor_material: Material) -> Array:
	var parts := _new_set(set_name)
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	_room_shell(room, body, size, floor_material, wall, _set_paint(Color(0.2, 0.2, 0.26)))
	_door_panel(room, "HallwayDoor", Vector3(door_x, 1.1, size.z * 0.5 - 0.03), PI)
	return parts


# --- The galley ---------------------------------------------------------------------
# 8 x 6 m, 3 m tall: a galley kitchen along the back, a dining table with
# stools, a mustard couch facing a big TV, an arcade cabinet, a porthole
# onto space, hanging lamps. The crew's living room.

func _build_galley() -> Node3D:
	var size := Vector3(8.0, 3.0, 6.0)
	var parts := _rig_room("GalleySet", size, 2.8, _set_paint(Color(0.45, 0.58, 0.58), WALL_PANELS, 2.0), _set_paint(Color(0.95, 0.85, 0.75), FLOOR_TILES, 1.2))
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var wood := _set_paint(Color(1.0, 1.0, 1.0), WOOD, 0.8)
	var dark := _set_paint(Color(0.2, 0.2, 0.25))
	# The kitchen along the back wall.
	_piece(room, body, "Counter", Vector3(5.0, 0.9, 0.7), Vector3(-0.9, 0.45, -2.65), _set_paint(Color(0.9, 0.55, 0.38)))
	_box(room, "CounterTop", Vector3(5.1, 0.06, 0.78), Vector3(-0.9, 0.93, -2.62), dark)
	_box(room, "Cabinets", Vector3(5.0, 0.7, 0.4), Vector3(-0.9, 2.2, -2.8), _set_paint(Color(0.95, 0.85, 0.7), WOOD, 0.8))
	_box(room, "StoveTop", Vector3(0.8, 0.04, 0.6), Vector3(-0.6, 0.97, -2.62), _set_paint(Color(1.0, 0.45, 0.2), null, 1.0, 1.4))
	_box(room, "Pot", Vector3(0.3, 0.25, 0.3), Vector3(-0.6, 1.12, -2.62), _set_paint(Color(0.7, 0.72, 0.78)))
	_piece(room, body, "Fridge", Vector3(0.9, 2.0, 0.8), Vector3(2.6, 1.0, -2.55), _set_paint(Color(0.92, 0.94, 0.95)))
	_box(room, "FridgeHandle", Vector3(0.05, 0.6, 0.06), Vector3(2.25, 1.2, -2.13), dark)
	_box(room, "FridgeMagnets", Vector3(0.5, 0.4, 0.02), Vector3(2.65, 1.5, -2.14), _set_paint(Color.WHITE, JOB_BOARD, 0.6))
	_box(room, "CoffeeMachine", Vector3(0.4, 0.5, 0.35), Vector3(-2.6, 1.21, -2.62), _set_paint(Color(0.85, 0.2, 0.25)))
	_box(room, "CoffeeLight", Vector3(0.08, 0.06, 0.02), Vector3(-2.6, 1.32, -2.44), _set_paint(Color(0.4, 1.0, 0.5), null, 1.0, 2.0))
	# The dining table and four low stools.
	_piece(room, body, "Table", Vector3(1.8, 0.08, 1.0), Vector3(-1.2, 0.72, 0.3), wood)
	for leg: Vector3 in [Vector3(-2.0, 0.35, -0.1), Vector3(-0.4, 0.35, -0.1), Vector3(-2.0, 0.35, 0.7), Vector3(-0.4, 0.35, 0.7)]:
		_box(room, "TableLeg", Vector3(0.08, 0.7, 0.08), leg, dark)
	for stool: Vector3 in [Vector3(-1.2, 0.2, -0.6), Vector3(-1.2, 0.2, 1.2), Vector3(0.0, 0.2, 0.3)]:
		_cylinder(room, "Stool", 0.22, 0.4, stool, _set_paint(Color(0.3, 0.6, 0.62)), Vector3.ZERO, 8)
	_box(room, "Mugs", Vector3(0.3, 0.1, 0.15), Vector3(-1.0, 0.81, 0.4), _set_paint(Color(0.95, 0.9, 0.85)))
	# The couch along the left wall, facing the TV on the right wall.
	var mustard := _set_paint(Color(0.85, 0.65, 0.25))
	_piece(room, body, "CouchSeat", Vector3(0.9, 0.42, 2.4), Vector3(-3.5, 0.21, 1.3), mustard)
	_box(room, "CouchBack", Vector3(0.25, 0.85, 2.4), Vector3(-3.87, 0.62, 1.3), mustard)
	_box(room, "CouchArmA", Vector3(0.9, 0.6, 0.2), Vector3(-3.5, 0.3, 0.05), mustard)
	_box(room, "CouchArmB", Vector3(0.9, 0.6, 0.2), Vector3(-3.5, 0.3, 2.55), mustard)
	_box(room, "Cushion", Vector3(0.3, 0.35, 0.4), Vector3(-3.6, 0.6, 0.4), _set_paint(Color(0.9, 0.35, 0.5)))
	_box(room, "TV", Vector3(0.1, 1.0, 1.6), Vector3(3.92, 1.5, 1.3), dark)
	_box(room, "TVScreen", Vector3(0.02, 0.85, 1.45), Vector3(3.86, 1.5, 1.3), _set_paint(Color(0.45, 0.75, 1.0), null, 1.0, 1.2))
	# The arcade cabinet in the corner (it plays Asteroid Alley, obviously).
	_piece(room, body, "Arcade", Vector3(0.9, 1.9, 0.8), Vector3(3.4, 0.95, -0.7), _set_paint(Color(0.45, 0.25, 0.7)))
	_box(room, "ArcadeScreen", Vector3(0.6, 0.45, 0.02), Vector3(3.4, 1.35, -0.29), _set_paint(Color(0.3, 1.0, 0.6), null, 1.0, 1.6))
	# A porthole onto space, a neon sign, a poster, lamps.
	_box(room, "Porthole", Vector3(0.05, 1.0, 1.4), Vector3(-3.96, 1.7, -1.2), _set_paint(Color.WHITE, SPACE_VIEW, 1.4, 0.9))
	_sign(room, "GalleySign", "MESS HALL", 0.004, Color(1.0, 0.45, 0.75), Vector3(-1.0, 2.75, -2.55))
	_box(room, "Poster", Vector3(0.8, 1.1, 0.02), Vector3(0.9, 1.7, 2.97), _set_paint(Color(1.0, 0.55, 0.2)))
	_cylinder(room, "LampShade", 0.35, 0.25, Vector3(-1.2, 2.5, 0.3), _set_paint(Color(1.0, 0.9, 0.6), null, 1.0, 1.4), Vector3.ZERO, 10)
	_lamp(room, "TableLamp", Vector3(-1.2, 2.2, 0.3), Color(1.0, 0.82, 0.55), 1.8, 5.5)
	_lamp(room, "KitchenLamp", Vector3(0.0, 2.6, -1.8), Color(0.85, 0.95, 1.0), 1.0, 5.0, false)
	_lamp(room, "TVGlow", Vector3(3.2, 1.5, 1.3), Color(0.5, 0.75, 1.0), 0.8, 3.5, false)
	_lamp(room, "ArcadeGlow", Vector3(3.0, 1.4, -0.2), Color(0.6, 0.3, 1.0), 0.8, 3.0, false)
	return room


# --- The engine room ------------------------------------------------------------------
# 7 x 6 m, 3.6 m tall: the big engine (a drum with a glowing core) at the
# back, pipes, a machinery wall, Chang Ma's workbench and cot, an oil drum.

func _build_engine_room() -> Node3D:
	var size := Vector3(7.0, 3.6, 6.0)
	var parts := _rig_room("EngineRoomSet", size, 2.3, _set_paint(Color(0.42, 0.48, 0.44), WALL_PANELS, 2.0), _set_paint(Color(0.8, 0.82, 0.88), GRATE, 0.6))
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var hull := _set_paint(Color(0.7, 0.72, 0.78), PIPES, 0.8)
	var dark := _set_paint(Color(0.18, 0.18, 0.22))
	# The engine: a big drum on its side, with a glowing core band.
	var engine := _cylinder(room, "Engine", 1.0, 3.0, Vector3(-0.8, 1.2, -1.8), _set_paint(Color(0.75, 0.75, 0.8)), Vector3(0.0, 0.0, PI / 2.0), 12)
	engine.position.y = 1.25
	# Something solid to bump into (just its collision; the drum is the look).
	var block := _box(room, "EngineBlock", Vector3(3.0, 2.0, 2.0), Vector3(-0.8, 1.0, -1.8), dark)
	_add_collision(body, block)
	room.remove_child(block)
	block.free()
	_cylinder(room, "Core", 1.05, 0.5, Vector3(-0.8, 1.25, -1.8), _set_paint(Color(1.0, 0.55, 0.2), null, 1.0, 2.2), Vector3(0.0, 0.0, PI / 2.0), 12)
	_box(room, "EngineBase", Vector3(3.4, 0.3, 2.3), Vector3(-0.8, 0.15, -1.8), _hazard(3.0))
	# Pipes running up into the ceiling, and a machinery wall.
	for x: float in [-2.9, -2.5, 1.1, 1.5]:
		_box(room, "Pipe", Vector3(0.3, 3.6, 0.3), Vector3(x, 1.8, -2.8), hull)
	_box(room, "MachineWall", Vector3(0.1, 2.4, 2.2), Vector3(-3.45, 1.4, -1.4), _set_paint(Color(0.9, 0.9, 1.0), MACHINERY, 2.2))
	# Chang Ma's workbench along the right wall, with tools on a board.
	_piece(room, body, "Workbench", Vector3(0.8, 0.9, 2.4), Vector3(3.05, 0.45, -0.6), _set_paint(Color(1.0, 1.0, 1.0), WOOD, 0.8))
	_box(room, "ToolBoard", Vector3(0.05, 1.2, 2.2), Vector3(3.45, 1.7, -0.6), _set_paint(Color(0.9, 0.9, 1.0), MACHINERY, 1.4))
	_box(room, "Vise", Vector3(0.25, 0.2, 0.2), Vector3(3.0, 1.0, -1.4), dark)
	_box(room, "Radio", Vector3(0.35, 0.22, 0.2), Vector3(3.0, 1.01, 0.2), _set_paint(Color(0.85, 0.65, 0.3)))
	# His cot in the corner, an oil drum, crates of parts.
	_piece(room, body, "Cot", Vector3(0.9, 0.4, 2.0), Vector3(-2.9, 0.2, 1.6), _set_paint(Color(0.45, 0.5, 0.35)))
	_box(room, "Blanket", Vector3(0.85, 0.06, 1.2), Vector3(-2.9, 0.43, 1.9), _set_paint(Color.WHITE, BLANKET, 0.8))
	_piece(room, body, "OilDrum", Vector3(0.6, 0.9, 0.6), Vector3(1.4, 0.45, 2.1), _set_paint(Color(0.3, 0.45, 0.8)))
	_piece(room, body, "PartsCrate", Vector3(0.8, 0.6, 0.6), Vector3(0.2, 0.3, 2.4), _set_paint(Color.WHITE, CRATE, 0.8))
	_sign(room, "EngineSign", "ENGINE ROOM", 0.004, Color(1.0, 0.75, 0.3), Vector3(1.8, 3.2, -2.9))
	_lamp(room, "CoreGlow", Vector3(-0.8, 1.4, -0.4), Color(1.0, 0.6, 0.3), 2.2, 6.0)
	_lamp(room, "WorkLamp", Vector3(2.6, 2.6, -0.6), Color(0.85, 0.95, 1.0), 1.2, 5.0, false)
	return room


# --- The cargo bay ----------------------------------------------------------------------
# 10 x 8 m, 5 m tall: stacked containers, crates, Clem's forklift, the big
# loading door at the back with hazard stripes, and a sign saying what's in
# the back (filled in as you play).

func _build_cargo_bay() -> Node3D:
	var size := Vector3(10.0, 5.0, 8.0)
	var parts := _rig_room("CargoBaySet", size, 3.8, _set_paint(Color(0.5, 0.52, 0.58), WALL_PANELS, 2.5), _set_paint(Color(0.85, 0.85, 0.9), FLOOR_TILES, 1.6))
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var colors: Array[Color] = [Color(0.8, 0.38, 0.22), Color(0.22, 0.56, 0.6), Color(0.9, 0.7, 0.22), Color(0.52, 0.32, 0.64)]
	# Containers stacked along the left wall.
	for i in 3:
		_piece(room, body, "Container", Vector3(2.4, 2.4, 2.4), Vector3(-3.7, 1.2, -2.6 + i * 2.5), _set_paint(colors[i], CONTAINER, 2.4))
	_box(room, "ContainerTop", Vector3(2.4, 2.4, 2.4), Vector3(-3.7, 3.6, -1.35), _set_paint(colors[3], CONTAINER, 2.4))
	# Crates: a little stack to sit on, and some loose ones.
	_piece(room, body, "CrateA", Vector3(1.0, 1.0, 1.0), Vector3(-1.4, 0.5, 3.0), _set_paint(Color.WHITE, CRATE, 1.0))
	_piece(room, body, "CrateB", Vector3(1.0, 1.0, 1.0), Vector3(-2.5, 0.5, 2.0), _set_paint(Color.WHITE, CRATE, 1.0))
	_piece(room, body, "CrateC", Vector3(0.8, 0.8, 0.8), Vector3(-2.5, 1.4, 2.0), _set_paint(Color.WHITE, CRATE, 0.8))
	_piece(room, body, "Pallet", Vector3(1.4, 0.15, 1.2), Vector3(0.5, 0.08, 1.8), _set_paint(Color(1.0, 1.0, 1.0), WOOD, 0.6))
	# The big loading door at the back, framed with hazard stripes.
	_box(room, "LoadingDoor", Vector3(6.0, 3.8, 0.1), Vector3(1.0, 1.9, -3.94), _set_paint(Color(0.7, 0.72, 0.78), WALL_PANELS, 0.8))
	_box(room, "DoorFrameTop", Vector3(6.4, 0.25, 0.12), Vector3(1.0, 3.9, -3.93), _hazard(3.0))
	_box(room, "DoorFrameLeft", Vector3(0.25, 3.8, 0.12), Vector3(-2.1, 1.9, -3.93), _hazard(3.0))
	_box(room, "DoorFrameRight", Vector3(0.25, 3.8, 0.12), Vector3(4.1, 1.9, -3.93), _hazard(3.0))
	_box(room, "FloorLine", Vector3(6.0, 0.02, 0.15), Vector3(1.0, 0.011, -2.8), _hazard(4.0))
	# Clem's forklift.
	var yellow := _set_paint(Color(1.0, 0.78, 0.15))
	_piece(room, body, "ForkliftBody", Vector3(1.0, 0.9, 1.6), Vector3(3.0, 0.55, 0.4), yellow)
	_box(room, "ForkliftSeat", Vector3(0.6, 0.15, 0.5), Vector3(3.0, 1.08, 0.7), _set_paint(Color(0.2, 0.2, 0.25)))
	_box(room, "ForkliftMast", Vector3(0.9, 2.2, 0.12), Vector3(3.0, 1.1, -0.45), _set_paint(Color(0.3, 0.3, 0.35)))
	for x: float in [2.75, 3.25]:
		_box(room, "Fork", Vector3(0.12, 0.06, 1.0), Vector3(x, 0.2, -1.0), _set_paint(Color(0.3, 0.3, 0.35)))
	for wheel: Vector3 in [Vector3(2.5, 0.2, 0.9), Vector3(3.5, 0.2, 0.9), Vector3(2.5, 0.2, -0.1), Vector3(3.5, 0.2, -0.1)]:
		_cylinder(room, "Wheel", 0.2, 0.15, wheel, _set_paint(Color(0.1, 0.1, 0.12)), Vector3(0.0, 0.0, PI / 2.0), 8)
	_sign(room, "BaySign", "CARGO BAY 1", 0.005, Color(0.4, 0.95, 1.0), Vector3(-3.5, 4.4, 3.9))
	_lamp(room, "BayLampA", Vector3(-1.5, 4.5, 0.0), Color(0.9, 0.95, 1.0), 1.6, 8.0)
	_lamp(room, "BayLampB", Vector3(2.5, 4.5, -1.5), Color(1.0, 0.85, 0.6), 1.2, 7.0, false)
	return room
