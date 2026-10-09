extends "res://tools/build_placeholder_models.gd"
## Builds the stations of the three far systems, as seen from space:
##     res://scenes/flight/SalvageYardStation.tscn - Hoof & Hull Salvage, the
##         Dustbowl: a dead freighter hollowed out into a scrapyard, a crane
##         with a big magnet, scrap piles, amber floodlights
##     res://scenes/flight/ArboretumStation.tscn   - The Orbital Arboretum,
##         Greenhouse Reach: a glass dome on a garden disk with one huge
##         tree inside, hanging garden pods all around
##     res://scenes/flight/CreameryStation.tscn    - Flurry's Comet Creamery,
##         the Frostline: an ice-cream parlor built on a comet, a striped
##         awning, icicles, and a giant cone on a mast
##
## Like every station, the docking bay faces +Z (DockingFace at z = 182), so
## the place's node in FlightSandbox.tscn aims it. Keep everything out of the
## approach lane (x and y near 0, z from 190 to 800).
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_frontier_stations.gd
##
## Careful: running it again OVERWRITES those scenes. It borrows the shape and
## material helpers from build_placeholder_models.gd.


const ROCK := preload("res://textures/generated/rock.png")
const SPINNER_PATH := "res://scenes/common/Spinner.gd"


func _initialize() -> void:
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_save(_salvage_yard(), "res://scenes/flight/SalvageYardStation.tscn")
	_save(_arboretum(), "res://scenes/flight/ArboretumStation.tscn")
	_save(_creamery(), "res://scenes/flight/CreameryStation.tscn")
	quit()


## A new station root with its collision body.
func _station(node_name: String) -> Array:
	var station := Node3D.new()
	station.name = node_name
	var body := StaticBody3D.new()
	body.name = "Collision"
	station.add_child(body, true)
	return [station, body]


## The docking bay every station shares: a block with a dark round face and a
## ring of lights, facing +Z, and a little canopy of bulbs.
func _bay(station: Node3D, body: StaticBody3D, block: Material, light: Color, canopy: Material) -> void:
	_add_collision(body, _box(station, "BayBlock", Vector3(200.0, 150.0, 120.0), Vector3(0.0, 0.0, 120.0), block))
	_add_collision(body, _cylinder(station, "DockingFace", 56.0, 8.0, Vector3(0.0, 0.0, 182.0), _paint(Color(0.1, 0.09, 0.12), HULL, Vector2(0.05, 0.05)), ALONG_Z, 16))
	var ring := TorusMesh.new()
	ring.inner_radius = 30.0
	ring.outer_radius = 38.0
	ring.rings = 24
	ring.ring_segments = 6
	ring.material = _glow(light, 1.8)
	_mesh(station, "DockingLights", ring, Vector3(0.0, 0.0, 187.0), ALONG_Z)
	_box(station, "BayCanopy", Vector3(220.0, 12.0, 60.0), Vector3(0.0, 82.0, 160.0), canopy)
	for i in 7:
		var bulb := _box(station, "CanopyBulb", Vector3(10.0, 10.0, 10.0), Vector3(-90.0 + i * 30.0, 74.0, 190.0), _glow(light.lightened(0.3), 2.2))
		if i % 2 == 0:
			bulb.set_script(_blinker_script)


## A ball (with a ball-shaped collision when `body` is given).
func _ball(parent: Node3D, body: StaticBody3D, node_name: String, radius: float, where: Vector3, material: Material, stretch := Vector3.ONE) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	sphere.material = material
	var part := _mesh(parent, node_name, sphere, where)
	part.scale = stretch
	if body != null:
		var collision := CollisionShape3D.new()
		collision.name = node_name + "Shape"
		var shape := SphereShape3D.new()
		shape.radius = radius * minf(stretch.x, minf(stretch.y, stretch.z))
		collision.shape = shape
		collision.position = where
		body.add_child(collision, true)
	return part


# --- Hoof & Hull Salvage -------------------------------------------------------------------

func _salvage_yard() -> Node3D:
	var parts := _station("SalvageYardStation")
	var yard: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var rust := _paint(Color(0.62, 0.36, 0.22), HULL, Vector2(0.05, 0.05))
	var steel := _paint(Color(0.55, 0.52, 0.48), HULL, Vector2(0.05, 0.05))
	var amber := Color(1.0, 0.65, 0.25)
	var yellow := _paint(Color(0.95, 0.75, 0.2), null)
	_bay(yard, body, steel, amber, rust)

	# The dead freighter: a long hull, split open along the top, with its
	# ribs showing where the plating's been stripped.
	_add_collision(body, _box(yard, "HullFloor", Vector3(300.0, 40.0, 700.0), Vector3(0.0, -60.0, -260.0), rust))
	for side: float in [-1.0, 1.0]:
		_add_collision(body, _box(yard, "HullSide", Vector3(30.0, 180.0, 700.0), Vector3(side * 150.0, 30.0, -260.0), rust))
		for i in 7:
			var rib := _box(yard, "Rib", Vector3(20.0, 20.0, 20.0), Vector3(side * 100.0, 140.0, -560.0 + i * 90.0), steel)
			rib.scale = Vector3(5.0, 1.0, 1.0)
			rib.rotation = Vector3(0.0, 0.0, -0.5 * side)
	_box(yard, "Stern", Vector3(300.0, 220.0, 40.0), Vector3(0.0, 10.0, -620.0), rust)
	_box(yard, "Name", Vector3(200.0, 24.0, 4.0), Vector3(0.0, 90.0, -598.0), _glow(amber, 1.0))
	# Scrap piles inside the hull: lumps of junk in faded colors.
	var junk_colors: Array[Color] = [Color(0.4, 0.5, 0.6), Color(0.75, 0.3, 0.25), Color(0.85, 0.8, 0.6), Color(0.3, 0.45, 0.35), Color(0.6, 0.55, 0.5)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 26:
		var size := Vector3(rng.randf_range(20.0, 60.0), rng.randf_range(15.0, 45.0), rng.randf_range(20.0, 60.0))
		var lump := _box(yard, "Scrap", size, Vector3(rng.randf_range(-110.0, 110.0), -30.0 + size.y * 0.5, rng.randf_range(-560.0, -80.0)), _paint(junk_colors[i % junk_colors.size()], HULL, Vector2(0.05, 0.05)))
		lump.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))
	# The crane: a mast, a boom swinging slowly, and a big magnet on a cable.
	_add_collision(body, _box(yard, "CraneMast", Vector3(30.0, 320.0, 30.0), Vector3(-200.0, 100.0, -300.0), yellow))
	var boom := Node3D.new()
	boom.name = "CraneBoom"
	boom.position = Vector3(-200.0, 260.0, -300.0)
	boom.set_script(load(SPINNER_PATH))
	boom.set("speed", 0.04)
	yard.add_child(boom, true)
	_box(boom, "Boom", Vector3(320.0, 18.0, 18.0), Vector3(140.0, 0.0, 0.0), yellow)
	_box(boom, "Counterweight", Vector3(50.0, 40.0, 40.0), Vector3(-40.0, 0.0, 0.0), steel)
	_beam(boom, "Cable", Vector3(280.0, 0.0, 0.0), Vector3(280.0, -120.0, 0.0), 2.0, steel)
	_cylinder(boom, "Magnet", 40.0, 16.0, Vector3(280.0, -128.0, 0.0), _paint(Color(0.8, 0.15, 0.15), null), Vector3.ZERO, 12)
	var crane_light := _box(boom, "CraneLight", Vector3(10.0, 10.0, 10.0), Vector3(300.0, 12.0, 0.0), _glow(Color(1.0, 0.3, 0.2), 2.4))
	crane_light.set_script(_blinker_script)
	# Amber floodlights on tall poles, and a hazard band around the bay.
	for spot: Vector3 in [Vector3(160.0, 150.0, -40.0), Vector3(-160.0, 150.0, -40.0), Vector3(160.0, 150.0, -480.0)]:
		_beam(yard, "LightPole", spot - Vector3(0.0, 120.0, 0.0), spot, 4.0, steel)
		_box(yard, "Floodlight", Vector3(24.0, 14.0, 14.0), spot, _glow(amber, 2.4))
	_box(yard, "BayStripes", Vector3(204.0, 10.0, 4.0), Vector3(0.0, -60.0, 181.0), _hazard(0.1))
	# A stack of old rigs' doors and a satellite dish on the stern.
	for i in 4:
		var door := _box(yard, "OldDoor", Vector3(40.0, 60.0, 4.0), Vector3(200.0, -40.0 + i * 8.0, -200.0 - i * 30.0), _paint(junk_colors[(i + 2) % junk_colors.size()], HULL, Vector2(0.05, 0.05)))
		door.rotation = Vector3(0.0, 0.3 * i, 0.2)
	_cylinder(yard, "Dish", 50.0, 6.0, Vector3(0.0, 160.0, -620.0), steel, Vector3(0.6, 0.0, 0.0), 12)
	var beacon := _box(yard, "Beacon", Vector3(14.0, 14.0, 14.0), Vector3(0.0, 200.0, -620.0), _glow(amber, 2.6))
	beacon.set_script(_blinker_script)
	return yard


# --- The Orbital Arboretum -----------------------------------------------------------------

func _arboretum() -> Node3D:
	var parts := _station("ArboretumStation")
	var garden: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var white := _paint(Color(0.9, 0.93, 0.88), HULL, Vector2(0.05, 0.05))
	var moss := _paint(Color(0.35, 0.6, 0.3), ROCK, Vector2(0.03, 0.03))
	var bark := _paint(Color(0.45, 0.3, 0.2), null)
	var green := Color(0.45, 1.0, 0.45)
	_bay(garden, body, white, green, moss)

	# The garden disk, mossy on top.
	_add_collision(body, _cylinder(garden, "Disk", 300.0, 60.0, Vector3(0.0, -40.0, -260.0), white, Vector3.ZERO, 24))
	_cylinder(garden, "Lawn", 296.0, 4.0, Vector3(0.0, -8.0, -260.0), moss, Vector3.ZERO, 24)
	_cylinder(garden, "DiskLights", 304.0, 6.0, Vector3(0.0, -50.0, -260.0), _glow(green, 1.6), Vector3.ZERO, 24)
	# The great tree under the dome.
	_add_collision(body, _cylinder(garden, "Trunk", 30.0, 260.0, Vector3(0.0, 120.0, -260.0), bark, Vector3.ZERO, 8))
	for spot: Vector3 in [Vector3(0.0, 280.0, -260.0), Vector3(90.0, 230.0, -230.0), Vector3(-90.0, 240.0, -290.0), Vector3(20.0, 230.0, -170.0), Vector3(-20.0, 330.0, -280.0)]:
		_ball(garden, null, "Leaves", 95.0, spot, _paint(Color(0.3, 0.75, 0.35), ROCK, Vector2(0.03, 0.03)), Vector3(1.0, 0.8, 1.0))
	# Blossoms: pink glowing dots all over the crown (it's blooming soon).
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 24:
		_box(garden, "Blossom", Vector3(10.0, 10.0, 10.0), Vector3(rng.randf_range(-150.0, 150.0), rng.randf_range(200.0, 380.0), -260.0 + rng.randf_range(-150.0, 150.0)), _glow(Color(1.0, 0.6, 0.85), 1.8))
	# The glass dome: see-through, faintly green, with ribs.
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.6, 1.0, 0.7, 0.18)
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dome := SphereMesh.new()
	dome.radius = 280.0
	dome.height = 280.0
	dome.is_hemisphere = true
	dome.radial_segments = 16
	dome.rings = 6
	dome.material = glass
	_mesh(garden, "Dome", dome, Vector3(0.0, -10.0, -260.0))
	var dome_shape := CollisionShape3D.new()
	dome_shape.name = "DomeShape"
	var dome_ball := SphereShape3D.new()
	dome_ball.radius = 270.0
	dome_shape.shape = dome_ball
	dome_shape.position = Vector3(0.0, -10.0, -260.0)
	body.add_child(dome_shape, true)
	for i in 8:
		var angle := TAU * i / 8.0
		var rib := TorusMesh.new()
		rib.inner_radius = 276.0
		rib.outer_radius = 284.0
		rib.rings = 16
		rib.ring_segments = 4
		rib.material = white
		_mesh(garden, "DomeRib", rib, Vector3(0.0, -10.0, -260.0), Vector3(PI / 2.0, angle, 0.0)).scale = Vector3(1.0, 1.0, 1.0)
	_box(garden, "DomeCap", Vector3(40.0, 20.0, 40.0), Vector3(0.0, 270.0, -260.0), _glow(green, 2.0))
	# Hanging garden pods on stalks around the disk, each with a little light.
	for i in 6:
		var angle := TAU * (i + 0.5) / 6.0
		if absf(wrapf(angle, -PI, PI)) < 0.7:
			continue  # Keep the bay clear.
		var spot := Vector3(sin(angle) * 420.0, -120.0, -260.0 + cos(angle) * 420.0)
		_beam(garden, "Stalk", Vector3(sin(angle) * 290.0, -40.0, -260.0 + cos(angle) * 290.0), spot, 6.0, bark)
		_add_collision(body, _cylinder(garden, "Pod", 50.0, 70.0, spot, white, Vector3.ZERO, 10))
		_ball(garden, null, "PodPlants", 46.0, spot + Vector3(0.0, 35.0, 0.0), moss, Vector3(1.0, 0.6, 1.0))
		var lamp := _box(garden, "PodLight", Vector3(10.0, 10.0, 10.0), spot - Vector3(0.0, 40.0, 0.0), _glow(green, 2.0))
		lamp.set_script(_blinker_script)
		lamp.set("offset", i / 6.0)
	# Vines hanging off the disk's edge.
	for i in 14:
		var angle := TAU * i / 14.0
		if absf(wrapf(angle, -PI, PI)) < 0.5:
			continue
		_beam(garden, "Vine", Vector3(sin(angle) * 298.0, -60.0, -260.0 + cos(angle) * 298.0), Vector3(sin(angle) * 305.0, -160.0 - (i % 3) * 30.0, -260.0 + cos(angle) * 305.0), 3.0, moss)
	return garden


# --- Flurry's Comet Creamery ---------------------------------------------------------------

func _creamery() -> Node3D:
	var parts := _station("CreameryStation")
	var shop: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var ice := _paint(Color(0.82, 0.86, 1.0), ROCK, Vector2(0.02, 0.02))
	var pink := _paint(Color(1.0, 0.7, 0.85), null)
	var cream := _paint(Color(0.98, 0.95, 0.88), HULL, Vector2(0.05, 0.05))
	var waffle := _paint(Color(0.85, 0.6, 0.3), HULL, Vector2(0.05, 0.05))
	var lavender := Color(0.8, 0.65, 1.0)
	_bay(shop, body, cream, lavender, pink)

	# The comet: a big lumpy ball of ice, with a few smaller lumps.
	_ball(shop, body, "Comet", 260.0, Vector3(0.0, -200.0, -260.0), ice, Vector3(1.3, 0.8, 1.1))
	_ball(shop, body, "CometLump", 120.0, Vector3(260.0, -260.0, -200.0), ice)
	_ball(shop, body, "CometLump", 90.0, Vector3(-250.0, -230.0, -360.0), ice)
	# The parlor on top: a cream building with a pink-and-white striped
	# awning and big lit windows.
	_add_collision(body, _box(shop, "Parlor", Vector3(260.0, 140.0, 200.0), Vector3(0.0, 40.0, -230.0), cream))
	for i in 9:
		_box(shop, "Awning", Vector3(30.0, 10.0, 60.0), Vector3(-120.0 + i * 30.0, 120.0, -110.0), pink if i % 2 == 0 else cream).rotation = Vector3(0.35, 0.0, 0.0)
	_box(shop, "ParlorWindows", Vector3(220.0, 60.0, 2.0), Vector3(0.0, 40.0, -129.0), _windows(Vector2(4.0, 2.0)))
	_box(shop, "Roof", Vector3(280.0, 16.0, 220.0), Vector3(0.0, 118.0, -230.0), pink)
	# The giant cone on a mast: point down, three scoops, a cherry.
	_add_collision(body, _box(shop, "SignMast", Vector3(16.0, 260.0, 16.0), Vector3(-160.0, 250.0, -300.0), cream))
	var cone := CylinderMesh.new()
	cone.top_radius = 60.0
	cone.bottom_radius = 3.0
	cone.height = 160.0
	cone.radial_segments = 10
	cone.material = waffle
	_mesh(shop, "Cone", cone, Vector3(-160.0, 440.0, -300.0))
	var scoops: Array[Color] = [Color(1.0, 0.65, 0.85), Color(0.95, 0.95, 0.85), Color(0.55, 0.35, 0.25)]
	for i in 3:
		_ball(shop, null, "Scoop", 58.0 - i * 6.0, Vector3(-160.0, 530.0 + i * 70.0, -300.0), _glow(scoops[i], 0.5, scoops[i]))
	var cherry := _ball(shop, null, "Cherry", 14.0, Vector3(-160.0, 712.0, -300.0), _glow(Color(1.0, 0.15, 0.25), 2.2))
	cherry.set_script(_blinker_script)
	# Icicles hanging off the parlor and the bay.
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var icicle := _glow(Color(0.75, 0.85, 1.0), 0.5, Color(0.85, 0.9, 1.0))
	for i in 16:
		var spike := CylinderMesh.new()
		spike.top_radius = rng.randf_range(4.0, 8.0)
		spike.bottom_radius = 0.5
		spike.height = rng.randf_range(20.0, 50.0)
		spike.radial_segments = 5
		spike.material = icicle
		var x := -120.0 + i * 16.0
		_mesh(shop, "Icicle", spike, Vector3(x, -30.0 - spike.height * 0.5, -130.0))
	# Lavender lamps along the comet, and the freezer vents puffing frost.
	for i in 5:
		var angle := TAU * i / 5.0 + 0.3
		var lamp := _box(shop, "CometLamp", Vector3(12.0, 12.0, 12.0), Vector3(sin(angle) * 330.0, -150.0, -260.0 + cos(angle) * 280.0), _glow(lavender, 2.2))
		lamp.set_script(_blinker_script)
		lamp.set("offset", i / 5.0)
	for side: float in [-1.0, 1.0]:
		_cylinder(shop, "FreezerVent", 20.0, 40.0, Vector3(side * 100.0, 140.0, -300.0), _paint(Color(0.6, 0.65, 0.75), HULL, Vector2(0.05, 0.05)), Vector3.ZERO, 8)
		_ball(shop, null, "Frost", 26.0, Vector3(side * 100.0, 175.0, -300.0), _glow(Color(0.9, 0.95, 1.0), 0.6, Color(0.95, 0.97, 1.0)))
	return shop
