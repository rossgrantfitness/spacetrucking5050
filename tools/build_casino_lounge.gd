extends "res://tools/build_truck_stop.gd"
## Builds the inside of The High Roller (where you climb out after docking
## at Sal's casino in the Glimmer System) and Sal, who owns it:
##     res://scenes/hub/sets/HighRollerLoungeSet.tscn  - the casino floor:
##                                                      Sal's cashier cage,
##                                                      slot machines, a
##                                                      roulette table, card
##                                                      tables, a little
##                                                      lounge stage, and a
##                                                      big window onto the
##                                                      magenta planet
##     res://scenes/hub/CrocodileVisual.tscn           - Sal
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_casino_lounge.gd
##
## Careful: running it again OVERWRITES those scenes. The room itself
## (res://scenes/hub/HighRollerLounge.tscn, with its cameras, doors, people
## and things to use) is NOT touched. It borrows everything from
## build_truck_stop.gd and build_hub.gd.

const GLIMMER := preload("res://textures/generated/glimmer_planet.png")
const MAGENTA := Color(1.0, 0.3, 0.8)
const GOLD := Color(1.0, 0.8, 0.35)


func _initialize() -> void:
	_animator_script = load(ANIMATOR_PATH)
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_save(_crocodile(), "res://scenes/hub/CrocodileVisual.tscn")
	_save(_build_lounge(), "res://scenes/hub/sets/HighRollerLoungeSet.tscn")
	quit()


## Sal: a crocodile in a white collared shirt and a magenta tie (per
## CHARACTER_BIBLE.md: "huge toothy grin, collared shirt and tie, bulging
## eyes on top of the snout"). Hook: a long jaw full of square teeth.
func _crocodile() -> Node3D:
	var green := Color(0.36, 0.6, 0.32)
	var critter := _build_critter("CrocodileVisual", _look(green, Color(0.9, 0.85, 0.55), Color(0.95, 0.93, 0.9), Color(0.35, 0.15, 0.4), Color(0, 0, 0, 0), "round", "puff"))
	var head := _head(critter)
	var body := critter.get_node("Body") as Node3D
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic", "Body/Head/EarLeft", "Body/Head/EarRight", "Body/Head/Snout", "Body/Head/Nose", "Body/Tail"])
	# His eyes are up on top of the snout, not on his face: drop the face
	# eyes and move the eyelids (they blink) up onto the bulging ones.
	for part in head.get_children():
		if String(part.name).begins_with("Eye") and part.name != "Eyelids":
			part.free()
	(head.get_node("Eyelids") as Node3D).position = Vector3(0.0, 0.44, -0.17)
	var skin := _paint(green, FUZZ, Vector2(8, 8))
	var tooth := _paint(Color(1.0, 0.98, 0.9), null)
	# The long jaw: an upper snout, a lower jaw, and a grin between them.
	_box(head, "UpperJaw", Vector3(0.26, 0.09, 0.3), Vector3(0.0, 0.13, -0.3), skin)
	_box(head, "LowerJaw", Vector3(0.24, 0.05, 0.27), Vector3(0.0, 0.05, -0.28), _paint(Color(0.9, 0.85, 0.55), FUZZ, Vector2(8, 8)))
	_box(head, "Grin", Vector3(0.25, 0.025, 0.28), Vector3(0.0, 0.085, -0.29), _paint(Color(0.5, 0.12, 0.2), null))
	for side: float in [-1.0, 1.0]:
		for i in 5:
			_box(head, "Tooth", Vector3(0.025, 0.03, 0.025), Vector3(0.115 * side, 0.08, -0.19 - i * 0.05), tooth)
		# Bulging eyes on top of the snout.
		_box(head, "EyeBump", Vector3(0.11, 0.09, 0.11), Vector3(0.09 * side, 0.4, -0.1), skin)
		_box(head, "EyeWhite", Vector3(0.08, 0.06, 0.02), Vector3(0.09 * side, 0.41, -0.16), _paint(Color(0.98, 0.95, 0.7), null))
		_box(head, "Pupil", Vector3(0.02, 0.055, 0.02), Vector3(0.09 * side, 0.41, -0.172), _paint(Color(0.06, 0.05, 0.08), null))
		_box(head, "Nostril", Vector3(0.025, 0.02, 0.02), Vector3(0.04 * side, 0.18, -0.44), _paint(Color(0.15, 0.25, 0.12), null))
	for i in 4:
		_box(head, "FrontTooth", Vector3(0.025, 0.03, 0.02), Vector3(-0.045 + i * 0.03, 0.08, -0.44), tooth)
	# Ridges down the back of the head.
	for i in 3:
		_box(head, "Ridge", Vector3(0.05, 0.04, 0.06), Vector3(0.0, 0.39, 0.0 + i * 0.08), _paint(green.darkened(0.25), null))
	# The collar, the tie, and a gold chain.
	for side: float in [-1.0, 1.0]:
		var collar := _box(body, "Collar", Vector3(0.07, 0.04, 0.02), Vector3(0.045 * side, 0.29, -0.115), _paint(Color(1.0, 1.0, 1.0), null))
		collar.rotation = Vector3(0.0, 0.0, -0.5 * side)
	_box(body, "Tie", Vector3(0.05, 0.2, 0.02), Vector3(0.0, 0.17, -0.12), _paint(MAGENTA, null))
	_box(body, "TieKnot", Vector3(0.05, 0.04, 0.025), Vector3(0.0, 0.27, -0.12), _paint(MAGENTA.darkened(0.2), null))
	_box(body, "Chain", Vector3(0.18, 0.015, 0.02), Vector3(0.0, 0.25, -0.125), _paint(GOLD, null))
	# A long tapering tail with ridges.
	for piece in 4:
		_box(body, "Tail", Vector3(0.14 - piece * 0.025, 0.09 - piece * 0.015, 0.18), Vector3(0.0, -0.2 - piece * 0.04, 0.16 + piece * 0.16), skin)
		_box(body, "TailRidge", Vector3(0.03, 0.03, 0.06), Vector3(0.0, -0.14 - piece * 0.045, 0.16 + piece * 0.16), _paint(green.darkened(0.25), null))
	return critter


# --- The casino floor -------------------------------------------------------------------
# 22 x 18 m, 7 m tall. Back (-Z) is a wide window onto the Glimmer System's
# magenta gas giant. Left: Sal's cashier cage (the counter, with a raised
# floor behind it) and the job board. Middle: the roulette table and two
# card tables. Right: rows of slot machines (the one at the front works).
# Front-left: a little lounge stage and the jukebox. The airlock to your rig
# is on the right (+X) wall, near the front.

func _build_lounge() -> Node3D:
	var parts := _new_set("HighRollerLoungeSet")
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var size := Vector3(22.0, 7.0, 18.0)
	var wall := _set_paint(Color(0.32, 0.12, 0.35), WALL_PANELS, 3.0)
	var dark := _set_paint(Color(0.1, 0.05, 0.12))
	var gold := _set_paint(GOLD)
	_room_shell(room, body, size, _set_paint(Color(0.85, 0.35, 0.6), CARPET, 1.2), wall, _set_paint(Color(0.08, 0.04, 0.1)))
	_planet_window(room, body, wall)
	_cashier_cage(room, body, dark, gold)
	_tables(room, body, dark, gold)
	_slots(room, body, dark, gold)
	_stage(room, body, dark, gold)
	_lounge_extras(room, body, dark)
	_lounge_lights(room)
	return room


## The back wall: a long window onto the magenta gas giant.
func _planet_window(room: Node3D, body: StaticBody3D, wall: Material) -> void:
	room.get_node("WallBack").free()
	body.get_node("WallBackShape").free()
	_piece(room, body, "WallBackLeft", Vector3(4.0, 7.0, 0.2), Vector3(-9.0, 3.5, -9.1), wall)
	_piece(room, body, "WallBackRight", Vector3(4.0, 7.0, 0.2), Vector3(9.0, 3.5, -9.1), wall)
	_piece(room, body, "WallBackLow", Vector3(14.0, 1.2, 0.2), Vector3(0.0, 0.6, -9.1), wall)
	_piece(room, body, "WallBackHigh", Vector3(14.0, 1.3, 0.2), Vector3(0.0, 6.35, -9.1), wall)
	var quad := QuadMesh.new()
	quad.size = Vector2(14.0, 4.5)
	var view := StandardMaterial3D.new()
	view.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	view.albedo_texture = GLIMMER
	view.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	view.uv1_scale = Vector3(0.7, 0.7, 1.0)
	view.uv1_offset = Vector3(0.1, 0.15, 0.0)
	quad.material = view
	_mesh(room, "PlanetView", quad, Vector3(0.0, 3.45, -9.3), Vector3.ZERO)
	var frame := _set_paint(Color(0.2, 0.1, 0.2))
	for x: float in [-3.5, 0.0, 3.5]:
		_box(room, "WindowMullion", Vector3(0.2, 4.5, 0.25), Vector3(x, 3.45, -9.0), frame)
	_box(room, "WindowNeon", Vector3(14.0, 0.08, 0.08), Vector3(0.0, 5.75, -8.95), _set_paint(MAGENTA, null, 1.0, 2.2))


## Sal's cashier cage: a gold counter with bars on top and a raised floor
## behind it, the cage sign, and the job board beside it.
func _cashier_cage(room: Node3D, body: StaticBody3D, dark: Material, gold: Material) -> void:
	_piece(room, body, "CageCounter", Vector3(6.0, 1.0, 0.8), Vector3(-7.0, 0.5, -4.5), _set_paint(Color(0.45, 0.15, 0.4), WOOD, 0.8))
	_box(room, "CageCounterTop", Vector3(6.2, 0.08, 1.0), Vector3(-7.0, 1.04, -4.5), gold)
	_piece(room, body, "CagePlatform", Vector3(6.0, 0.6, 3.6), Vector3(-7.0, 0.3, -7.2), dark)
	for i in 9:
		_box(room, "CageBar", Vector3(0.05, 1.6, 0.05), Vector3(-9.8 + i * 0.7, 1.9, -4.4), gold)
	_box(room, "CageTop", Vector3(6.0, 0.1, 0.1), Vector3(-7.0, 2.7, -4.4), gold)
	_box(room, "ChipStack", Vector3(0.3, 0.35, 0.3), Vector3(-5.5, 1.25, -4.6), _set_paint(MAGENTA, null, 1.0, 0.6))
	_box(room, "ChipStack2", Vector3(0.3, 0.25, 0.3), Vector3(-5.1, 1.2, -4.6), _set_paint(Color(0.3, 0.6, 1.0), null, 1.0, 0.6))
	_box(room, "CageSignBack", Vector3(5.6, 1.1, 0.1), Vector3(-7.0, 5.2, -8.9), dark)
	_sign(room, "CageSign", "CASHIER", 0.007, GOLD, Vector3(-7.0, 5.35, -8.82))
	_sign(room, "CageSignSub", "SAL'S OFFICE · ALL WINNINGS FINAL · ALL LOSSES TOO", 0.0022, MAGENTA, Vector3(-7.0, 4.85, -8.82))
	# The job board, on the left wall by the cage.
	_box(room, "JobBoardFrame", Vector3(0.2, 2.0, 3.2), Vector3(-10.85, 2.0, -1.0), dark)
	var board := _box(room, "JobBoard", Vector3(0.05, 1.8, 3.0), Vector3(-10.72, 2.0, -1.0), _set_paint(Color.WHITE, JOB_BOARD, 3.0, 0.35))
	board.rotation = Vector3.ZERO
	_sign(room, "JobBoardSign", "HIGH ROLLER FREIGHT", 0.0035, GOLD, Vector3(-10.7, 3.25, -1.0))
	(room.get_node("JobBoardSign") as Node3D).rotation = Vector3(0.0, PI / 2.0, 0.0)


## The roulette table and two card tables, with stools.
func _tables(room: Node3D, body: StaticBody3D, dark: Material, gold: Material) -> void:
	var felt := _set_paint(Color(0.15, 0.5, 0.3))
	var stool := _set_paint(MAGENTA)
	# The roulette table: green felt and a spinning-looking wheel.
	_piece(room, body, "RouletteTable", Vector3(3.2, 0.85, 1.8), Vector3(-1.0, 0.43, -1.5), dark)
	_box(room, "RouletteFelt", Vector3(3.0, 0.04, 1.6), Vector3(-1.0, 0.87, -1.5), felt)
	_cylinder(room, "RouletteWheel", 0.55, 0.12, Vector3(-2.0, 0.95, -1.5), _set_paint(Color(0.35, 0.18, 0.1), WOOD, 0.5), Vector3.ZERO, 16)
	for i in 8:
		var angle := TAU * i / 8.0
		_box(room, "RoulettePocket", Vector3(0.12, 0.03, 0.12), Vector3(-2.0 + sin(angle) * 0.4, 1.02, -1.5 + cos(angle) * 0.4),
				_set_paint(Color(0.9, 0.15, 0.2) if i % 2 == 0 else Color(0.08, 0.06, 0.1)))
	_cylinder(room, "RouletteHub", 0.12, 0.2, Vector3(-2.0, 1.05, -1.5), gold, Vector3.ZERO, 8)
	for i in 4:
		_cylinder(room, "RouletteStool", 0.25, 0.6, Vector3(-2.3 + i * 0.9, 0.3, -0.2), stool, Vector3.ZERO, 8)
	# Two card tables, half-moon felt with chips.
	for spot: Vector3 in [Vector3(-1.5, 0.0, 3.5), Vector3(2.5, 0.0, 3.5)]:
		_piece(room, body, "CardTable", Vector3(2.2, 0.8, 1.3), spot + Vector3(0.0, 0.4, 0.0), dark)
		_box(room, "CardFelt", Vector3(2.0, 0.04, 1.1), spot + Vector3(0.0, 0.82, 0.0), felt)
		for k in 3:
			_box(room, "Card", Vector3(0.18, 0.01, 0.26), spot + Vector3(-0.5 + k * 0.5, 0.85, 0.2), _set_paint(Color(0.97, 0.97, 0.95)))
		_cylinder(room, "TableChips", 0.12, 0.15, spot + Vector3(0.7, 0.92, -0.2), _set_paint(MAGENTA, null, 1.0, 0.5), Vector3.ZERO, 8)
		for side: float in [-1.0, 0.0, 1.0]:
			_cylinder(room, "CardStool", 0.24, 0.55, spot + Vector3(side * 0.8, 0.28, 1.1), stool, Vector3.ZERO, 8)


## Rows of slot machines on the right. The front one (by the walkway) is the
## one you can play.
func _slots(room: Node3D, body: StaticBody3D, dark: Material, gold: Material) -> void:
	var cabinet_colors: Array[Color] = [MAGENTA, Color(0.3, 0.6, 1.0), GOLD, Color(0.5, 1.0, 0.55)]
	for row in 2:
		for i in 5:
			var spot := Vector3(4.0 + i * 1.3, 0.0, -6.5 + row * 3.0)
			var color := cabinet_colors[(i + row) % cabinet_colors.size()]
			_piece(room, body, "SlotCabinet", Vector3(1.0, 1.9, 0.8), spot + Vector3(0.0, 0.95, 0.0), _set_paint(color.darkened(0.4)))
			_box(room, "SlotScreen", Vector3(0.75, 0.45, 0.02), spot + Vector3(0.0, 1.25, 0.41), _set_paint(Color(1.0, 0.95, 0.75), null, 1.0, 1.4))
			_box(room, "SlotTopper", Vector3(1.05, 0.3, 0.85), spot + Vector3(0.0, 2.05, 0.0), _set_paint(color, null, 1.0, 1.8))
			_box(room, "SlotLever", Vector3(0.05, 0.4, 0.05), spot + Vector3(0.55, 1.2, 0.2), gold)
			for k in 3:
				_box(room, "SlotSymbol", Vector3(0.18, 0.18, 0.01), spot + Vector3(-0.24 + k * 0.24, 1.25, 0.425), _set_paint(cabinet_colors[(k + i) % cabinet_colors.size()], null, 1.0, 2.0))
	# The lucky machine at the front, bigger and gold, with a sign.
	var lucky := Vector3(6.6, 0.0, 0.8)
	_piece(room, body, "LuckySlot", Vector3(1.3, 2.2, 0.9), lucky + Vector3(0.0, 1.1, 0.0), _set_paint(GOLD.darkened(0.2)))
	_box(room, "LuckyScreen", Vector3(1.0, 0.55, 0.02), lucky + Vector3(0.0, 1.4, 0.46), _set_paint(Color(1.0, 0.95, 0.75), null, 1.0, 1.6))
	_box(room, "LuckyTopper", Vector3(1.4, 0.4, 0.95), lucky + Vector3(0.0, 2.4, 0.0), _set_paint(MAGENTA, null, 1.0, 2.2))
	_sign(room, "LuckySign", "THE LUCKY MOLAR · 10 CR", 0.0028, GOLD, lucky + Vector3(0.0, 2.85, 0.0))
	var sign_node := room.get_node("LuckySign") as Node3D
	sign_node.rotation = Vector3.ZERO
	_box(room, "SlotsRowSignBack", Vector3(6.0, 0.9, 0.1), Vector3(6.6, 5.3, -8.9), dark)
	_sign(room, "SlotsRowSign", "LOOSEST SLOTS IN THE SECTOR*", 0.0032, MAGENTA, Vector3(6.6, 5.4, -8.82))
	_sign(room, "SlotsRowSub", "*PROBABLY", 0.0022, GOLD, Vector3(6.6, 5.0, -8.82))


## A little lounge stage with a curtain and a mic, and the jukebox.
func _stage(room: Node3D, body: StaticBody3D, dark: Material, gold: Material) -> void:
	_piece(room, body, "Stage", Vector3(5.0, 0.5, 3.0), Vector3(-7.5, 0.25, 6.5), _set_paint(Color(0.35, 0.18, 0.12), WOOD, 0.8))
	_box(room, "StageEdge", Vector3(5.0, 0.06, 0.08), Vector3(-7.5, 0.5, 5.0), _set_paint(GOLD, null, 1.0, 1.5))
	_box(room, "Curtain", Vector3(5.0, 4.5, 0.1), Vector3(-7.5, 2.75, 8.9), _set_paint(Color(0.7, 0.1, 0.25), BLANKET, 1.2))
	_beam(room, "MicStand", Vector3(-7.5, 0.5, 6.2), Vector3(-7.5, 1.9, 6.2), 0.03, gold)
	_box(room, "Mic", Vector3(0.08, 0.14, 0.08), Vector3(-7.5, 1.95, 6.15), dark)
	_box(room, "StageSignBack", Vector3(4.0, 0.8, 0.1), Vector3(-7.5, 5.6, 8.85), dark)
	_sign(room, "StageSign", "TONIGHT: THE CROONING CRAB", 0.0028, MAGENTA, Vector3(-7.5, 5.65, 8.78))
	(room.get_node("StageSign") as Node3D).rotation = Vector3(0.0, PI, 0.0)
	_piece(room, body, "Jukebox", Vector3(0.7, 1.5, 1.1), Vector3(-10.5, 0.75, 3.0), _set_paint(Color(0.55, 0.25, 0.5), WOOD, 0.8))
	_box(room, "JukeboxGlow", Vector3(0.05, 0.9, 0.8), Vector3(-10.13, 0.9, 3.0), _set_paint(MAGENTA, null, 1.0, 2.2))


## The airlock, the pump kiosk, and a "no clocks" detail.
func _lounge_extras(room: Node3D, body: StaticBody3D, dark: Material) -> void:
	_box(room, "AirlockFrame", Vector3(0.3, 3.4, 3.0), Vector3(10.85, 1.7, 5.8), dark)
	_box(room, "AirlockDoor", Vector3(0.06, 2.6, 2.0), Vector3(10.7, 1.3, 5.8), _set_paint(Color(0.85, 0.85, 0.9), DOOR, 2.6))
	_box(room, "AirlockStripes", Vector3(0.04, 0.3, 3.0), Vector3(10.66, 3.0, 5.8), _hazard(2.0))
	_sign(room, "AirlockSign", "DOCK 2 · YOUR RIG", 0.004, Color(0.45, 0.95, 1.0), Vector3(10.6, 3.6, 5.8))
	(room.get_node("AirlockSign") as Node3D).rotation = Vector3(0.0, -PI / 2.0, 0.0)
	_piece(room, body, "PumpKiosk", Vector3(0.9, 1.8, 0.7), Vector3(9.2, 0.9, 3.5), _set_paint(GOLD.darkened(0.3)))
	_box(room, "PumpScreen", Vector3(0.6, 0.4, 0.02), Vector3(9.2, 1.3, 3.86), _set_paint(Color(0.5, 1.0, 0.6), null, 1.0, 1.6))
	# A blank square on the wall where a clock used to be.
	_box(room, "ClockGhost", Vector3(0.9, 0.9, 0.04), Vector3(0.0, 5.5, 8.98), _set_paint(Color(0.42, 0.18, 0.45)))
	# A red carpet runner from the airlock to the cage.
	_box(room, "Runner", Vector3(16.0, 0.02, 1.6), Vector3(1.5, 0.012, 5.8), _set_paint(Color(0.75, 0.1, 0.2)))


func _lounge_lights(room: Node3D) -> void:
	_lamp(room, "CageLight", Vector3(-7.0, 5.0, -3.0), Color(1.0, 0.8, 0.5), 2.6, 10.0)
	_lamp(room, "SlotsLight", Vector3(6.5, 5.0, -3.0), Color(1.0, 0.45, 0.85), 2.4, 11.0)
	_lamp(room, "TablesLight", Vector3(0.0, 5.5, 2.0), Color(1.0, 0.85, 0.6), 2.2, 11.0)
	_lamp(room, "WindowGlow", Vector3(0.0, 3.0, -7.5), MAGENTA, 2.0, 9.0, false)
	_lamp(room, "StageGlow", Vector3(-7.5, 3.5, 5.5), Color(1.0, 0.35, 0.5), 1.6, 8.0, false)
	_lamp(room, "AirlockGlow", Vector3(9.0, 2.5, 5.8), Color(0.5, 0.95, 1.0), 1.4, 6.0, false)
	# Chandeliers: three glowing gold boxes hanging over the floor.
	for x: float in [-6.0, 0.0, 6.0]:
		_beam(room, "ChandelierChain", Vector3(x, 7.0, 1.0), Vector3(x, 6.2, 1.0), 0.03, _set_paint(GOLD))
		_box(room, "Chandelier", Vector3(1.2, 0.4, 1.2), Vector3(x, 6.0, 1.0), _set_paint(Color(1.0, 0.9, 0.6), null, 1.0, 1.8))
	for i in 3:
		_box(room, "CeilingStrip", Vector3(0.3, 0.08, 16.0), Vector3(-8.0 + i * 8.0, 6.95, 0.0), _set_paint(MAGENTA, null, 1.0, 1.0))
