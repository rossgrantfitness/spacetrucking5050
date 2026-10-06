extends "res://tools/build_placeholder_models.gd"
## Builds the big things out in space that aren't ships:
##     res://scenes/flight/BaseStation.tscn     - the home base, a huge old starship
##     res://scenes/flight/CanneryStation.tscn  - Tidewater Cannery, far out in
##                                                the teal Tidewater system
##     res://scenes/flight/GasNGo.tscn          - Gas-N-Go 47, a little
##                                                drive-through fuel stop in space
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_world.gd
##
## Every station's docking bay faces its local +Z, like the truck stop's
## (rotate the place in the flight scene to aim it).
##
## Careful: running it again OVERWRITES those scenes. It borrows the shape and
## material helpers from build_placeholder_models.gd.


const BASE_SCRIPT_PATH := "res://scenes/flight/BaseStation.gd"


func _initialize() -> void:
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_save(_build_base(), "res://scenes/flight/BaseStation.tscn")
	_save(_build_cannery(), "res://scenes/flight/CanneryStation.tscn")
	_save(_build_gas_n_go(), "res://scenes/flight/GasNGo.tscn")
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
	# (No names painted on the station: the HUD's green ID label names it.)

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


# --- Tidewater Cannery -------------------------------------------------------------
# A fish cannery in the teal Tidewater system: a cluster of big silos, a
# smokestack, conveyor arms reaching out to the trawlers, stacks of crates,
# and a giant neon fish over the docking bay (which faces +Z).

func _build_cannery() -> Node3D:
	var cannery := Node3D.new()
	cannery.name = "CanneryStation"
	var body := StaticBody3D.new()
	body.name = "Collision"
	cannery.add_child(body, true)
	var white := _paint(Color(0.86, 0.9, 0.9), HULL, Vector2(10.0, 6.0), false)
	var teal := _paint(Color(0.2, 0.7, 0.68), HULL, Vector2(10.0, 2.0), false)
	var rust := _paint(Color(0.7, 0.38, 0.25), HULL, Vector2(0.05, 0.05))
	var dark := _paint(Color(0.12, 0.14, 0.18), HULL, Vector2(0.05, 0.05))

	# The main hall: a long chunky box with a docking bay in front.
	_add_collision(body, _box(cannery, "Hall", Vector3(320.0, 160.0, 260.0), Vector3(0.0, 0.0, -20.0), white))
	_box(cannery, "HallStripe", Vector3(324.0, 24.0, 264.0), Vector3(0.0, 40.0, -20.0), teal)
	_add_collision(body, _cylinder(cannery, "DockingFace", 56.0, 8.0, Vector3(0.0, 0.0, 113.0), dark, ALONG_Z, 16))
	var bay_light := TorusMesh.new()
	bay_light.inner_radius = 30.0
	bay_light.outer_radius = 38.0
	bay_light.rings = 24
	bay_light.ring_segments = 6
	bay_light.material = _glow(Color(0.35, 1.0, 0.85), 1.6)
	_mesh(cannery, "DockingLights", bay_light, Vector3(0.0, 0.0, 118.0), ALONG_Z)
	for x: float in [-160.0, 160.0]:
		_box(cannery, "Windows", Vector3(4.0, 40.0, 220.0), Vector3(x, -30.0, -20.0), _windows(Vector2(1.0, 14.0)))

	# Silos behind and above, like a cluster of giant tin cans.
	for silo: Array in [[Vector3(-90.0, 150.0, -60.0), 55.0, 220.0], [Vector3(20.0, 170.0, -90.0), 65.0, 260.0], [Vector3(120.0, 140.0, -50.0), 50.0, 200.0]]:
		_add_collision(body, _cylinder(cannery, "Silo", silo[1], silo[2], silo[0], white, Vector3.ZERO, 14))
		_cylinder(cannery, "SiloBand", silo[1] + 2.0, 14.0, silo[0] + Vector3(0.0, silo[2] * 0.3, 0.0), teal, Vector3.ZERO, 14)
		_cylinder(cannery, "SiloCap", silo[1] * 0.6, 16.0, silo[0] + Vector3(0.0, silo[2] * 0.5 + 8.0, 0.0), rust, Vector3.ZERO, 10)
	_add_collision(body, _cylinder(cannery, "Smokestack", 18.0, 260.0, Vector3(-150.0, 180.0, -110.0), rust, Vector3.ZERO, 10))
	var steam := _box(cannery, "SmokestackGlow", Vector3(30.0, 6.0, 30.0), Vector3(-150.0, 312.0, -110.0), _glow(Color(1.0, 0.6, 0.3), 1.8))
	steam.set_script(_blinker_script)

	# Conveyor arms reaching out sideways, with crates riding them.
	for side: float in [-1.0, 1.0]:
		var arm := _box(cannery, "ConveyorArm", Vector3(360.0, 14.0, 24.0), Vector3(side * 340.0, -40.0, 30.0), _hazard(0.06))
		_add_collision(body, arm)
		for i in 6:
			var color: Color = CONTAINER_COLORS[(i + int(side + 1.0)) % CONTAINER_COLORS.size()]
			_box(cannery, "ConveyorCrate", Vector3(24.0, 18.0, 20.0), Vector3(side * (200.0 + i * 50.0), -24.0, 30.0), _paint(color, CONTAINER, Vector2(0.06, 0.06)))
		var beacon := _box(cannery, "Beacon", Vector3(12.0, 12.0, 12.0), Vector3(side * 525.0, -40.0, 30.0), _glow(Color(1.0, 0.3, 0.2), 1.8))
		beacon.set_script(_blinker_script)
	# Stacks of crates on the roof.
	for i in 8:
		var color: Color = CONTAINER_COLORS[i % CONTAINER_COLORS.size()]
		_box(cannery, "RoofCrate", Vector3(40.0, 26.0, 30.0), Vector3(-120.0 + (i % 4) * 70.0, 93.0 + floorf(i / 4.0) * 26.0, 70.0), _paint(color, CONTAINER, Vector2(0.04, 0.04)))

	# The giant neon fish over the bay, and the sign.
	var fish := Node3D.new()
	fish.name = "NeonFish"
	fish.position = Vector3(0.0, 140.0, 110.0)
	cannery.add_child(fish, true)
	var fish_glow := _glow(Color(1.0, 0.55, 0.75), 2.0)
	_box(fish, "Body", Vector3(140.0, 50.0, 6.0), Vector3.ZERO, fish_glow).rotation = Vector3(0.0, 0.0, 0.0)
	var tail_top := _box(fish, "TailTop", Vector3(50.0, 14.0, 6.0), Vector3(-88.0, 16.0, 0.0), fish_glow)
	tail_top.rotation = Vector3(0.0, 0.0, 0.6)
	var tail_bottom := _box(fish, "TailBottom", Vector3(50.0, 14.0, 6.0), Vector3(-88.0, -16.0, 0.0), fish_glow)
	tail_bottom.rotation = Vector3(0.0, 0.0, -0.6)
	_box(fish, "Eye", Vector3(10.0, 10.0, 8.0), Vector3(48.0, 8.0, 0.0), _glow(Color(0.35, 1.0, 0.85), 2.4))
	# (No names painted on the station: the HUD's green ID label names it.)
	return cannery


# --- Gas-N-Go 47 ------------------------------------------------------------------
# A little drive-through fuel stop floating in the middle of nowhere: a
# flat platform with a lit canopy on pillars, two giant retro pumps, a
# kiosk, and a tall pole sign. You fly in under the canopy from +Z and out
# the far side.

func _build_gas_n_go() -> Node3D:
	var stop := Node3D.new()
	stop.name = "GasNGo"
	var body := StaticBody3D.new()
	body.name = "Collision"
	stop.add_child(body, true)
	var red := _paint(Color(0.92, 0.25, 0.25), HULL, Vector2(0.05, 0.05))
	var white := _paint(Color(0.92, 0.92, 0.88), HULL, Vector2(0.05, 0.05))
	var dark := _paint(Color(0.15, 0.15, 0.2), HULL, Vector2(0.05, 0.05))

	# The platform, with a road-like stripe down the middle.
	_add_collision(body, _box(stop, "Platform", Vector3(220.0, 12.0, 160.0), Vector3(0.0, -40.0, 0.0), dark))
	for i in 6:
		_box(stop, "LaneDash", Vector3(6.0, 1.0, 14.0), Vector3(0.0, -33.5, -70.0 + i * 28.0), _glow(Color(1.0, 0.85, 0.3), 1.2))
	# The canopy on four pillars, glowing underneath.
	_add_collision(body, _box(stop, "Canopy", Vector3(200.0, 10.0, 120.0), Vector3(0.0, 60.0, 0.0), red))
	_box(stop, "CanopyGlow", Vector3(190.0, 1.0, 110.0), Vector3(0.0, 54.5, 0.0), _glow(Color(1.0, 0.95, 0.85), 1.6))
	_box(stop, "CanopyStripe", Vector3(204.0, 4.0, 124.0), Vector3(0.0, 64.0, 0.0), white)
	for pillar: Vector3 in [Vector3(-90.0, 10.0, -50.0), Vector3(90.0, 10.0, -50.0), Vector3(-90.0, 10.0, 50.0), Vector3(90.0, 10.0, 50.0)]:
		_add_collision(body, _box(stop, "Pillar", Vector3(8.0, 90.0, 8.0), pillar, white))
	# Two giant retro pumps either side of the lane.
	for side: float in [-1.0, 1.0]:
		_add_collision(body, _box(stop, "Pump", Vector3(20.0, 40.0, 14.0), Vector3(side * 45.0, -14.0, 0.0), red))
		_box(stop, "PumpScreen", Vector3(14.0, 10.0, 1.0), Vector3(side * 45.0, -6.0, 7.6), _glow(Color(0.5, 1.0, 0.6), 1.8))
		_box(stop, "PumpTop", Vector3(22.0, 8.0, 16.0), Vector3(side * 45.0, 10.0, 0.0), _glow(Color(1.0, 0.95, 0.8), 1.2))
	# The kiosk to one side, windows lit.
	_add_collision(body, _box(stop, "Kiosk", Vector3(50.0, 30.0, 40.0), Vector3(75.0, -19.0, -40.0), white))
	_box(stop, "KioskWindows", Vector3(46.0, 10.0, 1.0), Vector3(75.0, -16.0, -19.5), _glow(Color(1.0, 0.85, 0.5), 1.5))
	# The tall pole sign, readable from far away.
	_add_collision(body, _box(stop, "SignPole", Vector3(8.0, 200.0, 8.0), Vector3(-130.0, 60.0, 0.0), white))
	_box(stop, "SignBoard", Vector3(130.0, 60.0, 6.0), Vector3(-130.0, 180.0, 0.0), dark)
	# (No names painted on the station: the HUD's green ID label names it.)
	var beacon := _box(stop, "Beacon", Vector3(10.0, 10.0, 10.0), Vector3(-130.0, 216.0, 0.0), _glow(Color(1.0, 0.3, 0.2), 2.0))
	beacon.set_script(_blinker_script)
	return stop
