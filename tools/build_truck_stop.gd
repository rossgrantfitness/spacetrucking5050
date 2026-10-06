extends "res://tools/build_hub.gd"
## Builds the truck stop's inside and the people who work and hang out there:
##     res://scenes/hub/sets/TruckStopSet.tscn   - the concourse: walls,
##                                                 counters, signs, lights
##     res://scenes/hub/BeaverVisual.tscn        - Dusty, the mechanic
##     res://scenes/hub/FrogVisual.tscn          - Lily, at the pumps
##     res://scenes/hub/WalrusVisual.tscn        - Big Wendell, a trucker
##     res://scenes/hub/HamsterVisual.tscn       - Pip, a courier
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_truck_stop.gd
##
## Careful: running it again OVERWRITES those scenes. The room itself
## (res://scenes/hub/TruckStop.tscn, with its cameras, doors, people and
## things to use) is NOT touched.
##
## The critters share the bunny's build and animation (see build_hub.gd),
## plus one feature each that's theirs alone, per CHARACTER_BIBLE.md.

const SPACE_VIEW_BIG := preload("res://textures/generated/space_view.png")


func _initialize() -> void:
	_animator_script = load(ANIMATOR_PATH)
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/hub/sets"))
	_save(_beaver(), "res://scenes/hub/BeaverVisual.tscn")
	_save(_frog(), "res://scenes/hub/FrogVisual.tscn")
	_save(_walrus(), "res://scenes/hub/WalrusVisual.tscn")
	_save(_hamster(), "res://scenes/hub/HamsterVisual.tscn")
	_save(_build_truck_stop(), "res://scenes/hub/sets/TruckStopSet.tscn")
	quit()


# --- The people ------------------------------------------------------------------------

func _look(fur: Color, belly: Color, jacket: Color, pants: Color, cap: Color, ears: String, tail: String) -> Dictionary:
	return {
		"fur": fur, "belly": belly, "inner_ear": fur.darkened(0.3), "jacket": jacket,
		"shirt": Color(0.95, 0.93, 0.88), "pants": pants, "boots": Color(0.2, 0.17, 0.15),
		"cap": cap, "cap_front": Color(0.96, 0.95, 0.9), "ears": ears, "cap_on": cap.a > 0.0,
		"wheat": false, "mask": false, "tail": tail,
	}


func _head(critter: Node3D) -> Node3D:
	return critter.get_node("Body/Head") as Node3D


func _remove(critter: Node3D, paths: Array[String]) -> void:
	for path in paths:
		var node := critter.get_node_or_null(path)
		if node != null:
			node.free()


func _beaver() -> Node3D:
	var critter := _build_critter("BeaverVisual", _look(Color(0.58, 0.38, 0.24), Color(0.8, 0.62, 0.45), Color(1.0, 0.55, 0.15), Color(0.95, 0.5, 0.15), Color(0.3, 0.35, 0.45), "round", "puff"))
	var head := _head(critter)
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic", "Body/Tail"])
	for side: float in [-1.0, 1.0]:
		_box(head, "Tooth", Vector3(0.03, 0.05, 0.015), Vector3(0.017 * side, 0.06, -0.22), _paint(Color(1.0, 0.98, 0.9), null))
	var tail := _box(critter.get_node("Body") as Node3D, "PaddleTail", Vector3(0.24, 0.04, 0.4), Vector3(0.0, -0.22, 0.28), _paint(Color(0.3, 0.2, 0.15), null))
	tail.rotation = Vector3(-0.25, 0.0, 0.0)
	_box(critter.get_node("Body") as Node3D, "Wrench", Vector3(0.04, 0.2, 0.04), Vector3(0.2, -0.05, -0.08), _paint(Color(0.75, 0.78, 0.82), null))
	return critter


## Lily: a frog in a pink pump-attendant visor. Hook: big eye domes on top
## of a wide head.
func _frog() -> Node3D:
	var green := Color(0.45, 0.78, 0.4)
	var critter := _build_critter("FrogVisual", _look(green, Color(0.92, 0.95, 0.7), Color(0.95, 0.3, 0.5), Color(0.35, 0.35, 0.55), Color(0, 0, 0, 0), "round", "puff"))
	var head := _head(critter)
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic", "Body/Head/EarLeft", "Body/Head/EarRight", "Body/Head/Snout", "Body/Head/Nose", "Body/Tail"])
	head.scale = Vector3(1.2, 0.85, 1.0)
	for side: float in [-1.0, 1.0]:
		_box(head, "EyeDome", Vector3(0.14, 0.12, 0.14), Vector3(0.12 * side, 0.4, -0.05), _paint(green, FUZZ, Vector2(8, 8)))
		_box(head, "EyeWhite", Vector3(0.1, 0.09, 0.02), Vector3(0.12 * side, 0.41, -0.125), _paint(Color(0.98, 0.98, 0.92), null))
		_box(head, "Pupil", Vector3(0.05, 0.06, 0.02), Vector3(0.12 * side, 0.41, -0.135), _paint(Color(0.06, 0.05, 0.08), null))
	_box(head, "Smile", Vector3(0.24, 0.015, 0.02), Vector3(0.0, 0.1, -0.18), _paint(Color(0.2, 0.3, 0.15), null))
	_box(head, "Visor", Vector3(0.4, 0.03, 0.18), Vector3(0.0, 0.33, -0.15), _paint(Color(0.95, 0.3, 0.5), null))
	return critter


## Big Wendell: a walrus trucker in a red cap. Hook: tusks and a huge
## mustache.
func _walrus() -> Node3D:
	var critter := _build_critter("WalrusVisual", _look(Color(0.55, 0.4, 0.36), Color(0.7, 0.55, 0.5), Color(0.25, 0.35, 0.6), Color(0.3, 0.3, 0.32), Color(0.85, 0.25, 0.2), "round", "puff"))
	var head := _head(critter)
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic", "Body/Head/EarLeft", "Body/Head/EarRight", "Body/Tail"])
	_box(head, "Mustache", Vector3(0.3, 0.1, 0.08), Vector3(0.0, 0.1, -0.22), _paint(Color(0.85, 0.75, 0.65), FUZZ, Vector2(8, 8)))
	for side: float in [-1.0, 1.0]:
		var tusk := _box(head, "Tusk", Vector3(0.03, 0.18, 0.03), Vector3(0.06 * side, -0.02, -0.23), _paint(Color(1.0, 0.97, 0.88), null))
		tusk.rotation = Vector3(0.15, 0.0, 0.1 * side)
	(critter.get_node("Body") as Node3D).scale = Vector3(1.25, 1.1, 1.2)
	return critter


## Pip: a hamster courier in a red jacket. Hook: stuffed cheek pouches.
func _hamster() -> Node3D:
	var critter := _build_critter("HamsterVisual", _look(Color(0.98, 0.78, 0.5), Color(1.0, 0.95, 0.88), Color(0.9, 0.25, 0.25), Color(0.25, 0.3, 0.45), Color(0, 0, 0, 0), "round", "puff"))
	var head := _head(critter)
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic"])
	for side: float in [-1.0, 1.0]:
		_box(head, "Cheek", Vector3(0.14, 0.13, 0.16), Vector3(0.19 * side, 0.11, -0.08), _paint(Color(1.0, 0.92, 0.82), FUZZ, Vector2(8, 8)))
	_box(head, "Goggles", Vector3(0.36, 0.06, 0.03), Vector3(0.0, 0.35, -0.15), _paint(Color(0.3, 0.8, 1.0), null))
	return critter


# --- The truck stop concourse ---------------------------------------------------------------
# 40 x 30 m and 10 m tall: big, glowing and a bit empty on purpose, with room
# to grow. Back (-Z) is a huge window onto space; front (+Z) has shuttered
# shopfronts that open up in later updates. The airlock to your rig is on
# the right (+X) wall.
#
#   back-left: MARGE'S DINER (counter, stools, booths, jukebox)
#   back-middle: the JOB BOARD under the big window
#   back-right: DUSTY'S GARAGE (repairs and upgrades)
#   middle: LILY'S PUMPS kiosk (fuel and boost fuel), pillars, benches
#   front-left: the arcade lounge; front: shuttered shops

func _build_truck_stop() -> Node3D:
	var parts := _new_set("TruckStopSet")
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var size := Vector3(40.0, 10.0, 30.0)
	var wall := _set_paint(Color(0.32, 0.36, 0.55), WALL_PANELS, 3.0)
	var dark := _set_paint(Color(0.14, 0.14, 0.2))
	var metal := _set_paint(Color(0.55, 0.58, 0.66))
	_room_shell(room, body, size, _set_paint(Color(0.85, 0.85, 0.95), FLOOR_TILES, 2.0), wall, _set_paint(Color(0.12, 0.12, 0.18)))
	_cut_big_window(room, body, wall)
	_atrium(room, body, dark, metal)
	_diner(room, body, dark, metal)
	_job_board(room, body, dark)
	_garage(room, body, dark, metal)
	_pumps(room, body, dark, metal)
	_arcade(room, body, dark)
	_shopfronts(room, body, dark)
	_airlock(room, body, dark)
	_lights(room)
	return room


## The back wall becomes a huge window onto the asteroid field and the
## ringed planet.
func _cut_big_window(room: Node3D, body: StaticBody3D, wall: Material) -> void:
	room.get_node("WallBack").free()
	body.get_node("WallBackShape").free()
	_piece(room, body, "WallBackLeft", Vector3(12.0, 10.0, 0.2), Vector3(-14.0, 5.0, -15.1), wall)
	_piece(room, body, "WallBackRight", Vector3(12.0, 10.0, 0.2), Vector3(14.0, 5.0, -15.1), wall)
	_piece(room, body, "WallBackLow", Vector3(16.0, 1.2, 0.2), Vector3(0.0, 0.6, -15.1), wall)
	_piece(room, body, "WallBackHigh", Vector3(16.0, 1.6, 0.2), Vector3(0.0, 9.2, -15.1), wall)
	_space_picture(room, "SpaceView", Vector2(16.0, 7.2), Vector3(0.0, 4.8, -15.3), 0.0)
	var frame := _set_paint(Color(0.2, 0.2, 0.26))
	for x: float in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		_box(room, "WindowMullion", Vector3(0.25, 7.2, 0.3), Vector3(x, 4.8, -15.0), frame)
	_box(room, "WindowSill", Vector3(16.4, 0.2, 0.6), Vector3(0.0, 1.2, -14.8), frame)
	_box(room, "WindowNeon", Vector3(16.0, 0.08, 0.08), Vector3(0.0, 8.4, -14.9), _set_paint(Color(0.4, 0.9, 1.0), null, 1.0, 2.0))


## The middle: pillars with neon bands, benches, plants, painted walkway
## lines from the airlock, and a big hanging sign.
func _atrium(room: Node3D, body: StaticBody3D, dark: Material, metal: Material) -> void:
	var neon: Array[Color] = [Color(1.0, 0.4, 0.8), Color(0.4, 0.95, 1.0), Color(0.5, 1.0, 0.5), Color(1.0, 0.75, 0.3)]
	var pillars: Array[Vector3] = [Vector3(-7.0, 0.0, -4.0), Vector3(7.0, 0.0, -4.0), Vector3(-7.0, 0.0, 7.0), Vector3(7.0, 0.0, 7.0)]
	for i in pillars.size():
		var spot := pillars[i]
		_piece(room, body, "Pillar", Vector3(1.0, 10.0, 1.0), spot + Vector3(0.0, 5.0, 0.0), metal)
		for band_y: float in [2.6, 6.5]:
			_box(room, "PillarNeon", Vector3(1.08, 0.12, 1.08), spot + Vector3(0.0, band_y, 0.0), _set_paint(neon[i], null, 1.0, 2.2))
	# Hanging sign in the middle of the ceiling.
	_box(room, "HangingSignBack", Vector3(9.0, 2.0, 0.3), Vector3(0.0, 8.0, 1.5), dark)
	_beam(room, "SignCable", Vector3(-4.0, 9.0, 1.5), Vector3(-4.0, 10.0, 1.5), 0.04, metal)
	_beam(room, "SignCable", Vector3(4.0, 9.0, 1.5), Vector3(4.0, 10.0, 1.5), 0.04, metal)
	_sign(room, "HangingSign", "TRUCK STOP", 0.012, Color(1.0, 0.45, 0.8), Vector3(0.0, 8.15, 1.68))
	_sign(room, "HangingSignSub", "OPEN 24/7 · FUEL · FOOD · NAPS", 0.004, Color(0.45, 0.95, 1.0), Vector3(0.0, 7.35, 1.68))
	# Benches and plants around the atrium.
	for bench: Vector3 in [Vector3(-3.0, 0.0, 9.5), Vector3(3.0, 0.0, -6.0), Vector3(-3.5, 0.0, -6.0)]:
		_piece(room, body, "Bench", Vector3(2.4, 0.45, 0.6), bench + Vector3(0.0, 0.23, 0.0), _set_paint(Color(0.3, 0.6, 0.62)))
	for plant: Vector3 in [Vector3(-7.0, 0.0, 1.5), Vector3(7.0, 0.0, 1.5), Vector3(-9.0, 0.0, -13.5), Vector3(9.0, 0.0, -13.5)]:
		_piece(room, body, "PlantPot", Vector3(0.7, 0.7, 0.7), plant + Vector3(0.0, 0.35, 0.0), _set_paint(Color(0.75, 0.4, 0.3)))
		for leaf_i in 6:
			var leaf := _box(room, "Leaf", Vector3(0.14, 1.2, 0.35), plant + Vector3(0.0, 1.2, 0.0), _set_paint(Color(0.35, 0.72, 0.4)))
			leaf.rotation = Vector3(0.45, leaf_i * 1.05, 0.0)
	# Painted walkway lines from the airlock, and floor chevrons.
	for i in 14:
		_box(room, "LaneDash", Vector3(1.0, 0.02, 0.15), Vector3(18.5 - i * 1.6, 0.01, 8.0), _set_paint(Color(1.0, 0.8, 0.2)))
		_box(room, "LaneDash", Vector3(1.0, 0.02, 0.15), Vector3(18.5 - i * 1.6, 0.01, 10.0), _set_paint(Color(1.0, 0.8, 0.2)))


## Marge's diner: a long counter with stools, a raised floor behind it so
## she can see over, booths along the wall, a pie case and a jukebox.
func _diner(room: Node3D, body: StaticBody3D, dark: Material, metal: Material) -> void:
	_box(room, "DinerFloor", Vector3(11.8, 0.02, 15.0), Vector3(-14.0, 0.011, -7.5), _set_paint(Color(1.0, 1.0, 1.0), CARPET, 0.8))
	_piece(room, body, "DinerCounter", Vector3(10.0, 1.0, 0.9), Vector3(-13.5, 0.5, -9.5), _set_paint(Color(0.95, 0.45, 0.4)))
	_box(room, "DinerCounterTop", Vector3(10.2, 0.08, 1.1), Vector3(-13.5, 1.04, -9.5), _set_paint(Color(0.9, 0.9, 0.85)))
	_box(room, "DinerCounterChrome", Vector3(10.02, 0.1, 0.02), Vector3(-13.5, 0.75, -9.04), metal)
	_piece(room, body, "DinerPlatform", Vector3(10.0, 0.45, 4.6), Vector3(-13.5, 0.225, -12.3), _set_paint(Color(0.32, 0.32, 0.4)))
	for i in 6:
		var x := -17.5 + i * 1.6
		_cylinder(room, "StoolSeat", 0.3, 0.12, Vector3(x, 0.75, -8.4), _set_paint(Color(0.95, 0.35, 0.45)), Vector3.ZERO, 10)
		_cylinder(room, "StoolPost", 0.06, 0.7, Vector3(x, 0.35, -8.4), metal, Vector3.ZERO, 6)
	# Behind the counter: pie case, coffee machine, menu boards, the kitchen pass.
	_box(room, "PieCase", Vector3(1.4, 0.6, 0.7), Vector3(-10.0, 1.4, -9.6), _set_paint(Color(0.7, 0.9, 1.0), null, 1.0, 0.4))
	for i in 3:
		_cylinder(room, "Pie", 0.18, 0.08, Vector3(-10.4 + i * 0.4, 1.25, -9.6), _set_paint(Color(0.85, 0.45, 0.9)), Vector3.ZERO, 10)
	_box(room, "CoffeeMachine", Vector3(0.7, 0.8, 0.5), Vector3(-17.5, 1.45, -9.7), _set_paint(Color(0.85, 0.2, 0.25)))
	_cylinder(room, "CoffeePot", 0.12, 0.25, Vector3(-16.7, 1.2, -9.5), _set_paint(Color(0.4, 0.25, 0.15)), Vector3.ZERO, 8)
	for i in 3:
		_box(room, "MenuBoard", Vector3(2.4, 1.3, 0.05), Vector3(-17.5 + i * 3.2, 4.0, -14.95), _set_paint(Color.WHITE, JOB_BOARD, 2.4, 0.5))
	_box(room, "KitchenPass", Vector3(4.0, 1.0, 0.1), Vector3(-13.5, 2.3, -14.95), _set_paint(Color(1.0, 0.75, 0.45), null, 1.0, 1.2))
	_box(room, "DinerSignBack", Vector3(7.0, 1.4, 0.1), Vector3(-13.5, 6.4, -14.92), dark)
	_sign(room, "DinerSign", "MARGE'S DINER", 0.008, Color(1.0, 0.75, 0.3), Vector3(-13.5, 6.55, -14.85))
	_sign(room, "DinerSignSub", "HOME OF THE NEBULA PIE", 0.003, Color(1.0, 0.45, 0.8), Vector3(-13.5, 5.95, -14.85))
	# Booths along the left wall: a table between two benches each.
	for z: float in [-5.0, -1.5, 2.0]:
		_piece(room, body, "BoothTable", Vector3(1.4, 0.75, 0.9), Vector3(-19.0, 0.38, z), _set_paint(Color(0.9, 0.9, 0.85)))
		for side: float in [-1.0, 1.0]:
			_piece(room, body, "BoothSeat", Vector3(1.4, 0.45, 0.55), Vector3(-19.0, 0.23, z + side * 0.85), _set_paint(Color(0.9, 0.3, 0.4)))
			_box(room, "BoothBack", Vector3(1.4, 0.9, 0.15), Vector3(-19.0, 0.9, z + side * 1.1), _set_paint(Color(0.9, 0.3, 0.4)))
		_cylinder(room, "BoothLamp", 0.25, 0.2, Vector3(-19.0, 2.6, z), _set_paint(Color(1.0, 0.8, 0.5), null, 1.0, 1.4), Vector3.ZERO, 8)
	# The jukebox: a glowing rainbow arch.
	_piece(room, body, "Jukebox", Vector3(0.7, 1.6, 1.2), Vector3(-19.5, 0.8, 5.5), _set_paint(Color(0.55, 0.3, 0.2), WOOD, 0.8))
	_box(room, "JukeboxGlow", Vector3(0.05, 1.0, 0.9), Vector3(-19.13, 1.0, 5.5), _set_paint(Color(1.0, 0.55, 0.85), null, 1.0, 2.2))
	_box(room, "JukeboxTop", Vector3(0.75, 0.2, 1.25), Vector3(-19.5, 1.7, 5.5), _set_paint(Color(0.4, 0.95, 1.0), null, 1.0, 2.0))


## The job board, standing in front of the big window like a departures board.
func _job_board(room: Node3D, body: StaticBody3D, dark: Material) -> void:
	_piece(room, body, "JobBoardStand", Vector3(5.0, 0.4, 0.8), Vector3(0.0, 0.2, -11.0), dark)
	_box(room, "JobBoardFrame", Vector3(5.2, 3.0, 0.25), Vector3(0.0, 2.3, -11.0), dark)
	_box(room, "JobBoard", Vector3(4.8, 2.6, 0.05), Vector3(0.0, 2.3, -10.85), _set_paint(Color.WHITE, JOB_BOARD, 4.8, 0.35))
	for leg: float in [-2.2, 2.2]:
		_box(room, "JobBoardLeg", Vector3(0.2, 1.0, 0.2), Vector3(leg, 0.7, -11.0), dark)
	_sign(room, "JobBoardSign", "JOB BOARD", 0.006, Color(0.45, 0.95, 1.0), Vector3(0.0, 4.25, -10.8))


## Dusty's garage: a big roll-up door, a lift with an engine on it, a
## pegboard of tools, drums, tires and a workbench, on a striped floor.
func _garage(room: Node3D, body: StaticBody3D, dark: Material, metal: Material) -> void:
	_box(room, "GarageFloor", Vector3(12.0, 0.02, 12.0), Vector3(14.0, 0.011, -9.0), _set_paint(Color(0.55, 0.55, 0.58)))
	_box(room, "GarageEdge", Vector3(12.0, 0.03, 0.3), Vector3(14.0, 0.02, -3.0), _hazard(2.0))
	_box(room, "GarageEdgeSide", Vector3(0.3, 0.03, 12.0), Vector3(8.0, 0.02, -9.0), _hazard(2.0))
	_box(room, "GarageDoor", Vector3(7.0, 5.0, 0.15), Vector3(15.0, 2.5, -14.92), _set_paint(Color(0.6, 0.62, 0.7), WALL_PANELS, 1.0))
	_box(room, "GarageDoorStripe", Vector3(7.0, 0.4, 0.02), Vector3(15.0, 4.8, -14.82), _hazard(2.0))
	_box(room, "GarageSignBack", Vector3(7.4, 1.2, 0.1), Vector3(15.0, 6.6, -14.92), dark)
	_sign(room, "GarageSign", "DUSTY'S GARAGE", 0.007, Color(1.0, 0.6, 0.2), Vector3(15.0, 6.75, -14.85))
	_sign(room, "GarageSignSub", "REPAIRS · UPGRADES · NO QUESTIONS", 0.0028, Color(0.5, 1.0, 0.5), Vector3(15.0, 6.2, -14.85))
	# The lift, with somebody's engine on it.
	_piece(room, body, "Lift", Vector3(4.0, 0.3, 5.0), Vector3(15.0, 0.15, -9.5), _hazard(1.0))
	for post: Vector3 in [Vector3(12.8, 1.5, -12.0), Vector3(17.2, 1.5, -12.0)]:
		_piece(room, body, "LiftPost", Vector3(0.3, 3.0, 0.3), post, _set_paint(Color(1.0, 0.8, 0.2)))
	_cylinder(room, "SpareEngine", 0.9, 2.2, Vector3(15.0, 1.3, -9.5), metal, ALONG_Z, 10)
	_cylinder(room, "SpareEngineGlow", 0.65, 0.1, Vector3(15.0, 1.3, -8.35), _set_paint(Color(1.0, 0.5, 0.2), null, 1.0, 1.5), ALONG_Z, 10)
	# Tools on the wall, a bench, drums and tires.
	_box(room, "Pegboard", Vector3(0.05, 2.5, 5.0), Vector3(19.9, 2.5, -9.0), _set_paint(Color(0.75, 0.6, 0.4), WOOD, 1.0))
	for i in 7:
		var tool := _box(room, "Tool", Vector3(0.04, 0.5, 0.1), Vector3(19.85, 2.2 + (i % 2) * 0.7, -11.0 + i * 0.6), metal)
		tool.rotation = Vector3(0.3 * (i % 3 - 1), 0.0, 0.0)
	_piece(room, body, "Workbench", Vector3(1.0, 0.95, 3.5), Vector3(19.4, 0.48, -5.5), _set_paint(Color(1.0, 1.0, 1.0), WOOD, 1.0))
	for drum: Vector3 in [Vector3(9.3, 0.0, -14.2), Vector3(10.2, 0.0, -14.3), Vector3(9.7, 0.0, -13.4)]:
		var drum_color := Color(0.25, 0.5, 0.9) if drum.x > 10.0 else Color(0.9, 0.3, 0.25)
		_piece(room, body, "Drum", Vector3(0.7, 1.0, 0.7), drum + Vector3(0.0, 0.5, 0.0), _set_paint(drum_color))
	for i in 3:
		_cylinder(room, "Tire", 0.55, 0.35, Vector3(19.2, 0.18 + i * 0.36, -13.8), _set_paint(Color(0.12, 0.12, 0.14)), Vector3.ZERO, 12)


## Lily's pumps: a kiosk counter with a raised floor behind it, a menu
## board, and two big retro fuel pumps.
func _pumps(room: Node3D, body: StaticBody3D, _dark: Material, _metal: Material) -> void:
	_piece(room, body, "PumpCounter", Vector3(4.0, 1.0, 0.8), Vector3(10.0, 0.5, 3.5), _set_paint(Color(0.3, 0.75, 0.55)))
	_box(room, "PumpCounterTop", Vector3(4.2, 0.08, 1.0), Vector3(10.0, 1.04, 3.5), _set_paint(Color(0.9, 0.9, 0.85)))
	_piece(room, body, "PumpPlatform", Vector3(4.0, 0.3, 2.0), Vector3(10.0, 0.15, 2.0), _set_paint(Color(0.32, 0.32, 0.4)))
	_piece(room, body, "PumpBackPanel", Vector3(4.6, 3.6, 0.3), Vector3(10.0, 1.8, 0.8), _set_paint(Color(0.8, 0.82, 0.9), MACHINERY, 1.8))
	_sign(room, "PumpSign", "LILY'S PUMPS", 0.006, Color(0.5, 1.0, 0.5), Vector3(10.0, 3.1, 0.98))
	_sign(room, "PumpSignSub", "FUEL · BOOST · SNACKS", 0.003, Color(1.0, 0.8, 0.3), Vector3(10.0, 2.5, 0.98))
	_box(room, "CashRegister", Vector3(0.5, 0.35, 0.4), Vector3(11.2, 1.25, 3.4), _set_paint(Color(0.85, 0.82, 0.74)))
	for x: float in [7.0, 13.0]:
		_piece(room, body, "FuelPump", Vector3(0.9, 2.0, 0.7), Vector3(x, 1.0, 3.6), _set_paint(Color(0.95, 0.3, 0.3)))
		_box(room, "FuelPumpScreen", Vector3(0.6, 0.4, 0.02), Vector3(x, 1.5, 3.96), _set_paint(Color(0.5, 1.0, 0.6), null, 1.0, 1.6))
		_box(room, "FuelPumpTop", Vector3(0.95, 0.3, 0.75), Vector3(x, 2.15, 3.6), _set_paint(Color(1.0, 0.95, 0.85), null, 1.0, 0.8))


## The arcade lounge: cabinets glowing against the front wall, a couch, a
## vending machine and the restroom door.
func _arcade(room: Node3D, body: StaticBody3D, _dark: Material) -> void:
	_box(room, "ArcadeCarpet", Vector3(10.0, 0.02, 7.0), Vector3(-15.0, 0.012, 11.4), _set_paint(Color(0.6, 0.3, 0.9), CARPET, 0.7))
	var screens: Array[Color] = [Color(0.4, 0.95, 1.0), Color(1.0, 0.45, 0.8), Color(0.5, 1.0, 0.5)]
	for i in 3:
		var x := -18.0 + i * 1.6
		_piece(room, body, "ArcadeCabinet", Vector3(1.1, 2.0, 0.9), Vector3(x, 1.0, 14.4), _set_paint(Color(0.15, 0.12, 0.3)))
		var screen := _box(room, "ArcadeScreen", Vector3(0.8, 0.6, 0.02), Vector3(x, 1.4, 13.93), _set_paint(screens[i], null, 1.0, 2.0))
		screen.rotation = Vector3(0.0, PI, 0.0)
		_box(room, "ArcadeMarquee", Vector3(1.1, 0.3, 0.05), Vector3(x, 2.1, 13.94), _set_paint(screens[(i + 1) % 3], null, 1.0, 2.2))
	_sign(room, "ArcadeSign", "ARCADE", 0.008, Color(0.4, 0.95, 1.0), Vector3(-16.5, 4.0, 14.85))
	(room.get_node("ArcadeSign") as Node3D).rotation = Vector3(0.0, PI, 0.0)
	_piece(room, body, "Couch", Vector3(3.0, 0.5, 1.0), Vector3(-15.5, 0.25, 9.0), _set_paint(Color(0.9, 0.6, 0.3)))
	_box(room, "CouchBack", Vector3(3.0, 0.7, 0.25), Vector3(-15.5, 0.75, 8.55), _set_paint(Color(0.9, 0.6, 0.3)))
	_piece(room, body, "VendingMachine", Vector3(1.1, 2.1, 0.9), Vector3(-11.5, 1.05, 14.4), _set_paint(Color(0.2, 0.75, 0.4)))
	var vending_front := _box(room, "VendingFront", Vector3(0.8, 1.4, 0.02), Vector3(-11.5, 1.2, 13.93), _set_paint(Color(0.7, 1.0, 0.5), null, 1.0, 1.6))
	vending_front.rotation = Vector3(0.0, PI, 0.0)
	_door_panel(room, "RestroomDoor", Vector3(-19.97, 1.1, 12.0), PI / 2.0)
	_sign(room, "RestroomSign", "RESTROOMS · SHOWERS", 0.003, Color(1.0, 1.0, 1.0), Vector3(-19.85, 2.6, 12.0))
	(room.get_node("RestroomSign") as Node3D).rotation = Vector3(0.0, PI / 2.0, 0.0)


## Shopfronts along the front wall: places that open in later updates
## (outfits, decor) behind shutters, the OrbitalEx office (open: the boss's
## desk is in the room scene), plus the motel by the airlock.
func _shopfronts(room: Node3D, _body: StaticBody3D, dark: Material) -> void:
	var shops := [["OUTFITTERS", -3.0, Color(1.0, 0.45, 0.8), false], ["HOME & DECOR", 4.5, Color(1.0, 0.8, 0.3), false],
			["ORBITALEX OFFICE", 12.0, Color(0.45, 0.95, 1.0), true]]
	for shop: Array in shops:
		var x: float = shop[1]
		var open: bool = shop[3]
		_box(room, "ShopFrame", Vector3(6.0, 4.4, 0.3), Vector3(x, 2.2, 14.85), dark)
		if not open:
			_box(room, "Shutter", Vector3(5.2, 3.4, 0.05), Vector3(x, 1.7, 14.68), _set_paint(Color(0.7, 0.72, 0.78), WALL_PANELS, 0.6))
		_sign(room, "ShopSign", shop[0], 0.006, shop[2], Vector3(x, 3.85, 14.6))
		if open:
			# Glass doors in (see OrbitalExOffice.tscn), lit from inside.
			_box(room, "ShopWindow", Vector3(5.2, 3.0, 0.05), Vector3(x, 1.6, 14.68), _set_paint(shop[2], null, 1.0, 0.5))
			for side: float in [-1.0, 1.0]:
				_box(room, "ShopDoor", Vector3(1.1, 2.4, 0.06), Vector3(x + 0.58 * side, 1.2, 14.64), _set_paint(Color(0.75, 0.95, 1.0), null, 1.0, 0.9))
			_box(room, "ShopMat", Vector3(2.6, 0.02, 1.2), Vector3(x, 0.012, 13.9), _set_paint(Color(0.85, 0.15, 0.2), CARPET, 0.8))
		if not open:
			_sign(room, "ComingSoon", "COMING SOON", 0.0035, Color(1.0, 0.85, 0.25), Vector3(x, 1.9, 14.6))
	for label in room.get_children():
		if label is Label3D and (label.name.begins_with("ShopSign") or label.name.begins_with("ComingSoon")):
			(label as Node3D).rotation = Vector3(0.0, PI, 0.0)
	# The motel, on the right wall by the airlock.
	_box(room, "MotelFrame", Vector3(0.3, 4.0, 5.0), Vector3(19.85, 2.0, 1.0), dark)
	_box(room, "MotelShutter", Vector3(0.05, 3.0, 4.2), Vector3(19.68, 1.5, 1.0), _set_paint(Color(0.7, 0.72, 0.78), WALL_PANELS, 0.6))
	_sign(room, "MotelSign", "NAP MOTEL · COMING SOON", 0.0045, Color(1.0, 0.45, 0.8), Vector3(19.6, 3.5, 1.0))
	(room.get_node("MotelSign") as Node3D).rotation = Vector3(0.0, -PI / 2.0, 0.0)


## The airlock to your rig, on the right wall, with a little window onto the
## docking bay.
func _airlock(room: Node3D, _body: StaticBody3D, dark: Material) -> void:
	_box(room, "AirlockFrame", Vector3(0.3, 3.6, 3.0), Vector3(19.85, 1.8, 9.0), dark)
	_box(room, "AirlockDoor", Vector3(0.06, 2.8, 2.0), Vector3(19.7, 1.4, 9.0), _set_paint(Color(0.85, 0.85, 0.9), DOOR, 2.8))
	_box(room, "AirlockStripes", Vector3(0.04, 0.3, 3.0), Vector3(19.66, 3.2, 9.0), _hazard(2.0))
	_box(room, "AirlockLight", Vector3(0.1, 0.25, 0.6), Vector3(19.7, 3.5, 9.0), _set_paint(Color(0.4, 1.0, 0.5), null, 1.0, 2.5))
	_sign(room, "AirlockSign", "DOCK 3 · YOUR RIG", 0.0045, Color(0.45, 0.95, 1.0), Vector3(19.6, 4.2, 9.0))
	(room.get_node("AirlockSign") as Node3D).rotation = Vector3(0.0, -PI / 2.0, 0.0)
	_space_picture(room, "Porthole", Vector2(1.6, 1.6), Vector3(19.9, 2.2, 13.0), -PI / 2.0)
	_box(room, "PortholeFrame", Vector3(0.1, 1.9, 0.15), Vector3(19.8, 2.2, 12.2), dark)
	_box(room, "PortholeFrame", Vector3(0.1, 1.9, 0.15), Vector3(19.8, 2.2, 13.8), dark)


## Warm light over the diner, cool over the garage, colored pools in the
## middle, and glowing strips along the ceiling.
func _lights(room: Node3D) -> void:
	_lamp(room, "DinerLight", Vector3(-13.5, 4.5, -8.0), Color(1.0, 0.75, 0.5), 3.0, 12.0)
	_lamp(room, "BoothLight", Vector3(-17.5, 3.0, -1.5), Color(1.0, 0.7, 0.5), 1.6, 7.0, false)
	_lamp(room, "GarageLight", Vector3(14.0, 6.0, -8.0), Color(0.7, 0.85, 1.0), 2.8, 13.0)
	_lamp(room, "PumpsLight", Vector3(10.0, 4.0, 5.5), Color(0.6, 1.0, 0.7), 1.8, 9.0, false)
	_lamp(room, "AtriumPink", Vector3(-4.0, 6.5, 2.0), Color(1.0, 0.45, 0.8), 2.0, 14.0, false)
	_lamp(room, "AtriumCyan", Vector3(4.0, 6.5, 2.0), Color(0.45, 0.9, 1.0), 2.0, 14.0, false)
	_lamp(room, "WindowLight", Vector3(0.0, 4.0, -12.5), Color(0.55, 0.6, 1.0), 2.2, 11.0)
	_lamp(room, "ArcadeLight", Vector3(-15.0, 3.0, 11.5), Color(0.7, 0.4, 1.0), 2.0, 9.0, false)
	_lamp(room, "AirlockGlow", Vector3(17.5, 3.0, 9.0), Color(0.5, 0.95, 1.0), 1.5, 7.0, false)
	_lamp(room, "ShopsFill", Vector3(5.0, 5.0, 12.0), Color(1.0, 0.8, 0.6), 1.4, 12.0, false)
	for i in 5:
		_box(room, "CeilingStrip", Vector3(0.5, 0.08, 26.0), Vector3(-16.0 + i * 8.0, 9.95, 0.0), _set_paint(Color(0.85, 0.9, 1.0), null, 1.0, 1.3))


## A flat picture of space for a window, shown as-is (no lighting): it's
## what's outside. Faces +Z, turned by `facing_y`.
func _space_picture(parent: Node3D, node_name: String, size: Vector2, where: Vector3, facing_y: float) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = SPACE_VIEW_BIG
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	quad.material = material
	var picture := _mesh(parent, node_name, quad, where, Vector3(0.0, facing_y, 0.0))
	picture.name = node_name
