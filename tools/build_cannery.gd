extends "res://tools/build_truck_stop.gd"
## Builds Tidewater Cannery's canteen (where you climb out after docking at
## Tidewater) and Gill, who runs it:
##     res://scenes/hub/sets/CanneryCanteenSet.tscn   - the room: canteen
##                                                       counter, tables,
##                                                       conveyor belts of cans,
##                                                       a big window onto the
##                                                       ocean planet
##     res://scenes/hub/OtterVisual.tscn              - Gill
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_cannery.gd
##
## Careful: running it again OVERWRITES those scenes. The room itself
## (res://scenes/hub/CanneryCanteen.tscn, with its cameras, doors, people
## and things to use) is NOT touched. It borrows everything from
## build_truck_stop.gd and build_hub.gd.

const OCEAN := preload("res://textures/generated/ocean_planet.png")


func _initialize() -> void:
	_animator_script = load(ANIMATOR_PATH)
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_save(_otter(), "res://scenes/hub/OtterVisual.tscn")
	_save(_build_canteen(), "res://scenes/hub/sets/CanneryCanteenSet.tscn")
	quit()


## Gill: a sleepy otter in a yellow fishing hat. Hook: whiskers, and a long
## tapering tail.
func _otter() -> Node3D:
	var critter := _build_critter("OtterVisual", _look(Color(0.52, 0.38, 0.28), Color(0.85, 0.75, 0.62), Color(0.2, 0.45, 0.5), Color(0.25, 0.3, 0.35), Color(0, 0, 0, 0), "round", "puff"))
	var head := _head(critter)
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic", "Body/Tail"])
	for ear in ["Body/Head/EarLeft", "Body/Head/EarRight"]:
		(critter.get_node(ear) as Node3D).scale = Vector3(0.6, 0.45, 0.6)
	var whisker := _paint(Color(0.95, 0.93, 0.88), null)
	for side: float in [-1.0, 1.0]:
		for row in 2:
			var hair := _box(head, "Whisker", Vector3(0.16, 0.008, 0.008), Vector3(0.14 * side, 0.1 + row * 0.03, -0.2), whisker)
			hair.rotation = Vector3(0.0, 0.25 * side, (0.1 - row * 0.2) * side)
	# The fishing hat: a soft crown and a wide floppy brim.
	_loft(head, "HatCrown", Vector3(0.0, 0.4, 0.15), Vector2(0.36, 0.1), Vector3(0.0, 0.4, -0.15), Vector2(0.36, 0.1), _paint(Color(0.95, 0.8, 0.3), null), 0.4)
	_box(head, "HatBrim", Vector3(0.52, 0.02, 0.52), Vector3(0.0, 0.37, 0.0), _paint(Color(0.95, 0.8, 0.3), null))
	var tail_color := _paint(Color(0.45, 0.33, 0.24), FUZZ, Vector2(8, 8))
	for piece in 3:
		_box(critter.get_node("Body") as Node3D, "Tail", Vector3(0.12 - piece * 0.03, 0.08 - piece * 0.015, 0.16), Vector3(0.0, -0.18 - piece * 0.05, 0.16 + piece * 0.14), tail_color)
	return critter


# --- The canteen --------------------------------------------------------------------------
# 20 x 16 m, 6 m tall. Back (-Z) is a wide window onto Tidewater's ocean
# planet. Left: Gill's canteen counter and tables. Right: the cannery floor
# (conveyor belts of cans, crates, a can pyramid, a crane hook). The
# airlock to your rig is on the right (+X) wall, near the front.

func _build_canteen() -> Node3D:
	var parts := _new_set("CanneryCanteenSet")
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var size := Vector3(20.0, 6.0, 16.0)
	var wall := _set_paint(Color(0.24, 0.42, 0.46), WALL_PANELS, 3.0)
	var dark := _set_paint(Color(0.1, 0.16, 0.18))
	var metal := _set_paint(Color(0.55, 0.6, 0.62))
	_room_shell(room, body, size, _set_paint(Color(0.75, 0.85, 0.85), FLOOR_TILES, 1.6), wall, _set_paint(Color(0.08, 0.12, 0.14)))
	_ocean_window(room, body, wall)
	_canteen(room, body, dark, metal)
	_cannery_floor(room, body, dark, metal)
	_cannery_extras(room, body, dark)
	_canteen_lights(room)
	return room


## The back wall: a long window onto the ocean planet, teal and huge.
func _ocean_window(room: Node3D, body: StaticBody3D, wall: Material) -> void:
	room.get_node("WallBack").free()
	body.get_node("WallBackShape").free()
	_piece(room, body, "WallBackLeft", Vector3(3.0, 6.0, 0.2), Vector3(-8.5, 3.0, -8.1), wall)
	_piece(room, body, "WallBackRight", Vector3(3.0, 6.0, 0.2), Vector3(8.5, 3.0, -8.1), wall)
	_piece(room, body, "WallBackLow", Vector3(14.0, 1.0, 0.2), Vector3(0.0, 0.5, -8.1), wall)
	_piece(room, body, "WallBackHigh", Vector3(14.0, 1.0, 0.2), Vector3(0.0, 5.5, -8.1), wall)
	var quad := QuadMesh.new()
	quad.size = Vector2(14.0, 4.0)
	var view := StandardMaterial3D.new()
	view.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	view.albedo_texture = OCEAN
	view.albedo_color = Color(0.85, 1.0, 1.0)
	view.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	view.uv1_scale = Vector3(0.6, 0.6, 1.0)
	view.uv1_offset = Vector3(0.2, 0.2, 0.0)
	quad.material = view
	_mesh(room, "OceanView", quad, Vector3(0.0, 3.0, -8.3), Vector3.ZERO)
	var frame := _set_paint(Color(0.15, 0.2, 0.22))
	for x: float in [-3.5, 0.0, 3.5]:
		_box(room, "WindowMullion", Vector3(0.2, 4.0, 0.25), Vector3(x, 3.0, -8.0), frame)
	_box(room, "WindowNeon", Vector3(14.0, 0.08, 0.08), Vector3(0.0, 5.0, -7.95), _set_paint(Color(0.35, 1.0, 0.85), null, 1.0, 2.0))


## Gill's canteen: a counter with a raised floor behind it, a coffee
## machine (somewhere), a fish-shaped neon sign, tables and stools.
func _canteen(room: Node3D, body: StaticBody3D, dark: Material, metal: Material) -> void:
	_box(room, "CanteenFloor", Vector3(9.8, 0.02, 15.6), Vector3(-5.0, 0.011, 0.0), _set_paint(Color(1.0, 1.0, 1.0), CARPET, 0.8))
	_piece(room, body, "Counter", Vector3(6.0, 0.9, 0.8), Vector3(-6.0, 0.45, -4.0), _set_paint(Color(0.95, 0.75, 0.3)))
	_box(room, "CounterTop", Vector3(6.2, 0.08, 1.0), Vector3(-6.0, 0.94, -4.0), _set_paint(Color(0.9, 0.92, 0.9)))
	_piece(room, body, "CounterPlatform", Vector3(6.0, 0.6, 3.0), Vector3(-6.0, 0.3, -6.3), _set_paint(Color(0.3, 0.36, 0.4)))
	_box(room, "CoffeeMachine", Vector3(0.6, 0.7, 0.45), Vector3(-8.4, 1.3, -4.1), _set_paint(Color(0.3, 0.6, 0.65)))
	_box(room, "FishFryer", Vector3(1.0, 0.5, 0.6), Vector3(-4.0, 1.2, -4.1), metal)
	for i in 5:
		_cylinder(room, "Stool", 0.28, 0.1, Vector3(-8.0 + i * 1.0, 0.72, -3.0), _set_paint(Color(0.3, 0.85, 0.8)), Vector3.ZERO, 10)
		_cylinder(room, "StoolPost", 0.05, 0.68, Vector3(-8.0 + i * 1.0, 0.34, -3.0), metal, Vector3.ZERO, 6)
	_box(room, "CanteenSignBack", Vector3(5.0, 1.0, 0.1), Vector3(-6.0, 4.3, -7.9), dark)
	_sign(room, "CanteenSign", "GILL'S CANTEEN", 0.006, Color(1.0, 0.8, 0.3), Vector3(-6.0, 4.4, -7.82))
	_sign(room, "CanteenSignSub", "FISH · COFFEE (SOMEWHERE) · PIE (SOMETIMES)", 0.0022, Color(0.4, 1.0, 0.85), Vector3(-6.0, 3.95, -7.82))
	# A neon fish over the counter.
	_box(room, "NeonFishBody", Vector3(1.6, 0.6, 0.06), Vector3(-6.0, 3.0, -7.9), _set_paint(Color(1.0, 0.5, 0.75), null, 1.0, 2.2))
	_box(room, "NeonFishTail", Vector3(0.5, 0.7, 0.06), Vector3(-4.9, 3.0, -7.9), _set_paint(Color(0.4, 1.0, 0.9), null, 1.0, 2.2))
	# Tables.
	for spot: Vector3 in [Vector3(-7.5, 0.0, 2.0), Vector3(-3.5, 0.0, 2.0), Vector3(-7.5, 0.0, 5.5), Vector3(-3.5, 0.0, 5.5)]:
		_piece(room, body, "Table", Vector3(1.4, 0.75, 1.0), spot + Vector3(0.0, 0.38, 0.0), _set_paint(Color(0.9, 0.92, 0.9)))
		for side: float in [-1.0, 1.0]:
			_cylinder(room, "TableStool", 0.25, 0.45, spot + Vector3(side * 1.0, 0.23, 0.0), _set_paint(Color(0.95, 0.75, 0.3)), Vector3.ZERO, 8)
		_cylinder(room, "TableCan", 0.1, 0.22, spot + Vector3(0.2, 0.86, 0.1), _set_paint(Color(0.85, 0.3, 0.3)), Vector3.ZERO, 8)
	# The jukebox (it's always on Tide 77).
	_piece(room, body, "Jukebox", Vector3(0.7, 1.5, 1.1), Vector3(-9.5, 0.75, 3.5), _set_paint(Color(0.3, 0.55, 0.55), WOOD, 0.8))
	_box(room, "JukeboxGlow", Vector3(0.05, 0.9, 0.8), Vector3(-9.13, 0.9, 3.5), _set_paint(Color(0.4, 1.0, 0.9), null, 1.0, 2.2))


## The cannery floor: two conveyor belts of cans, crates, a pyramid of
## canned starfish, and a crane hook over it all.
func _cannery_floor(room: Node3D, body: StaticBody3D, dark: Material, metal: Material) -> void:
	_box(room, "WorkFloor", Vector3(9.8, 0.02, 9.0), Vector3(5.0, 0.011, -3.5), _set_paint(Color(0.55, 0.6, 0.6)))
	_box(room, "WorkFloorEdge", Vector3(0.3, 0.03, 9.0), Vector3(0.2, 0.02, -3.5), _hazard(2.0))
	var can_colors: Array[Color] = [Color(0.85, 0.3, 0.3), Color(0.3, 0.75, 0.85), Color(0.95, 0.8, 0.3)]
	for belt_z: float in [-6.0, -2.5]:
		_piece(room, body, "Conveyor", Vector3(8.0, 0.9, 1.0), Vector3(5.5, 0.45, belt_z), dark)
		_box(room, "ConveyorBelt", Vector3(8.0, 0.04, 0.9), Vector3(5.5, 0.92, belt_z), _set_paint(Color(0.2, 0.2, 0.22), SET_VENTS, 0.5))
		for i in 12:
			_cylinder(room, "Can", 0.12, 0.26, Vector3(2.0 + i * 0.62, 1.07, belt_z), _set_paint(can_colors[i % 3]), Vector3.ZERO, 8)
	_box(room, "CannerySignBack", Vector3(6.0, 1.0, 0.1), Vector3(5.0, 4.6, -7.9), dark)
	_sign(room, "CannerySign", "TIDEWATER CANNERY", 0.006, Color(0.4, 1.0, 0.85), Vector3(5.0, 4.7, -7.82))
	_sign(room, "CannerySignSub", "WE CAN, THEREFORE WE ARE", 0.0025, Color(1.0, 0.55, 0.75), Vector3(5.0, 4.25, -7.82))
	# The can pyramid.
	for layer in 4:
		for i in 4 - layer:
			_cylinder(room, "PyramidCan", 0.2, 0.42, Vector3(8.2 + i * 0.42 + layer * 0.21, 0.21 + layer * 0.42, 1.2), _set_paint(Color(1.0, 0.55, 0.75)), Vector3.ZERO, 10)
	# Crates.
	for crate: Vector3 in [Vector3(3.0, 0.0, 1.5), Vector3(3.0, 1.0, 1.5), Vector3(4.2, 0.0, 1.3)]:
		_piece(room, body, "Crate", Vector3(1.0, 1.0, 1.0), crate + Vector3(0.0, 0.5, 0.0), _set_paint(Color(1.0, 1.0, 1.0), CRATE, 1.0))
	# The crane hook, hanging from a rail.
	_box(room, "CraneRail", Vector3(9.0, 0.2, 0.3), Vector3(5.0, 5.7, -4.0), metal)
	_beam(room, "CraneCable", Vector3(6.0, 5.6, -4.0), Vector3(6.0, 3.2, -4.0), 0.03, metal)
	_box(room, "CraneHook", Vector3(0.3, 0.4, 0.1), Vector3(6.0, 3.0, -4.0), _hazard(4.0))


## The fish tank, the DJ hatch, the airlock and the job board.
func _cannery_extras(room: Node3D, body: StaticBody3D, dark: Material) -> void:
	_piece(room, body, "FishTank", Vector3(2.0, 1.2, 0.6), Vector3(-1.0, 0.6, 7.6), _set_paint(Color(0.3, 0.8, 1.0), null, 1.0, 0.9))
	for i in 3:
		_box(room, "TankFish", Vector3(0.2, 0.1, 0.02), Vector3(-1.6 + i * 0.6, 0.6 + (i % 2) * 0.25, 7.28), _set_paint(Color(1.0, 0.6, 0.3), null, 1.0, 1.5))
	# A hatch in the floor: Tide 77 broadcasts from down there.
	_box(room, "RadioHatch", Vector3(1.2, 0.03, 1.2), Vector3(1.5, 0.02, 5.5), _hazard(3.0))
	_box(room, "OnAirLight", Vector3(0.6, 0.2, 0.05), Vector3(1.5, 2.6, 7.9), _set_paint(Color(1.0, 0.25, 0.3), null, 1.0, 2.5))
	_sign(room, "OnAirSign", "TIDE 77 · ON AIR · BELOW", 0.0025, Color(1.0, 0.4, 0.45), Vector3(1.5, 2.95, 7.85))
	(room.get_node("OnAirSign") as Node3D).rotation = Vector3(0.0, PI, 0.0)
	# The airlock to your rig, on the right wall.
	_box(room, "AirlockFrame", Vector3(0.3, 3.4, 3.0), Vector3(9.85, 1.7, 5.5), dark)
	_box(room, "AirlockDoor", Vector3(0.06, 2.6, 2.0), Vector3(9.7, 1.3, 5.5), _set_paint(Color(0.85, 0.85, 0.9), DOOR, 2.6))
	_box(room, "AirlockStripes", Vector3(0.04, 0.3, 3.0), Vector3(9.66, 3.0, 5.5), _hazard(2.0))
	_sign(room, "AirlockSign", "DOCK 1 · YOUR RIG", 0.004, Color(0.45, 0.95, 1.0), Vector3(9.6, 3.6, 5.5))
	(room.get_node("AirlockSign") as Node3D).rotation = Vector3(0.0, -PI / 2.0, 0.0)
	# The job board, by the window.
	_box(room, "JobBoardFrame", Vector3(3.2, 2.0, 0.2), Vector3(-0.5, 2.0, -7.6), dark)
	_box(room, "JobBoard", Vector3(3.0, 1.8, 0.05), Vector3(-0.5, 2.0, -7.48), _set_paint(Color.WHITE, JOB_BOARD, 3.0, 0.35))
	_sign(room, "JobBoardSign", "LOADS OUT", 0.004, Color(0.45, 0.95, 1.0), Vector3(-0.5, 3.25, -7.45))
	# The pump kiosk.
	_piece(room, body, "PumpKiosk", Vector3(0.9, 1.8, 0.7), Vector3(8.0, 0.9, 3.8), _set_paint(Color(0.3, 0.75, 0.7)))
	_box(room, "PumpScreen", Vector3(0.6, 0.4, 0.02), Vector3(8.0, 1.3, 3.44), _set_paint(Color(0.5, 1.0, 0.6), null, 1.0, 1.6))


func _canteen_lights(room: Node3D) -> void:
	_lamp(room, "CanteenLight", Vector3(-6.0, 4.5, -2.0), Color(1.0, 0.8, 0.55), 2.6, 10.0)
	_lamp(room, "CanneryLight", Vector3(5.0, 5.0, -3.0), Color(0.6, 0.95, 0.95), 2.6, 11.0)
	_lamp(room, "WindowGlow", Vector3(0.0, 3.0, -6.5), Color(0.35, 1.0, 0.85), 2.0, 9.0, false)
	_lamp(room, "TableGlow", Vector3(-5.5, 3.0, 4.0), Color(1.0, 0.55, 0.75), 1.4, 8.0, false)
	_lamp(room, "AirlockGlow", Vector3(8.0, 2.5, 5.5), Color(0.5, 0.95, 1.0), 1.4, 6.0, false)
	for i in 3:
		_box(room, "CeilingStrip", Vector3(0.4, 0.08, 14.0), Vector3(-6.0 + i * 6.0, 5.95, 0.0), _set_paint(Color(0.8, 1.0, 0.95), null, 1.0, 1.2))
