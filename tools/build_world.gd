extends "res://tools/build_placeholder_models.gd"
## Builds the big things out in space that aren't ships:
##     res://scenes/flight/BaseStation.tscn  - the home base, a huge old starship
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_world.gd
##
## Careful: running it again OVERWRITES that scene. It borrows the shape and
## material helpers from build_placeholder_models.gd.


const BASE_SCRIPT_PATH := "res://scenes/flight/BaseStation.gd"


func _initialize() -> void:
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_save(_build_base(), "res://scenes/flight/BaseStation.tscn")
	quit()


# --- The home base -----------------------------------------------------------------
# A long, chunky starship about 1.6 km from nose to engines. The hangar
# mouth is on the front face (local -Z, at z = 0) and the hull runs back
# along +Z. Rows of lit windows (250 neighbors), a slowly spinning habitat
# ring, a bridge tower, antennas, and big warm engines at the back.

func _build_base() -> Node3D:
	var base := Node3D.new()
	base.name = "BaseStation"
	base.set_script(load(BASE_SCRIPT_PATH))
	var body := StaticBody3D.new()
	body.name = "Collision"
	base.add_child(body, true)

	var hull := _paint(Color(0.62, 0.66, 0.78), HULL, Vector2(24.0, 12.0), false)
	var trim := _paint(Color(0.85, 0.55, 0.3), HULL, Vector2(24.0, 2.0), false)
	var dark := _paint(Color(0.12, 0.12, 0.18), HULL, Vector2(0.05, 0.05))
	var strut := _paint(Color(0.45, 0.42, 0.55), HULL, Vector2(0.05, 0.05))
	var length := 1600.0
	var mid := length * 0.5

	# The main hull, with the hangar mouth cut into the front: the front
	# face is four slabs around a 180 x 100 m opening.
	_add_collision(body, _box(base, "HullMain", Vector3(420.0, 240.0, length - 140.0), Vector3(0.0, 0.0, mid + 70.0), hull))
	for slab: Array in [
			[Vector3(420.0, 70.0, 140.0), Vector3(0.0, 85.0, 70.0)],
			[Vector3(420.0, 70.0, 140.0), Vector3(0.0, -85.0, 70.0)],
			[Vector3(120.0, 100.0, 140.0), Vector3(-150.0, 0.0, 70.0)],
			[Vector3(120.0, 100.0, 140.0), Vector3(150.0, 0.0, 70.0)]]:
		_add_collision(body, _box(base, "HullFront", slab[0], slab[1], hull))
	# The hangar inside: dark, with landing lights down the floor.
	_box(base, "HangarBack", Vector3(180.0, 100.0, 4.0), Vector3(0.0, 0.0, 138.0), dark)
	_box(base, "HangarFloor", Vector3(180.0, 4.0, 140.0), Vector3(0.0, -48.0, 70.0), dark)
	for i in 6:
		for side: float in [-1.0, 1.0]:
			_box(base, "LandingLight", Vector3(6.0, 2.0, 6.0), Vector3(60.0 * side, -45.0, 10.0 + i * 22.0), _glow(Color(1.0, 0.75, 0.3), 2.0))
	# A glowing frame and hazard stripes around the hangar mouth.
	var frame_glow := _glow(Color(0.35, 0.95, 1.0), 1.6)
	for part: Array in [
			[Vector3(196.0, 6.0, 6.0), Vector3(0.0, 53.0, -2.0)],
			[Vector3(196.0, 6.0, 6.0), Vector3(0.0, -53.0, -2.0)],
			[Vector3(6.0, 112.0, 6.0), Vector3(-95.0, 0.0, -2.0)],
			[Vector3(6.0, 112.0, 6.0), Vector3(95.0, 0.0, -2.0)]]:
		_box(base, "HangarFrame", part[0], part[1], frame_glow)
	var hazard := _hazard(0.05)
	_box(base, "HazardTop", Vector3(260.0, 14.0, 4.0), Vector3(0.0, 70.0, -2.0), hazard)
	_box(base, "HazardBottom", Vector3(260.0, 14.0, 4.0), Vector3(0.0, -70.0, -2.0), hazard)
	_sign(base, "HangarSign", "HANGAR 7 - WELCOME HOME", 0.3, Color(0.45, 0.95, 1.0), Vector3(0.0, 95.0, -3.0))
	(base.get_node("HangarSign") as Node3D).rotation = Vector3(0.0, PI, 0.0)  # Signs read from their +Z side.
	var name_sign := Label3D.new()
	name_sign.name = "NameSign"
	name_sign.text = "[BASE_NAME]"
	name_sign.font_size = 96
	name_sign.pixel_size = 0.8
	name_sign.outline_size = 16
	name_sign.modulate = Color(1.0, 0.8, 0.35)
	name_sign.outline_modulate = Color(0.25, 0.05, 0.3)
	name_sign.position = Vector3(0.0, 160.0, 40.0)
	name_sign.rotation = Vector3(0.0, PI, 0.0)
	base.add_child(name_sign, true)
	var side_sign := name_sign.duplicate() as Label3D
	side_sign.name = "NameSignSide"
	side_sign.position = Vector3(-212.0, 40.0, 560.0)
	side_sign.rotation = Vector3(0.0, -PI / 2.0, 0.0)
	side_sign.pixel_size = 1.4
	base.add_child(side_sign, true)

	# Bands of trim and rows of windows along both sides: 250 neighbors.
	for band_z: float in [240.0, 700.0, 1150.0]:
		_box(base, "TrimBand", Vector3(426.0, 246.0, 24.0), Vector3(0.0, 0.0, band_z), trim)
	for side: float in [-1.0, 1.0]:
		for row: float in [-60.0, 0.0, 60.0]:
			_box(base, "WindowRow", Vector3(4.0, 30.0, 1100.0), Vector3(211.0 * side, row, 760.0), _windows(Vector2(1.0, 60.0)))
	for x: float in [-120.0, 0.0, 120.0]:
		_box(base, "RoofWindows", Vector3(60.0, 4.0, 900.0), Vector3(x, 121.0, 800.0), _windows(Vector2(4.0, 50.0)))

	# The bridge tower on top, with antennas and blinking beacons.
	_add_collision(body, _box(base, "BridgeTower", Vector3(140.0, 160.0, 220.0), Vector3(0.0, 200.0, 1250.0), hull))
	_box(base, "BridgeWindows", Vector3(144.0, 24.0, 4.0), Vector3(0.0, 240.0, 1138.0), _glow(Color(0.5, 0.9, 1.0), 1.4))
	for antenna: Array in [[Vector3(-40.0, 300.0, 1250.0), 120.0], [Vector3(30.0, 330.0, 1290.0), 180.0], [Vector3(60.0, 290.0, 1200.0), 90.0]]:
		_box(base, "Antenna", Vector3(6.0, antenna[1], 6.0), antenna[0], strut)
		var beacon := _box(base, "Beacon", Vector3(12.0, 12.0, 12.0), antenna[0] + Vector3(0.0, antenna[1] * 0.5 + 6.0, 0.0), _glow(Color(1.0, 0.2, 0.2), 1.8))
		beacon.set_script(_blinker_script)
		beacon.set("offset", randf())

	# The habitat ring: a big slowly turning wheel of windows around the
	# middle (BaseStation.gd spins it).
	var ring := Node3D.new()
	ring.name = "HabitatRing"
	ring.position = Vector3(0.0, 0.0, 900.0)
	base.add_child(ring, true)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 430.0
	ring_mesh.outer_radius = 500.0
	ring_mesh.rings = 40
	ring_mesh.ring_segments = 8
	ring_mesh.material = _windows(Vector2(32.0, 1.5))
	_mesh(ring, "Wheel", ring_mesh, Vector3.ZERO, ALONG_Z)
	for i in 6:
		var angle := i * TAU / 6.0
		var spoke := _box(ring, "Spoke", Vector3(20.0, 250.0, 20.0), Vector3(cos(angle), sin(angle), 0.0) * 330.0, strut)
		spoke.rotation = Vector3(0.0, 0.0, angle - PI / 2.0)
	# The wheel's collision doesn't turn (a ring looks the same as it spins).
	var ring_body := StaticBody3D.new()
	ring_body.name = "RingCollision"
	ring_body.position = ring.position
	base.add_child(ring_body, true)
	_add_ring_collision(ring_body, 465.0, 35.0, 32)

	# Big warm engines at the back, glowing even when parked.
	for engine: Vector3 in [Vector3(-130.0, -60.0, length), Vector3(130.0, -60.0, length), Vector3(-130.0, 60.0, length), Vector3(130.0, 60.0, length)]:
		_cylinder(base, "EngineBell", 70.0, 80.0, engine + Vector3(0.0, 0.0, 30.0), dark, ALONG_Z, 12)
		_cylinder(base, "EngineGlow", 55.0, 4.0, engine + Vector3(0.0, 0.0, 72.0), _glow(Color(1.0, 0.55, 0.25), 2.2), ALONG_Z, 12)

	# Cargo pods clamped along the belly.
	for i in 5:
		var color: Color = CONTAINER_COLORS[i % CONTAINER_COLORS.size()]
		_box(base, "CargoPod", Vector3(80.0, 50.0, 140.0), Vector3(-100.0 + (i % 2) * 200.0, -145.0, 350.0 + i * 220.0), _paint(color, CONTAINER, Vector2(0.03, 0.03)))
	return base
