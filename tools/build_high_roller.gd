extends "res://tools/build_placeholder_models.gd"
## Builds The High Roller, Sal's casino out in the magenta Glimmer System,
## as seen from space:
##     res://scenes/flight/HighRollerStation.tscn
##
## A giant roulette wheel turning slowly on its side, a tower of lit
## floors on top with a huge neon sign, playing-card panels around the rim,
## giant neon dice hanging off the side, and a docking bay facing +Z (like
## every station: rotate the place in the flight scene to aim it).
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_high_roller.gd
##
## Careful: running it again OVERWRITES that scene. It borrows the shape
## and material helpers from build_placeholder_models.gd.


const SPINNER_PATH := "res://scenes/common/Spinner.gd"


func _initialize() -> void:
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_save(_build_casino(), "res://scenes/flight/HighRollerStation.tscn")
	quit()


func _build_casino() -> Node3D:
	var casino := Node3D.new()
	casino.name = "HighRollerStation"
	var body := StaticBody3D.new()
	body.name = "Collision"
	casino.add_child(body, true)
	var gold := _paint(Color(1.0, 0.78, 0.3), HULL, Vector2(0.05, 0.05))
	var dark := _paint(Color(0.12, 0.06, 0.16), HULL, Vector2(0.05, 0.05))
	var magenta := _paint(Color(0.85, 0.2, 0.6), HULL, Vector2(10.0, 4.0), false)
	var cream := _paint(Color(0.95, 0.92, 0.88), HULL, Vector2(10.0, 4.0), false)

	# The base: a chunky drum the bay is cut into.
	_add_collision(body, _cylinder(casino, "Drum", 260.0, 180.0, Vector3(0.0, 0.0, -120.0), magenta, Vector3.ZERO, 20))
	_cylinder(casino, "DrumBand", 263.0, 22.0, Vector3(0.0, 40.0, -120.0), gold, Vector3.ZERO, 20)
	_cylinder(casino, "DrumLights", 264.0, 6.0, Vector3(0.0, -30.0, -120.0), _glow(Color(1.0, 0.85, 0.5), 1.8), Vector3.ZERO, 20)
	# The docking bay: a dark round face with magenta lights, facing +Z.
	_add_collision(body, _box(casino, "BayBlock", Vector3(200.0, 150.0, 120.0), Vector3(0.0, 0.0, 120.0), cream))
	_add_collision(body, _cylinder(casino, "DockingFace", 56.0, 8.0, Vector3(0.0, 0.0, 182.0), dark, ALONG_Z, 16))
	var bay_light := TorusMesh.new()
	bay_light.inner_radius = 30.0
	bay_light.outer_radius = 38.0
	bay_light.rings = 24
	bay_light.ring_segments = 6
	bay_light.material = _glow(Color(1.0, 0.35, 0.8), 1.8)
	_mesh(casino, "DockingLights", bay_light, Vector3(0.0, 0.0, 187.0), ALONG_Z)
	_box(casino, "BayCanopy", Vector3(220.0, 12.0, 60.0), Vector3(0.0, 82.0, 160.0), gold)
	for i in 9:
		var bulb := _box(casino, "CanopyBulb", Vector3(10.0, 10.0, 10.0), Vector3(-96.0 + i * 24.0, 74.0, 190.0), _glow(Color(1.0, 0.95, 0.7), 2.2))
		if i % 2 == 0:
			bulb.set_script(_blinker_script)

	# The roulette wheel on top, turning slowly: red and black pockets
	# around a gold hub.
	var wheel := Node3D.new()
	wheel.name = "RouletteWheel"
	wheel.position = Vector3(0.0, 110.0, -120.0)
	wheel.set_script(load(SPINNER_PATH))
	wheel.set("speed", 0.06)
	casino.add_child(wheel, true)
	_cylinder(wheel, "WheelBase", 330.0, 30.0, Vector3.ZERO, dark, Vector3.ZERO, 24)
	for i in 24:
		var angle := TAU * i / 24.0
		var pocket_color := Color(0.85, 0.12, 0.2) if i % 2 == 0 else Color(0.08, 0.06, 0.1)
		if i == 0:
			pocket_color = Color(0.2, 0.75, 0.35)
		var pocket := _box(wheel, "Pocket", Vector3(60.0, 8.0, 80.0), Vector3(sin(angle) * 270.0, 18.0, cos(angle) * 270.0), _glow(pocket_color, 0.9, pocket_color))
		pocket.rotation = Vector3(0.0, angle, 0.0)
	_cylinder(wheel, "WheelHub", 90.0, 40.0, Vector3(0.0, 20.0, 0.0), gold, Vector3.ZERO, 16)
	_cylinder(wheel, "WheelSpire", 16.0, 90.0, Vector3(0.0, 70.0, 0.0), gold, Vector3.ZERO, 8)
	_add_ring_collision(body, 300.0, 40.0, 16)

	# The hotel tower rising through the middle, rows of lit windows.
	var tower := _box(casino, "Tower", Vector3(120.0, 420.0, 120.0), Vector3(0.0, 330.0, -120.0), cream)
	tower.position = Vector3(0.0, 330.0, -120.0)
	_add_collision(body, tower)
	for side: float in [-1.0, 1.0]:
		_box(casino, "TowerWindows", Vector3(2.0, 380.0, 100.0), Vector3(side * 61.0, 330.0, -120.0), _windows(Vector2(6.0, 30.0)))
	_box(casino, "TowerWindowsFront", Vector3(100.0, 380.0, 2.0), Vector3(0.0, 330.0, -59.0), _windows(Vector2(6.0, 30.0)))
	_box(casino, "TowerCrown", Vector3(150.0, 30.0, 150.0), Vector3(0.0, 555.0, -120.0), gold)
	var beacon := _box(casino, "Beacon", Vector3(16.0, 16.0, 16.0), Vector3(0.0, 585.0, -120.0), _glow(Color(1.0, 0.3, 0.6), 2.4))
	beacon.set_script(_blinker_script)

	# The giant sign on the tower's front, with chasing bulbs.
	_box(casino, "SignBoard", Vector3(360.0, 120.0, 10.0), Vector3(0.0, 470.0, -50.0), dark)
	_sign(casino, "SignName", "THE HIGH ROLLER", 0.45, Color(1.0, 0.4, 0.85), Vector3(0.0, 485.0, -44.0))
	_sign(casino, "SignSub", "CASINO · HOTEL · BUFFET · NO CLOCKS", 0.18, Color(1.0, 0.85, 0.4), Vector3(0.0, 445.0, -44.0))
	for i in 16:
		var bulb := _box(casino, "SignBulb", Vector3(10.0, 10.0, 6.0), Vector3(-170.0 + i * 22.7, 528.0, -44.0), _glow(Color(1.0, 0.95, 0.7), 2.4))
		bulb.set_script(_blinker_script)
		bulb.set("offset", i / 16.0)
		bulb.set("period", 0.8)
		bulb.set("on_fraction", 0.6)

	# Playing-card panels standing around the drum's rim.
	var suits: Array[Color] = [Color(1.0, 0.25, 0.35), Color(0.1, 0.08, 0.12)]
	for i in 8:
		var angle := TAU * (i + 0.5) / 8.0
		if absf(wrapf(angle, -PI, PI)) < 0.6:
			continue  # Keep the bay clear.
		var card := _box(casino, "Card", Vector3(70.0, 100.0, 4.0), Vector3(sin(angle) * 268.0, 10.0, -120.0 + cos(angle) * 268.0), cream)
		card.rotation = Vector3(0.0, angle, 0.0)
		var suit := _box(casino, "CardSuit", Vector3(30.0, 30.0, 2.0), Vector3(sin(angle) * 271.0, 10.0, -120.0 + cos(angle) * 271.0), _glow(suits[i % 2], 1.2, suits[i % 2]))
		suit.rotation = Vector3(0.0, angle, PI / 4.0)

	# Giant neon dice hanging off one side on a boom.
	_add_collision(body, _box(casino, "DiceBoom", Vector3(260.0, 14.0, 14.0), Vector3(-380.0, 60.0, -120.0), gold))
	for i in 2:
		var die := _box(casino, "NeonDie", Vector3(60.0, 60.0, 60.0), Vector3(-480.0 + i * 70.0, 0.0 - i * 20.0, -120.0), _glow(Color(1.0, 0.3, 0.75) if i == 0 else Color(0.4, 0.95, 1.0), 1.4))
		die.rotation = Vector3(0.4 * (i + 1), 0.7, 0.2)
		_beam(casino, "DieCable", Vector3(-480.0 + i * 70.0, 60.0, -120.0), Vector3(-480.0 + i * 70.0, 30.0 - i * 20.0, -120.0), 2.0, gold)
	return casino
