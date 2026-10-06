extends "res://tools/build_placeholder_models.gd"
## Builds the rigs you can buy at Dusty's from the developer's ship design
## sheets (reference/Gemini_Generated_Image_*), at rig size (about 32 m
## long, the same as the Lazy Susan), into res://scenes/flight/rigs/:
##
##     StackShipVisual   - SLAB, the Ship Logistical Armored Barge (Stack-Ship Corp.)
##     BulkOreVisual     - Bulk-Ore class (System Mining Guild): navy and orange, an open ore bay
##     TankerVisual      - Tanker class bulk LNG carrier: frosty, two glowing cryo spheres
##     CatamaranVisual   - Catamaran class inter-system barge: twin hulls, containers between
##     OmegaCrawlerVisual- Oreo class Omega Ore Crawler: the deluxe gray hauler with a long ore slot
##     OreCrawlerVisual  - Ore-Crawler: construction yellow, hazard-striped jaws, cranes
##     IceTugVisual      - Ice-Tug: icy blue with black stripes, a tall cab
##     HabBrickVisual    - Hab-Brick: a red-brown colony block, rows of lit windows, a garden
##     GarbageScowVisual - Garbage Scow: an open rusty frame full of junk, a grabber, space gulls
##
## Every rig points its nose along -Z, and has "Nozzle" markers on the backs
## of its engines (Ship.gd hangs the flames on those). Their handling lives
## in data/ships/*.tres.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_rigs.gd
## Re-running overwrites the rig scenes.


const OCTAGON_TURN := Vector3(PI / 2.0, PI / 8.0, 0.0)
const GLASS := Color(1.0, 0.72, 0.3)
const ROCK_TEXTURE := preload("res://textures/generated/rock.png")


func _initialize() -> void:
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_trail_script = load(TRAIL_SCRIPT_PATH)
	_flare_script = load(FLARE_SCRIPT_PATH)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/flight/rigs"))
	_ship_mode = true  # Solid paint with panel details, not a tiled texture.
	var rigs := {
		"StackShipVisual": _stack_ship(),
		"BulkOreVisual": _bulk_ore(),
		"TankerVisual": _tanker(),
		"CatamaranVisual": _catamaran(),
		"OmegaCrawlerVisual": _omega_crawler(),
		"OreCrawlerVisual": _ore_crawler(),
		"IceTugVisual": _ice_tug(),
		"HabBrickVisual": _hab_brick(),
		"GarbageScowVisual": _garbage_scow(),
	}
	for rig_name: String in rigs:
		_save(rigs[rig_name], "res://scenes/flight/rigs/%s.tscn" % rig_name)
	quit()


# --- Shared bits ---------------------------------------------------------------

func _rig(rig_name: String) -> Node3D:
	var rig := Node3D.new()
	rig.name = rig_name
	return rig


## The cab up front: a sloped glass strip (where Jacki sits) and a little
## headlight pair. Every rig has one, so it reads as somebody's truck.
func _cab(rig: Node3D, nose_z: float, y: float, width: float) -> void:
	_loft(rig, "CabGlass", Vector3(0.0, y, nose_z - 0.05), Vector2(width * 0.55, 0.7), Vector3(0.0, y + 0.5, nose_z + 2.6), Vector2(width * 0.75, 1.2),
			_glow(GLASS, 1.0, Color(0.35, 0.2, 0.05)))
	for side: float in [-1.0, 1.0]:
		_box(rig, "Headlight", Vector3(0.5, 0.3, 0.12), Vector3(width * 0.32 * side, y - 1.4, nose_z - 0.08), _glow(Color(1.0, 0.95, 0.8), 1.4))


## Red and green nav lights (blinking) and an amber roof beacon.
func _lights(rig: Node3D, half_width: float, y: float, z: float, beacon_spot: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		var color := Color(1.0, 0.15, 0.15) if side < 0.0 else Color(0.2, 1.0, 0.35)
		var nav := _box(rig, "NavLight", Vector3(0.35, 0.35, 0.35), Vector3(half_width * side, y, z), _glow(color, 1.6))
		nav.set_script(_blinker_script)
		nav.set("offset", 0.0 if side < 0.0 else 0.5)
	var beacon := _box(rig, "Beacon", Vector3(0.5, 0.35, 0.5), beacon_spot, _glow(Color(1.0, 0.45, 0.1), 1.8))
	beacon.set_script(_blinker_script)
	beacon.set("offset", 0.25)


## A neon company sign on both flanks, facing out.
func _flank_signs(rig: Node3D, text: String, color: Color, half_width: float, where: Vector3, meters_per_pixel: float = 0.012) -> void:
	for side: float in [-1.0, 1.0]:
		var label := Label3D.new()
		label.name = "Sign"
		label.text = text
		label.font_size = 96
		label.pixel_size = meters_per_pixel
		label.outline_size = 14
		label.modulate = color
		label.outline_modulate = Color(color.r * 0.25, color.g * 0.25, color.b * 0.3)
		label.double_sided = false
		label.position = Vector3(side * (half_width + 0.06), where.y, where.z)
		label.rotation = Vector3(0.0, side * PI / 2.0, 0.0)
		rig.add_child(label, true)


## An 8-sided frame ring round the hull (the chunky octagon rings on the
## sheets): a frame with a dark recess inside, along Z.
func _octagon_frame(rig: Node3D, size: Vector2, depth: float, z: float, frame: Material) -> void:
	_loft(rig, "Frame", Vector3(0.0, 0.0, z - depth * 0.5), size, Vector3(0.0, 0.0, z + depth * 0.5), size, frame, 0.25)
	_loft(rig, "FrameRecess", Vector3(0.0, 0.0, z - depth * 0.5 - 0.05), size * 0.74, Vector3(0.0, 0.0, z - depth * 0.5 + 0.4), size * 0.74,
			_paint(Color(0.1, 0.09, 0.13), null), 0.25)


func _ball(rig: Node3D, node_name: String, radius: float, where: Vector3, material: Material, squash: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	sphere.material = material
	var ball := _mesh(rig, node_name, sphere, where)
	ball.scale = squash
	return ball


func _rock(color: Color) -> ShaderMaterial:
	return _paint(color, ROCK_TEXTURE, Vector2(0.35, 0.35))


# --- STACK-SHIP: the armored barge ----------------------------------------------
# Warm gray, a fat orange band, two octagon frames up front, little windows
# on top, scaffolding with work decks down one flank, a ribbed engine block
# with four engines, and a green neon "STACK-SHIP CORP." sign.

func _stack_ship() -> Node3D:
	var rig := _rig("StackShipVisual")
	var gray := _paint(Color(0.66, 0.62, 0.6))
	var orange := _paint(Color(0.95, 0.5, 0.16))
	var dark := _paint(Color(0.2, 0.2, 0.24), null)
	_loft(rig, "Hull", Vector3(0.0, 0.0, -12.0), Vector2(8.0, 8.6), Vector3(0.0, 0.0, 9.0), Vector2(8.0, 8.6), gray, 0.18)
	_octagon_frame(rig, Vector2(9.4, 10.0), 2.4, -15.0, gray)
	_octagon_frame(rig, Vector2(9.4, 10.0), 2.4, -11.6, gray)
	_box(rig, "OrangeBand", Vector3(8.1, 8.7, 2.6), Vector3(0.0, 0.0, -7.4), orange)
	_cab(rig, -16.3, 2.0, 7.0)
	for x: float in [-1.8, 1.6]:
		_box(rig, "RoofWindow", Vector3(2.2, 0.2, 2.6), Vector3(x, 4.35, -3.0), _paint(Color(0.12, 0.14, 0.2), null))
	# Scaffolding: orange decks and thin poles down the right flank.
	for deck in 2:
		_box(rig, "Deck", Vector3(1.0, 0.15, 5.0), Vector3(4.5, -2.0 + deck * 2.4, 0.5 + deck * 1.2), orange)
	for pole in 4:
		_box(rig, "Pole", Vector3(0.12, 5.0, 0.12), Vector3(4.95, -1.0, -1.5 + pole * 1.6), dark)
	# The engine block: narrower, ribbed, at the back.
	_loft(rig, "EngineBlock", Vector3(0.0, 0.0, 9.0), Vector2(6.4, 7.0), Vector3(0.0, 0.0, 14.5), Vector2(6.0, 6.6), gray, 0.2)
	for rib in 4:
		_box(rig, "Rib", Vector3(6.8, 7.4, 0.3), Vector3(0.0, 0.0, 10.0 + rib * 1.2), _paint(Color(0.45, 0.43, 0.42)))
	for spot: Vector2 in [Vector2(-1.6, -1.6), Vector2(1.6, -1.6), Vector2(-1.6, 1.6), Vector2(1.6, 1.6)]:
		_engine(rig, Vector3(spot.x, spot.y, 14.6), Vector2(2.2, 2.2), Color(1.0, 0.7, 0.35), 1.0, true)
	_flank_signs(rig, "STACK-SHIP\nCORP.", Color(0.4, 1.0, 0.45), 4.0, Vector3(0.0, 0.8, 3.0))
	_lights(rig, 4.6, 0.0, 12.0, Vector3(0.0, 4.6, -6.0))
	return rig


# --- BULK-ORE: the System Mining Guild hauler ----------------------------------
# Navy with orange bands, pincer prongs up front, an open ore bay in the
# middle heaped with rocks, little crane arms over it.

func _bulk_ore() -> Node3D:
	var rig := _rig("BulkOreVisual")
	var navy := _paint(Color(0.24, 0.32, 0.48))
	var orange := _paint(Color(0.95, 0.5, 0.16))
	var steel := _paint(Color(0.55, 0.53, 0.5))
	# Two pincer prongs at the front with the cab between them.
	for side: float in [-1.0, 1.0]:
		_loft(rig, "Prong", Vector3(2.6 * side, 0.0, -16.5), Vector2(2.6, 6.0), Vector3(2.6 * side, 0.0, -9.0), Vector2(3.2, 7.6), navy, 0.25)
		_box(rig, "ProngBand", Vector3(3.3, 7.7, 1.6), Vector3(2.6 * side, 0.0, -11.0), orange)
	_loft(rig, "CabBlock", Vector3(0.0, 0.0, -13.0), Vector2(3.0, 5.0), Vector3(0.0, 0.0, -9.0), Vector2(3.2, 6.0), navy)
	_cab(rig, -13.1, 1.4, 3.6)
	# The open bay: a floor, side rails, frames, and a heap of ore.
	_box(rig, "BayFloor", Vector3(8.0, 0.8, 9.0), Vector3(0.0, -3.0, -3.5), navy)
	for side: float in [-1.0, 1.0]:
		_box(rig, "BayRail", Vector3(0.8, 2.0, 9.0), Vector3(3.6 * side, -1.8, -3.5), navy)
	for z: float in [-8.4, 1.4]:
		_octagon_frame(rig, Vector2(8.6, 8.4), 1.0, z, steel)
	var ore := [Color(0.62, 0.52, 0.42), Color(0.45, 0.55, 0.62), Color(0.7, 0.58, 0.48)]
	for i in 7:
		_ball(rig, "Ore", 1.0 + (i % 3) * 0.35, Vector3(-2.4 + (i % 4) * 1.6, -1.8 + (i % 2) * 0.6, -7.0 + i * 1.1), _rock(ore[i % 3]))
	for z: float in [-6.0, -1.0]:
		_beam(rig, "CraneArm", Vector3(3.6, 4.0, z), Vector3(0.0, 2.2, z + 1.2), 0.25, orange)
	# The back half: the hull proper, banded, with two engines.
	_loft(rig, "Hull", Vector3(0.0, 0.0, 2.0), Vector2(7.8, 7.8), Vector3(0.0, 0.0, 14.2), Vector2(7.0, 7.0), navy)
	_box(rig, "BackBand", Vector3(7.9, 7.9, 1.2), Vector3(0.0, 0.0, 10.5), orange)
	_octagon_frame(rig, Vector2(8.6, 8.6), 1.0, 6.0, steel)
	for x: float in [-1.8, 1.8]:
		_engine(rig, Vector3(x, 0.0, 14.3), Vector2(2.6, 2.6), Color(1.0, 0.7, 0.3), 1.0, true)
	_flank_signs(rig, "SYSTEM MINING GUILD", Color(0.95, 0.95, 1.0), 3.9, Vector3(0.0, 1.2, 8.0), 0.008)
	_lights(rig, 4.0, 0.0, 12.5, Vector3(0.0, 4.1, 4.0))
	return rig


# --- TANKER: the cryo carrier --------------------------------------------------
# A frosty slab of a hull with two huge glowing ice-blue spheres set into
# its flanks, strapped in with riveted belts, a walkway, icicles under the
# belly, cyan neon "CRYO-LOGISTICS".

func _tanker() -> Node3D:
	var rig := _rig("TankerVisual")
	var frost := _paint(Color(0.72, 0.84, 0.88))
	var belt := _paint(Color(0.6, 0.46, 0.36))
	var ice := _glow(Color(0.65, 0.9, 1.0), 0.55, Color(0.7, 0.88, 1.0))
	_loft(rig, "Hull", Vector3(0.0, 0.0, -16.0), Vector2(6.0, 7.0), Vector3(0.0, 0.0, 12.0), Vector2(6.6, 8.6), frost, 0.15)
	_cab(rig, -16.1, 1.6, 5.0)
	for z: float in [-5.5, 3.0]:
		for side: float in [-1.0, 1.0]:
			_ball(rig, "CryoSphere", 3.6, Vector3(1.5 * side, 0.0, z), ice, Vector3(0.8, 1.0, 1.0))
		var strap := TorusMesh.new()
		strap.inner_radius = 3.65
		strap.outer_radius = 4.05
		strap.rings = 12
		strap.ring_segments = 4
		strap.material = belt
		_mesh(rig, "Strap", strap, Vector3(0.0, 0.0, z), Vector3(PI / 2.0, 0.0, 0.0))
	_box(rig, "Walkway", Vector3(7.8, 0.15, 18.0), Vector3(0.0, -1.2, -1.5), _paint(Color(0.4, 0.42, 0.46), null))
	for i in 9:
		_box(rig, "Icicle", Vector3(0.25, 0.8 + (i * 37) % 7 * 0.15, 0.25), Vector3(-2.2 + (i * 53) % 44 * 0.1, -4.3 - (i % 3) * 0.2, -12.0 + i * 2.6), _paint(Color(0.92, 0.97, 1.0), null))
	for y: float in [-1.8, 1.8]:
		_engine(rig, Vector3(0.0, y, 12.1), Vector2(3.0, 2.6), Color(0.6, 0.9, 1.0), 1.0, true)
	_flank_signs(rig, "CRYO-\nLOGISTICS", Color(0.45, 1.0, 0.95), 3.3, Vector3(0.0, 2.0, -12.0))
	_lights(rig, 3.4, 0.0, 10.0, Vector3(0.0, 4.4, -10.0))
	return rig


# --- CATAMARAN: the inter-system barge -----------------------------------------
# Two long octagonal hulls side by side, joined by a deck carrying a stack
# of colorful containers, a little cab hanging under the middle, purple trim.

func _catamaran() -> Node3D:
	var rig := _rig("CatamaranVisual")
	var gray := _paint(Color(0.6, 0.58, 0.62))
	var purple := _paint(Color(0.62, 0.42, 0.8))
	for side: float in [-1.0, 1.0]:
		var x := 4.6 * side
		_loft(rig, "Hull", Vector3(x, 0.0, -15.5), Vector2(4.0, 5.0), Vector3(x, 0.0, 13.0), Vector2(4.4, 5.6), gray, 0.25)
		_octagon_frame(rig, Vector2(4.8, 6.0), 1.0, -14.0, gray)
		_box(rig, "PurpleFrame", Vector3(4.6, 5.8, 1.0), Vector3(x, 0.0, 4.0), purple)
		_engine(rig, Vector3(x, 0.0, 13.1), Vector2(2.8, 3.2), Color(0.9, 0.55, 1.0), 1.0, true)
		_box(rig, "Window", Vector3(0.1, 0.6, 1.6), Vector3(x + 2.21 * side, 1.4, -8.0), _glow(Color(1.0, 0.82, 0.45), 1.2))
	# The middle deck and the container stack.
	_box(rig, "Deck", Vector3(5.4, 0.8, 16.0), Vector3(0.0, -2.2, -1.0), gray)
	var slot := 0
	for z: float in [-6.0, -1.0, 4.0]:
		for y: float in [-0.6, 1.6]:
			var paint := _paint(CONTAINER_COLORS[slot % CONTAINER_COLORS.size()], CONTAINER, Vector2(0.3, 0.33))
			_box(rig, "Container", Vector3(4.8, 2.1, 4.6), Vector3(0.0, y, z), paint)
			slot += 1
	# The little cab hanging under the front of the deck (somebody's in there).
	_box(rig, "Cab", Vector3(2.6, 2.0, 2.6), Vector3(0.0, -3.6, -8.5), gray)
	_box(rig, "CabWindow", Vector3(2.0, 0.8, 0.1), Vector3(0.0, -3.4, -9.85), _glow(GLASS, 1.0, Color(0.35, 0.2, 0.05)))
	_box(rig, "Chimney", Vector3(0.3, 1.2, 0.3), Vector3(0.8, -2.0, -8.0), _paint(Color(0.2, 0.2, 0.24), null))
	_cab(rig, -15.6, 1.2, 2.6)
	_flank_signs(rig, "INTER-SYSTEM\nBARGE", Color(1.0, 0.4, 0.9), 6.8, Vector3(0.0, 0.6, 9.0), 0.01)
	_lights(rig, 6.9, 0.0, 11.0, Vector3(0.0, 3.0, -2.0))
	return rig


# --- OMEGA ORE CRAWLER (Oreo class): the deluxe gray hauler ---------------------
# Like the Stack-Ship's big sister: warm gray, an orange band, octagon frames,
# and a long glowing ore slot down the flank with a mining arm working it.

func _omega_crawler() -> Node3D:
	var rig := _rig("OmegaCrawlerVisual")
	var gray := _paint(Color(0.62, 0.6, 0.6))
	var orange := _paint(Color(0.95, 0.5, 0.16))
	_loft(rig, "Hull", Vector3(0.0, 0.0, -12.5), Vector2(8.6, 9.0), Vector3(0.0, 0.0, 11.0), Vector2(8.6, 9.0), gray, 0.18)
	_octagon_frame(rig, Vector2(10.0, 10.4), 2.4, -15.4, gray)
	_octagon_frame(rig, Vector2(10.0, 10.4), 2.4, -12.0, gray)
	_box(rig, "OrangeBand", Vector3(8.7, 9.1, 2.4), Vector3(0.0, 0.0, -7.8), orange)
	_cab(rig, -16.7, 2.2, 7.4)
	# The ore slot: a long dark groove with a glow deep inside, both flanks.
	for side: float in [-1.0, 1.0]:
		_box(rig, "OreSlot", Vector3(0.3, 1.6, 14.0), Vector3(4.2 * side, -0.6, 2.0), _paint(Color(0.08, 0.07, 0.1), null))
		_box(rig, "SlotGlow", Vector3(0.1, 0.5, 13.0), Vector3(4.05 * side, -0.6, 2.0), _glow(Color(1.0, 0.65, 0.25), 1.2))
		_box(rig, "SlotLip", Vector3(0.6, 0.15, 14.4), Vector3(4.35 * side, -1.5, 2.0), orange)
	_beam(rig, "MiningArm", Vector3(4.4, -1.5, -2.0), Vector3(5.6, 0.4, 0.5), 0.3, _paint(Color(0.3, 0.3, 0.34), null))
	_loft(rig, "EngineBlock", Vector3(0.0, 0.0, 11.0), Vector2(7.0, 7.4), Vector3(0.0, 0.0, 15.4), Vector2(6.4, 7.0), gray, 0.2)
	for rib in 3:
		_box(rig, "Rib", Vector3(7.4, 7.8, 0.3), Vector3(0.0, 0.0, 12.0 + rib * 1.1), _paint(Color(0.45, 0.43, 0.42)))
	for spot: Vector2 in [Vector2(-1.7, -1.7), Vector2(1.7, -1.7), Vector2(-1.7, 1.7), Vector2(1.7, 1.7)]:
		_engine(rig, Vector3(spot.x, spot.y, 15.5), Vector2(2.4, 2.4), Color(1.0, 0.75, 0.4), 1.0, true)
	_flank_signs(rig, "SYSTEM MINING GUILD", Color(0.4, 1.0, 0.45), 4.3, Vector3(0.0, 2.6, 5.0), 0.009)
	_flank_signs(rig, "OMEGA ORE CRAWLER", Color(0.85, 0.85, 0.9), 4.3, Vector3(0.0, -2.6, 3.0), 0.006)
	_lights(rig, 4.9, 0.0, 13.0, Vector3(0.0, 4.8, -6.0))
	return rig


# --- ORE-CRAWLER: the mobile refinery --------------------------------------------
# Construction yellow, giant hazard-striped jaws open at the front with
# teeth (and a rock in its mouth), a gray body, two little cranes on top.

func _ore_crawler() -> Node3D:
	var rig := _rig("OreCrawlerVisual")
	var yellow := _paint(Color(1.0, 0.78, 0.16))
	var gray := _paint(Color(0.42, 0.42, 0.46))
	var hazard := _hazard(1.2)
	# The jaws: an upper and a lower half, open, with teeth.
	_box(rig, "UpperJaw", Vector3(8.4, 2.4, 7.0), Vector3(0.0, 3.0, -13.0), hazard)
	_box(rig, "LowerJaw", Vector3(8.4, 2.4, 7.0), Vector3(0.0, -3.0, -13.0), hazard)
	for i in 4:
		var x := -3.0 + i * 2.0
		_box(rig, "Tooth", Vector3(0.9, 0.9, 0.9), Vector3(x, 1.6, -16.0), _paint(Color(0.9, 0.9, 0.85), null)).rotation = Vector3(0.0, 0.0, PI / 4.0)
		_box(rig, "Tooth", Vector3(0.9, 0.9, 0.9), Vector3(x, -1.6, -16.0), _paint(Color(0.9, 0.9, 0.85), null)).rotation = Vector3(0.0, 0.0, PI / 4.0)
	_ball(rig, "MouthRock", 1.6, Vector3(0.6, 0.0, -12.5), _rock(Color(0.55, 0.48, 0.42)))
	_box(rig, "Throat", Vector3(7.0, 3.6, 2.0), Vector3(0.0, 0.0, -10.4), _paint(Color(0.12, 0.1, 0.12), null))
	_box(rig, "Collar", Vector3(8.8, 8.8, 3.0), Vector3(0.0, 0.0, -8.0), yellow)
	_loft(rig, "Body", Vector3(0.0, 0.0, -6.5), Vector2(7.6, 7.6), Vector3(0.0, 0.0, 13.0), Vector2(7.0, 7.0), gray)
	_cab(rig, -9.6, 4.4, 5.0)
	# Two cranes on top, one dangling a grabber.
	for crane_z: float in [-2.0, 6.0]:
		_box(rig, "CraneMast", Vector3(0.4, 4.0, 0.4), Vector3(2.0, 5.6, crane_z), yellow)
		_box(rig, "CraneJib", Vector3(0.4, 0.4, 6.0), Vector3(2.0, 7.6, crane_z - 2.4), yellow)
		_box(rig, "CraneCable", Vector3(0.08, 2.0, 0.08), Vector3(2.0, 6.6, crane_z - 5.2), _paint(Color(0.2, 0.2, 0.22), null))
	_box(rig, "Grabber", Vector3(0.9, 0.6, 0.9), Vector3(2.0, 5.4, 0.8), yellow)
	for x: float in [-2.0, 2.0]:
		_engine(rig, Vector3(x, 0.0, 13.1), Vector2(3.0, 3.0), Color(1.0, 0.8, 0.3), 1.0, true)
	_flank_signs(rig, "M  MINING GUILD", Color(1.0, 0.85, 0.3), 3.8, Vector3(0.0, 1.0, 3.0), 0.011)
	_lights(rig, 3.9, 0.0, 11.0, Vector3(0.0, 4.0, 10.0))
	return rig


# --- ICE-TUG: the comet harvester --------------------------------------------------
# Icy blue with black diagonal stripes, twin front pods, a tall cab tower on
# top with lit windows, a green neon "T".

func _ice_tug() -> Node3D:
	var rig := _rig("IceTugVisual")
	var ice := _paint(Color(0.55, 0.78, 0.95))
	var black := _paint(Color(0.12, 0.12, 0.16))
	for side: float in [-1.0, 1.0]:
		_loft(rig, "FrontPod", Vector3(2.0 * side, -0.8, -15.0), Vector2(3.2, 4.4), Vector3(2.0 * side, -0.4, -5.0), Vector2(3.8, 5.6), ice, 0.25)
	_loft(rig, "Hull", Vector3(0.0, 0.0, -6.0), Vector2(7.4, 7.0), Vector3(0.0, 0.0, 12.0), Vector2(6.6, 6.4), ice)
	for i in 3:
		var stripe := _box(rig, "Stripe", Vector3(7.6, 7.2, 1.0), Vector3(0.0, 0.0, -3.0 + i * 5.0), black)
		stripe.rotation = Vector3(0.35, 0.0, 0.0)
	# The cab tower.
	_box(rig, "Tower", Vector3(4.0, 2.6, 5.0), Vector3(0.0, 4.6, -2.0), ice)
	_box(rig, "TowerWindows", Vector3(4.05, 0.8, 2.4), Vector3(0.0, 5.0, -3.4), _glow(GLASS, 1.0, Color(0.35, 0.2, 0.05)))
	_box(rig, "TowerTop", Vector3(2.2, 1.0, 2.4), Vector3(0.0, 6.4, -1.4), ice)
	_cylinder(rig, "Mast", 0.08, 2.4, Vector3(0.6, 8.0, -1.0), black, Vector3.ZERO, 5)
	_cab(rig, -15.1, 0.6, 3.0)
	for x: float in [-1.7, 1.7]:
		_engine(rig, Vector3(x, -0.6, 12.1), Vector2(2.6, 2.8), Color(0.5, 0.9, 1.0), 1.0, true)
	_flank_signs(rig, "T  TIDEWATER\n   CANNERY", Color(0.4, 1.0, 0.5), 3.5, Vector3(0.0, 0.2, 5.0), 0.01)
	_lights(rig, 3.7, 0.0, 10.0, Vector3(0.0, 7.1, -1.4))
	return rig


# --- HAB-BRICK: the colony block -----------------------------------------------------
# A long red-brown block with rows of little lit window strips, teal octagon
# frames, and a glowing green garden deck along its waist.

func _hab_brick() -> Node3D:
	var rig := _rig("HabBrickVisual")
	var brick := _paint(Color(0.6, 0.3, 0.22))
	var teal := _paint(Color(0.3, 0.62, 0.62))
	_loft(rig, "Hull", Vector3(0.0, 0.0, -16.0), Vector2(7.6, 7.6), Vector3(0.0, 0.0, 13.0), Vector2(7.6, 7.6), brick, 0.2)
	for z: float in [-12.0, -3.0, 6.0]:
		_octagon_frame(rig, Vector2(8.8, 8.8), 1.2, z, teal)
	var lit: Array[Color] = [Color(1.0, 0.82, 0.45), Color(0.5, 1.0, 0.9), Color(1.0, 0.55, 0.75)]
	for side: float in [-1.0, 1.0]:
		for column in 14:
			var z := -14.5 + column * 2.0
			if absf(z + 3.0) < 1.0 or absf(z - 6.0) < 1.0 or absf(z + 12.0) < 1.0:
				continue
			for row: float in [-1.6, 1.8]:
				_box(rig, "WindowStrip", Vector3(0.1, 1.6, 0.35), Vector3(side * 3.81, row, z), _glow(lit[(column + int(row)) % lit.size()], 1.2))
	_box(rig, "GardenDeck", Vector3(7.7, 0.9, 6.0), Vector3(0.0, 0.1, 1.5), _glow(Color(0.4, 0.9, 0.4), 0.6))
	_cab(rig, -16.1, 1.8, 6.0)
	for spot: Vector2 in [Vector2(-1.8, -1.8), Vector2(1.8, -1.8), Vector2(-1.8, 1.8), Vector2(1.8, 1.8)]:
		_engine(rig, Vector3(spot.x, spot.y, 13.1), Vector2(2.2, 2.2), Color(1.0, 0.6, 0.4), 1.0, true)
	_flank_signs(rig, "COLONY\nMANAGEMENT CORP.", Color(0.6, 1.0, 1.0), 3.8, Vector3(0.0, 0.0, 10.0), 0.008)
	_lights(rig, 4.4, 0.0, 12.0, Vector3(0.0, 4.4, -8.0))
	return rig


# --- GARBAGE SCOW: the debris collector -----------------------------------------
# An open, rusty frame heaped with junk, a grabber arm and a little cab at
# the back, a magenta neon "ORBITAL SANITATION" sign, and space gulls.

func _garbage_scow() -> Node3D:
	var rig := _rig("GarbageScowVisual")
	var rust := _paint(Color(0.45, 0.42, 0.3))
	var size := Vector3(8.0, 6.4, 22.0)
	var half := size * 0.5
	var middle := Vector3(0.0, 0.0, -3.0)
	# The frame: its long edges, then ribs every few meters.
	for x: float in [-half.x, half.x]:
		for y: float in [-half.y, half.y]:
			_box(rig, "Rail", Vector3(0.5, 0.5, size.z), middle + Vector3(x, y, 0.0), rust)
	for i in 6:
		var z := -half.z + i * size.z / 5.0
		_box(rig, "RibTop", Vector3(size.x, 0.4, 0.4), middle + Vector3(0.0, half.y, z), rust)
		_box(rig, "RibLeft", Vector3(0.4, size.y, 0.4), middle + Vector3(-half.x, 0.0, z), rust)
		_box(rig, "RibRight", Vector3(0.4, size.y, 0.4), middle + Vector3(half.x, 0.0, z), rust)
	_box(rig, "Floor", Vector3(size.x, 0.4, size.z), middle + Vector3(0.0, -half.y, 0.0), rust)
	_loft(rig, "Bow", Vector3(0.0, -0.5, -16.5), Vector2(5.0, 4.0), Vector3(0.0, 0.0, -14.0), Vector2(8.4, 6.8), rust)
	# The junk heap.
	var junk: Array[Color] = [Color(0.5, 0.45, 0.4), Color(0.35, 0.45, 0.4), Color(0.6, 0.35, 0.3), Color(0.5, 0.5, 0.55)]
	for i in 12:
		var spot := middle + Vector3(-2.6 + (i * 37) % 52 * 0.1, -2.2 + (i % 3) * 0.7, -9.0 + i * 1.5)
		if i % 3 == 0:
			_ball(rig, "Junk", 0.8 + (i % 2) * 0.4, spot, _rock(junk[i % junk.size()]))
		else:
			var piece := _box(rig, "Junk", Vector3(1.2 + (i % 3) * 0.4, 0.8 + (i % 2) * 0.5, 1.4), spot, _paint(junk[i % junk.size()], CONTAINER, Vector2(0.3, 0.33)))
			piece.rotation = Vector3(0.2 * (i % 3), 0.5 * i, 0.0)
	# The cab and engine block at the back, and the grabber arm.
	_loft(rig, "Stern", Vector3(0.0, 0.0, 8.0), Vector2(7.6, 6.6), Vector3(0.0, 0.0, 13.0), Vector2(7.0, 6.0), rust)
	_box(rig, "Cab", Vector3(3.0, 2.2, 3.0), Vector3(0.0, 4.4, 10.0), rust)
	_box(rig, "CabWindow", Vector3(2.6, 0.8, 0.1), Vector3(0.0, 4.6, 8.45), _glow(GLASS, 1.0, Color(0.35, 0.2, 0.05)))
	_beam(rig, "Boom", Vector3(0.0, 5.2, 9.0), Vector3(1.0, 8.0, 3.0), 0.4, _paint(Color(0.85, 0.65, 0.2)))
	_beam(rig, "Stick", Vector3(1.0, 8.0, 3.0), Vector3(1.4, 5.0, -1.0), 0.35, _paint(Color(0.85, 0.65, 0.2)))
	_box(rig, "Bucket", Vector3(1.4, 1.0, 1.2), Vector3(1.4, 4.6, -1.4), _paint(Color(0.85, 0.65, 0.2)))
	for i in 5:
		_box(rig, "SpaceGull", Vector3(0.7, 0.1, 0.25), Vector3(-2.0 + i * 1.1, 7.5 + (i % 2) * 1.2, 4.0 + (i % 3) * 1.5), _paint(Color(0.95, 0.95, 0.95), null))
	for x: float in [-2.0, 2.0]:
		_engine(rig, Vector3(x, 0.0, 13.1), Vector2(2.6, 2.6), Color(0.9, 0.5, 1.0), 1.0, true)
	_flank_signs(rig, "ORBITAL\nSANITATION", Color(1.0, 0.4, 0.85), 4.35, Vector3(0.0, 0.6, 10.8), 0.009)
	_lights(rig, 4.3, 0.0, 12.0, Vector3(0.0, 5.7, 10.0))
	return rig
