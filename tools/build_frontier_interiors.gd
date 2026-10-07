extends "res://tools/build_truck_stop.gd"
## Builds the insides of the three far systems' stations (where you climb out
## after docking) and the clients who run them:
##     res://scenes/hub/sets/SalvageYardSet.tscn - Hoof & Hull's yard office:
##                                                 corrugated walls, scrap
##                                                 piles, a crane hook, a tin
##                                                 counter, amber work lights
##     res://scenes/hub/sets/ArboretumSet.tscn   - the Arboretum's glasshouse:
##                                                 planters, ferns, a pond,
##                                                 hanging vines, the great
##                                                 tree's trunk through the
##                                                 floor
##     res://scenes/hub/sets/CreamerySet.tscn    - Flurry's parlor: checkered
##                                                 floor, a long ice-cream
##                                                 counter, booths, freezers,
##                                                 icicles, a giant cone
##     res://scenes/hub/GoatVisual.tscn          - Mags Hoofmann
##     res://scenes/hub/TortoiseVisual.tscn      - Dr. Shelby Moss
##     res://scenes/hub/PenguinVisual.tscn       - Penny Flurry
##
## All three rooms share the casino's floor plan (22 x 18 m, 7 m tall), so
## their cameras, doors and people sit in the same spots:
##   back (-Z): a wide window onto the system's planet
##   back-left: the client's counter, on a raised floor behind it
##   left wall: the job board          front-left: the jukebox
##   right wall, front: the airlock to your rig, the pump kiosk beside it
##   middle and right: each place's own things
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_frontier_interiors.gd
##
## Careful: running it again OVERWRITES those scenes. The rooms themselves
## (res://scenes/hub/SalvageYard.tscn, Arboretum.tscn, Creamery.tscn) are
## NOT touched.

const DESERT := preload("res://textures/generated/desert_planet.png")
const JUNGLE := preload("res://textures/generated/jungle_planet.png")
const ICE := preload("res://textures/generated/ice_planet.png")


func _initialize() -> void:
	_animator_script = load(ANIMATOR_PATH)
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_save(_goat(), "res://scenes/hub/GoatVisual.tscn")
	_save(_tortoise(), "res://scenes/hub/TortoiseVisual.tscn")
	_save(_penguin(), "res://scenes/hub/PenguinVisual.tscn")
	_save(_salvage_set(), "res://scenes/hub/sets/SalvageYardSet.tscn")
	_save(_arboretum_set(), "res://scenes/hub/sets/ArboretumSet.tscn")
	_save(_creamery_set(), "res://scenes/hub/sets/CreamerySet.tscn")
	quit()


# --- The clients ---------------------------------------------------------------------------

## Mags: a goat in rust-orange overalls with welding goggles pushed up.
## Hook: curling horns and a long chin beard.
func _goat() -> Node3D:
	var cream := Color(0.9, 0.85, 0.74)
	var critter := _build_critter("GoatVisual", _look(cream, Color(0.98, 0.95, 0.88), Color(0.85, 0.42, 0.18), Color(0.4, 0.3, 0.25), Color(0, 0, 0, 0), "round", "puff"))
	var head := _head(critter)
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic"])
	var horn := _paint(Color(0.55, 0.45, 0.35), null)
	for side: float in [-1.0, 1.0]:
		# The horns sweep up and back, then curl down.
		var base := _box(head, "Horn", Vector3(0.06, 0.16, 0.06), Vector3(0.1 * side, 0.46, 0.02), horn)
		base.rotation = Vector3(-0.5, 0.0, 0.2 * side)
		var curl := _box(head, "HornCurl", Vector3(0.05, 0.12, 0.05), Vector3(0.14 * side, 0.5, 0.12), horn)
		curl.rotation = Vector3(-1.6, 0.0, 0.3 * side)
		# Goat ears stick out sideways.
		var ear := head.get_node("EarLeft" if side < 0.0 else "EarRight") as Node3D
		ear.rotation = Vector3(0.0, 0.0, -1.2 * side)
		ear.position = Vector3(0.21 * side, 0.27, 0.0)
		_box(head, "Pupil", Vector3(0.05, 0.015, 0.012), Vector3(0.09 * side, 0.22, -0.193), _paint(Color(0.9, 0.75, 0.3), null))
	_box(head, "Beard", Vector3(0.08, 0.16, 0.06), Vector3(0.0, -0.01, -0.19), _paint(Color(0.95, 0.93, 0.85), FUZZ, Vector2(8, 8)))
	_box(head, "Goggles", Vector3(0.38, 0.06, 0.04), Vector3(0.0, 0.36, -0.15), _paint(Color(0.2, 0.2, 0.22), null))
	for side: float in [-1.0, 1.0]:
		_box(head, "GoggleLens", Vector3(0.09, 0.05, 0.02), Vector3(0.08 * side, 0.36, -0.175), _paint(Color(1.0, 0.65, 0.25), null))
	var body := critter.get_node("Body") as Node3D
	_box(body, "OverallBib", Vector3(0.2, 0.16, 0.02), Vector3(0.0, 0.12, -0.115), _paint(Color(0.75, 0.35, 0.15), null))
	_box(body, "Wrench", Vector3(0.04, 0.2, 0.04), Vector3(-0.2, -0.05, -0.08), _paint(Color(0.75, 0.78, 0.82), null))
	return critter


## Dr. Moss: a tortoise in a white lab coat with round glasses. Hook: a big
## domed shell on her back, mossy on top.
func _tortoise() -> Node3D:
	var skin := Color(0.48, 0.6, 0.36)
	var critter := _build_critter("TortoiseVisual", _look(skin, Color(0.7, 0.75, 0.5), Color(0.95, 0.96, 0.94), Color(0.3, 0.38, 0.3), Color(0, 0, 0, 0), "round", "puff"))
	var head := _head(critter)
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic", "Body/Head/EarLeft", "Body/Head/EarRight", "Body/Head/Nose", "Body/Tail"])
	head.scale = Vector3(0.9, 0.85, 1.05)
	for side: float in [-1.0, 1.0]:
		_box(head, "GlassRim", Vector3(0.1, 0.1, 0.015), Vector3(0.09 * side, 0.22, -0.2), _paint(Color(0.75, 0.6, 0.3), null))
	_box(head, "GlassBridge", Vector3(0.06, 0.015, 0.015), Vector3(0.0, 0.23, -0.2), _paint(Color(0.75, 0.6, 0.3), null))
	_box(head, "Smile", Vector3(0.16, 0.015, 0.02), Vector3(0.0, 0.1, -0.225), _paint(Color(0.25, 0.3, 0.2), null))
	var body := critter.get_node("Body") as Node3D
	# The shell: a squashed half-ball on her back, with plates and moss.
	var shell := SphereMesh.new()
	shell.radius = 0.26
	shell.height = 0.26
	shell.is_hemisphere = true
	shell.radial_segments = 10
	shell.rings = 4
	shell.material = _paint(Color(0.55, 0.38, 0.22), FUZZ, Vector2(3.0, 3.0))
	var dome := _mesh(body, "Shell", shell, Vector3(0.0, 0.14, 0.12), Vector3(-PI / 2.0, 0.0, 0.0))
	dome.scale = Vector3(1.0, 0.9, 1.0)
	for i in 5:
		var angle := TAU * i / 5.0
		_box(body, "ShellPlate", Vector3(0.09, 0.09, 0.02), Vector3(sin(angle) * 0.13, 0.14 + cos(angle) * 0.13, 0.33), _paint(Color(0.68, 0.5, 0.3), null))
	_box(body, "ShellMoss", Vector3(0.18, 0.06, 0.12), Vector3(0.0, 0.33, 0.18), _paint(Color(0.35, 0.7, 0.3), FUZZ, Vector2(8, 8)))
	_box(body, "Clipboard", Vector3(0.14, 0.18, 0.02), Vector3(0.19, -0.02, -0.1), _paint(Color(0.6, 0.45, 0.3), null))
	return critter


## Penny: a penguin in a pink soda-jerk apron and paper hat. Hook: an orange
## beak and big orange feet.
func _penguin() -> Node3D:
	var black := Color(0.14, 0.15, 0.22)
	var critter := _build_critter("PenguinVisual", _look(black, Color(0.97, 0.97, 1.0), black, black, Color(0, 0, 0, 0), "round", "puff"))
	var head := _head(critter)
	_remove(critter, ["Body/Head/Headset", "Body/Head/Mic", "Body/Head/EarLeft", "Body/Head/EarRight", "Body/Head/Snout", "Body/Head/Nose"])
	var orange := _paint(Color(1.0, 0.6, 0.15), null)
	_box(head, "Face", Vector3(0.3, 0.2, 0.02), Vector3(0.0, 0.18, -0.175), _paint(Color(0.97, 0.97, 1.0), FUZZ, Vector2(8, 8)))
	_box(head, "Beak", Vector3(0.1, 0.05, 0.1), Vector3(0.0, 0.14, -0.23), orange)
	for side: float in [-1.0, 1.0]:
		_box(head, "Blush", Vector3(0.05, 0.025, 0.01), Vector3(0.13 * side, 0.15, -0.187), _paint(Color(1.0, 0.6, 0.75), null))
	# The paper hat, folded, with a stripe.
	_box(head, "PaperHat", Vector3(0.3, 0.1, 0.18), Vector3(0.0, 0.43, -0.02), _paint(Color(0.98, 0.98, 0.95), null))
	_box(head, "HatStripe", Vector3(0.31, 0.03, 0.19), Vector3(0.0, 0.42, -0.02), _paint(Color(1.0, 0.55, 0.75), null))
	var body := critter.get_node("Body") as Node3D
	_box(body, "Belly", Vector3(0.22, 0.26, 0.02), Vector3(0.0, 0.12, -0.112), _paint(Color(0.97, 0.97, 1.0), FUZZ, Vector2(8, 8)))
	_box(body, "Apron", Vector3(0.2, 0.2, 0.02), Vector3(0.0, 0.05, -0.122), _paint(Color(1.0, 0.6, 0.8), null))
	_box(body, "Scoop", Vector3(0.04, 0.18, 0.04), Vector3(0.2, -0.05, -0.08), _paint(Color(0.8, 0.82, 0.88), null))
	for side: float in [-1.0, 1.0]:
		var leg := critter.get_node("LegLeft" if side < 0.0 else "LegRight") as Node3D
		_box(leg, "Foot", Vector3(0.15, 0.04, 0.22), Vector3(0.0, -0.33, -0.05), orange)
		var boot := leg.get_node_or_null("Boot")
		if boot != null:
			boot.free()
	return critter


# --- The shared floor plan ------------------------------------------------------------------

## The room every far station shares (see the top of this file). Returns
## [room, body]; each place adds its own things on top.
func _base_room(set_name: String, look: Dictionary) -> Array:
	var parts := _new_set(set_name)
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var wall: Material = look["wall"]
	var dark: Material = look["dark"]
	var accent: Color = look["accent"]
	_room_shell(room, body, Vector3(22.0, 7.0, 18.0), look["floor"], wall, look["ceiling"])
	# The window onto the planet.
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
	view.albedo_texture = look["planet"]
	view.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	view.uv1_scale = Vector3(0.7, 0.7, 1.0)
	view.uv1_offset = Vector3(0.1, 0.15, 0.0)
	quad.material = view
	_mesh(room, "PlanetView", quad, Vector3(0.0, 3.45, -9.3), Vector3.ZERO)
	for x: float in [-3.5, 0.0, 3.5]:
		_box(room, "WindowMullion", Vector3(0.2, 4.5, 0.25), Vector3(x, 3.45, -9.0), dark)
	_box(room, "WindowNeon", Vector3(14.0, 0.08, 0.08), Vector3(0.0, 5.75, -8.95), _set_paint(accent, null, 1.0, 2.2))
	# The client's counter and the raised floor behind it.
	_piece(room, body, "Counter", Vector3(6.0, 1.0, 0.8), Vector3(-7.0, 0.5, -4.5), look["counter"])
	_box(room, "CounterTop", Vector3(6.2, 0.08, 1.0), Vector3(-7.0, 1.04, -4.5), look["counter_top"])
	_piece(room, body, "CounterPlatform", Vector3(6.0, 0.6, 3.6), Vector3(-7.0, 0.3, -7.2), dark)
	_box(room, "CounterSignBack", Vector3(5.6, 1.1, 0.1), Vector3(-7.0, 5.2, -8.9), dark)
	_sign(room, "CounterSign", look["sign"], 0.006, accent, Vector3(-7.0, 5.35, -8.82))
	_sign(room, "CounterSignSub", look["sub_sign"], 0.0022, look["second"], Vector3(-7.0, 4.85, -8.82))
	# The job board on the left wall.
	_box(room, "JobBoardFrame", Vector3(0.2, 2.0, 3.2), Vector3(-10.85, 2.0, -1.0), dark)
	_box(room, "JobBoard", Vector3(0.05, 1.8, 3.0), Vector3(-10.72, 2.0, -1.0), _set_paint(Color.WHITE, JOB_BOARD, 3.0, 0.35))
	_sign(room, "JobBoardSign", look["board_sign"], 0.0035, accent, Vector3(-10.7, 3.25, -1.0))
	(room.get_node("JobBoardSign") as Node3D).rotation = Vector3(0.0, PI / 2.0, 0.0)
	# The jukebox, front-left.
	_piece(room, body, "Jukebox", Vector3(0.7, 1.5, 1.1), Vector3(-10.5, 0.75, 3.0), _set_paint(Color(0.45, 0.3, 0.25), WOOD, 0.8))
	_box(room, "JukeboxGlow", Vector3(0.05, 0.9, 0.8), Vector3(-10.13, 0.9, 3.0), _set_paint(accent, null, 1.0, 2.2))
	# The airlock to your rig, and the pump kiosk.
	_box(room, "AirlockFrame", Vector3(0.3, 3.4, 3.0), Vector3(10.85, 1.7, 5.8), dark)
	_box(room, "AirlockDoor", Vector3(0.06, 2.6, 2.0), Vector3(10.7, 1.3, 5.8), _set_paint(Color(0.85, 0.85, 0.9), DOOR, 2.6))
	_box(room, "AirlockStripes", Vector3(0.04, 0.3, 3.0), Vector3(10.66, 3.0, 5.8), _hazard(2.0))
	_sign(room, "AirlockSign", "DOCK 1 · YOUR RIG", 0.004, Color(0.45, 0.95, 1.0), Vector3(10.6, 3.6, 5.8))
	(room.get_node("AirlockSign") as Node3D).rotation = Vector3(0.0, -PI / 2.0, 0.0)
	_piece(room, body, "PumpKiosk", Vector3(0.9, 1.8, 0.7), Vector3(9.2, 0.9, 3.5), look["counter"])
	_box(room, "PumpScreen", Vector3(0.6, 0.4, 0.02), Vector3(9.2, 1.3, 3.86), _set_paint(Color(0.5, 1.0, 0.6), null, 1.0, 1.6))
	# Lights: the counter, the room, the window and the airlock.
	_lamp(room, "CounterLight", Vector3(-7.0, 5.0, -3.0), look["lamp"], 2.6, 10.0)
	_lamp(room, "RoomLight", Vector3(4.0, 5.5, -2.0), look["lamp"], 2.4, 12.0)
	_lamp(room, "FrontLight", Vector3(0.0, 5.5, 4.0), look["lamp"], 2.0, 11.0)
	_lamp(room, "WindowGlow", Vector3(0.0, 3.0, -7.5), accent, 1.8, 9.0, false)
	_lamp(room, "AirlockGlow", Vector3(9.0, 2.5, 5.8), Color(0.5, 0.95, 1.0), 1.4, 6.0, false)
	return [room, body]


# --- Hoof & Hull Salvage --------------------------------------------------------------------

func _salvage_set() -> Node3D:
	var amber := Color(1.0, 0.65, 0.25)
	var dark := _set_paint(Color(0.16, 0.12, 0.1))
	var rust := _set_paint(Color(0.55, 0.32, 0.2), WALL_PANELS, 2.0)
	var steel := _set_paint(Color(0.5, 0.5, 0.52), MACHINERY, 1.5)
	var parts := _base_room("SalvageYardSet", {
		"wall": rust, "dark": dark, "floor": _set_paint(Color(0.45, 0.4, 0.35), GRATE, 1.0),
		"ceiling": _set_paint(Color(0.12, 0.1, 0.09), PIPES, 2.0), "planet": DESERT, "accent": amber, "second": Color(1.0, 0.9, 0.6),
		"counter": _set_paint(Color(0.6, 0.6, 0.62), MACHINERY, 1.0), "counter_top": _set_paint(Color(0.75, 0.75, 0.78)),
		"sign": "HOOF & HULL", "sub_sign": "WE BUY · WE SELL · WE DON'T ASK", "board_sign": "HAULING WANTED", "lamp": Color(1.0, 0.75, 0.45),
	})
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	# Scrap piles in the middle and right: crates, drums, old rig doors,
	# tires, a fridge (the canyon has the other one).
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var junk: Array[Color] = [Color(0.4, 0.5, 0.6), Color(0.75, 0.3, 0.25), Color(0.85, 0.8, 0.6), Color(0.3, 0.45, 0.35), Color(0.65, 0.6, 0.55)]
	for pile: Vector3 in [Vector3(4.5, 0.0, -5.5), Vector3(7.5, 0.0, -2.0), Vector3(1.0, 0.0, -6.0)]:
		_bump_box(room, body, "PileBump", Vector3(3.0, 1.6, 2.4), pile + Vector3(0.0, 0.8, 0.0))
		for i in 7:
			var size := Vector3(rng.randf_range(0.5, 1.3), rng.randf_range(0.4, 1.0), rng.randf_range(0.5, 1.2))
			var lump := _box(room, "Scrap", size, pile + Vector3(rng.randf_range(-1.1, 1.1), size.y * 0.5 + (0.6 if i > 4 else 0.0), rng.randf_range(-0.8, 0.8)), _set_paint(junk[(i + int(pile.x)) % junk.size()], CRATE, 1.0))
			lump.rotation = Vector3(0.0, rng.randf() * TAU, rng.randf_range(-0.2, 0.2))
	for i in 3:
		_cylinder(room, "Tire", 0.45, 0.3, Vector3(3.0 + i * 0.4, 0.15 + i * 0.3, 1.5), _set_paint(Color(0.12, 0.12, 0.13)), Vector3.ZERO, 12)
	_piece(room, body, "Fridge", Vector3(0.9, 1.9, 0.8), Vector3(-2.5, 0.95, -7.8), _set_paint(Color(0.85, 0.9, 0.8)))
	_sign(room, "FridgeNote", "NOT FOR SALE", 0.0018, Color(1.0, 0.4, 0.3), Vector3(-2.5, 1.5, -7.38))
	# The crane hook hanging from a ceiling rail, and a workbench.
	_box(room, "CraneRail", Vector3(14.0, 0.25, 0.4), Vector3(2.0, 6.75, -1.0), steel)
	_beam(room, "HookChain", Vector3(3.5, 6.6, -1.0), Vector3(3.5, 3.4, -1.0), 0.04, steel)
	_box(room, "Hook", Vector3(0.5, 0.6, 0.15), Vector3(3.5, 3.1, -1.0), _set_paint(Color(0.95, 0.75, 0.2)))
	_piece(room, body, "Workbench", Vector3(3.0, 0.9, 1.0), Vector3(-3.0, 0.45, 6.6), _set_paint(Color(0.45, 0.32, 0.22), WOOD, 0.8))
	_box(room, "Pegboard", Vector3(3.0, 1.6, 0.06), Vector3(-3.0, 2.2, 8.95), _set_paint(Color(0.6, 0.5, 0.35), MACHINERY, 1.2))
	_box(room, "Lamp", Vector3(0.5, 0.2, 0.4), Vector3(-3.0, 1.6, 6.6), _set_paint(amber, null, 1.0, 2.0))
	# Oil drums by the jukebox, and dust on the floor.
	for i in 3:
		_cylinder(room, "Drum", 0.35, 1.0, Vector3(-9.6 + i * 0.75, 0.5, 6.8), _set_paint(junk[i]), Vector3.ZERO, 10)
	_box(room, "DustDrift", Vector3(6.0, 0.03, 3.0), Vector3(2.0, 0.015, 3.0), _set_paint(Color(0.85, 0.65, 0.4)))
	_box(room, "Runner", Vector3(16.0, 0.02, 1.6), Vector3(1.5, 0.012, 5.8), _hazard(1.0))
	# Work lights strung across the ceiling.
	for x: float in [-6.0, 0.0, 6.0]:
		_beam(room, "LampCord", Vector3(x, 7.0, 1.0), Vector3(x, 6.0, 1.0), 0.02, dark)
		_box(room, "WorkLamp", Vector3(0.5, 0.3, 0.5), Vector3(x, 5.85, 1.0), _set_paint(amber, null, 1.0, 2.0))
	_lamp(room, "PileLight", Vector3(5.0, 4.0, -4.0), amber, 1.6, 8.0, false)
	return room


# --- The Orbital Arboretum ------------------------------------------------------------------

func _arboretum_set() -> Node3D:
	var green := Color(0.45, 1.0, 0.45)
	var dark := _set_paint(Color(0.1, 0.16, 0.12))
	var leaves := _set_paint(Color(0.3, 0.7, 0.35), BLANKET, 0.6)
	var soil := _set_paint(Color(0.35, 0.25, 0.18))
	var parts := _base_room("ArboretumSet", {
		"wall": _set_paint(Color(0.82, 0.9, 0.82), WALL_PANELS, 3.0), "dark": dark, "floor": _set_paint(Color(0.55, 0.5, 0.42), FLOOR_TILES, 1.2),
		"ceiling": _set_paint(Color(0.6, 0.85, 0.7), GRATE, 2.0), "planet": JUNGLE, "accent": green, "second": Color(1.0, 0.65, 0.85),
		"counter": _set_paint(Color(0.45, 0.32, 0.22), WOOD, 0.8), "counter_top": _set_paint(Color(0.85, 0.82, 0.7)),
		"sign": "THE ARBORETUM", "sub_sign": "PLEASE DO NOT WAKE THE MOSS", "board_sign": "SEEDS & SHIPPING", "lamp": Color(0.9, 1.0, 0.8),
	})
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	# The great tree's trunk, coming up through the floor and out through
	# the ceiling, with a ring of moss around it.
	_piece(room, body, "Trunk", Vector3(2.2, 7.0, 2.2), Vector3(3.0, 3.5, -3.5), _set_paint(Color(0.45, 0.3, 0.2), WOOD, 1.5))
	_cylinder(room, "TrunkMoss", 1.9, 0.3, Vector3(3.0, 0.15, -3.5), leaves, Vector3.ZERO, 12)
	for i in 6:
		var angle := TAU * i / 6.0
		var root_piece := _box(room, "Root", Vector3(0.4, 0.3, 1.6), Vector3(3.0 + sin(angle) * 1.4, 0.15, -3.5 + cos(angle) * 1.4), _set_paint(Color(0.4, 0.28, 0.18), WOOD, 1.0))
		root_piece.rotation = Vector3(0.0, angle, 0.0)
	# Planters with ferns and flowers, a pond with a little bridge.
	for spot: Vector3 in [Vector3(-2.0, 0.0, -1.5), Vector3(7.5, 0.0, -6.5), Vector3(-2.0, 0.0, 3.5), Vector3(7.5, 0.0, 0.0)]:
		_piece(room, body, "Planter", Vector3(2.4, 0.7, 1.4), spot + Vector3(0.0, 0.35, 0.0), _set_paint(Color(0.75, 0.55, 0.4), WOOD, 1.0))
		_box(room, "PlanterSoil", Vector3(2.2, 0.05, 1.2), spot + Vector3(0.0, 0.7, 0.0), soil)
		for k in 4:
			var fern := _box(room, "Fern", Vector3(0.5, 0.8, 0.5), spot + Vector3(-0.8 + k * 0.55, 1.1, 0.0), leaves)
			fern.rotation = Vector3(0.2 * (k % 2 * 2 - 1), k * 0.7, 0.0)
		_box(room, "Flowers", Vector3(1.6, 0.15, 0.5), spot + Vector3(0.0, 0.85, 0.35), _set_paint(Color(1.0, 0.6, 0.85), null, 1.0, 0.6))
	_box(room, "Pond", Vector3(4.0, 0.04, 2.6), Vector3(3.0, 0.02, 2.5), _set_paint(Color(0.3, 0.65, 0.85), null, 1.0, 0.5))
	_box(room, "PondRim", Vector3(4.4, 0.15, 3.0), Vector3(3.0, 0.0, 2.5), _set_paint(Color(0.6, 0.6, 0.55)))
	_box(room, "LilyPad", Vector3(0.5, 0.03, 0.5), Vector3(2.0, 0.05, 2.2), leaves)
	_box(room, "LilyPad", Vector3(0.4, 0.03, 0.4), Vector3(4.0, 0.05, 3.0), leaves)
	# Vines hanging from the ceiling, and glowing seed lamps.
	var rng := RandomNumberGenerator.new()
	rng.seed = 505
	for i in 14:
		var x := rng.randf_range(-9.0, 9.0)
		var z := rng.randf_range(-7.0, 7.0)
		var length := rng.randf_range(1.0, 2.6)
		_box(room, "Vine", Vector3(0.12, length, 0.12), Vector3(x, 7.0 - length * 0.5, z), leaves)
	for x: float in [-6.0, 0.0, 6.0]:
		_beam(room, "LampCord", Vector3(x, 7.0, 1.0), Vector3(x, 6.0, 1.0), 0.02, dark)
		_box(room, "SeedLamp", Vector3(0.5, 0.5, 0.5), Vector3(x, 5.8, 1.0), _set_paint(Color(1.0, 0.9, 0.55), null, 1.0, 1.8))
	_box(room, "Runner", Vector3(16.0, 0.02, 1.6), Vector3(1.5, 0.012, 5.8), _set_paint(Color(0.35, 0.55, 0.3), CARPET, 1.0))
	_lamp(room, "PondGlow", Vector3(3.0, 1.5, 2.5), Color(0.5, 0.85, 1.0), 1.2, 6.0, false)
	return room


# --- Flurry's Comet Creamery ----------------------------------------------------------------

func _creamery_set() -> Node3D:
	var lavender := Color(0.8, 0.65, 1.0)
	var pink := Color(1.0, 0.65, 0.82)
	var dark := _set_paint(Color(0.18, 0.15, 0.26))
	var parts := _base_room("CreamerySet", {
		"wall": _set_paint(Color(0.85, 0.8, 0.95), WALL_PANELS, 3.0), "dark": dark, "floor": _set_paint(Color(0.95, 0.92, 0.95), FLOOR_TILES, 0.8),
		"ceiling": _set_paint(Color(0.92, 0.88, 1.0)), "planet": ICE, "accent": lavender, "second": pink,
		"counter": _set_paint(Color(0.95, 0.75, 0.85)), "counter_top": _set_paint(Color(0.98, 0.98, 1.0)),
		"sign": "FLURRY'S", "sub_sign": "COMET CREAMERY · 80 FLAVORS · 1 PLAIN", "board_sign": "DELIVERIES", "lamp": Color(0.95, 0.92, 1.0),
	})
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	# Tubs of ice cream in the counter's glass case.
	var flavors: Array[Color] = [Color(1.0, 0.7, 0.85), Color(0.95, 0.95, 0.85), Color(0.55, 0.35, 0.25), Color(0.6, 0.9, 0.7), Color(0.75, 0.65, 1.0), Color(1.0, 0.85, 0.4)]
	for i in 6:
		_box(room, "Tub", Vector3(0.7, 0.18, 0.5), Vector3(-9.2 + i * 0.85, 1.15, -4.5), _set_paint(flavors[i], null, 1.0, 0.25))
	_box(room, "GlassCase", Vector3(5.6, 0.4, 0.05), Vector3(-7.0, 1.3, -4.1), _set_paint(Color(0.8, 0.9, 1.0), null, 1.0, 0.3))
	# Booths with pink seats and little tables in the middle and right.
	for spot: Vector3 in [Vector3(0.0, 0.0, -5.0), Vector3(5.0, 0.0, -5.0), Vector3(0.0, 0.0, 0.5), Vector3(5.0, 0.0, 0.5)]:
		_piece(room, body, "BoothTable", Vector3(1.6, 0.8, 1.0), spot + Vector3(0.0, 0.4, 0.0), _set_paint(Color(0.98, 0.98, 1.0)))
		for side: float in [-1.0, 1.0]:
			_piece(room, body, "BoothSeat", Vector3(1.6, 0.5, 0.6), spot + Vector3(0.0, 0.25, side * 1.0), _set_paint(pink))
			_box(room, "BoothBack", Vector3(1.6, 0.8, 0.15), spot + Vector3(0.0, 0.9, side * 1.3), _set_paint(pink))
		_box(room, "Sundae", Vector3(0.25, 0.3, 0.25), spot + Vector3(0.3, 0.95, 0.0), _set_paint(flavors[int(spot.x) % flavors.size()], null, 1.0, 0.3))
	# Freezers along the right wall, with frost puffing.
	for i in 3:
		_piece(room, body, "Freezer", Vector3(0.9, 2.0, 1.4), Vector3(10.4, 1.0, -7.0 + i * 1.6), _set_paint(Color(0.85, 0.9, 1.0), MACHINERY, 1.2))
		_box(room, "FreezerLight", Vector3(0.04, 0.3, 1.0), Vector3(9.94, 1.6, -7.0 + i * 1.6), _set_paint(Color(0.6, 0.85, 1.0), null, 1.0, 1.6))
	# Icicles along the window top, and the giant cone in the front corner.
	for i in 18:
		_box(room, "Icicle", Vector3(0.08, 0.3 + (i % 3) * 0.15, 0.08), Vector3(-6.8 + i * 0.8, 5.55 - (i % 3) * 0.07, -8.95), _set_paint(Color(0.85, 0.92, 1.0), null, 1.0, 0.5))
	_piece(room, body, "ConePlinth", Vector3(1.4, 0.4, 1.4), Vector3(6.0, 0.2, 6.5), dark)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.6
	cone.bottom_radius = 0.05
	cone.height = 1.8
	cone.radial_segments = 8
	cone.material = _set_paint(Color(0.85, 0.6, 0.3), WOOD, 0.4)
	_mesh(room, "GiantCone", cone, Vector3(6.0, 1.3, 6.5))
	for i in 3:
		var scoop := SphereMesh.new()
		scoop.radius = 0.6 - i * 0.06
		scoop.height = scoop.radius * 2.0
		scoop.radial_segments = 10
		scoop.rings = 5
		scoop.material = _set_paint(flavors[i], null, 1.0, 0.2)
		_mesh(room, "GiantScoop", scoop, Vector3(6.0, 2.5 + i * 0.75, 6.5))
	_box(room, "Runner", Vector3(16.0, 0.02, 1.6), Vector3(1.5, 0.012, 5.8), _set_paint(lavender, CARPET, 1.0))
	# Checkerboard strip along the walls, and the neon cone sign.
	for i in 22:
		_box(room, "WallCheck", Vector3(1.0, 0.5, 0.05), Vector3(-10.5 + i * 1.0, 1.25, 8.95), _set_paint(pink if i % 2 == 0 else Color(0.98, 0.98, 1.0)))
	_box(room, "NeonConeBack", Vector3(2.4, 1.6, 0.1), Vector3(0.0, 5.0, 8.9), dark)
	_sign(room, "NeonCone", "ONE SCOOP FREE · ALWAYS", 0.003, pink, Vector3(0.0, 5.0, 8.82))
	(room.get_node("NeonCone") as Node3D).rotation = Vector3(0.0, PI, 0.0)
	_lamp(room, "FreezerGlow", Vector3(9.0, 2.0, -5.0), Color(0.6, 0.85, 1.0), 1.4, 7.0, false)
	return room
