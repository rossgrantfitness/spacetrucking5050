extends SceneTree
## Builds res://scenes/flight/GlimmerRoad.tscn: everything fixed along the
## road from the truck stop to The High Roller, Sal's casino in the magenta
## Glimmer System (about 56 km): the Glimmer System's gimmick (neon billboards, more and more of them as you
## get closer), roadside attractions (the world's biggest slot machine, the
## giant dice, the Little Chapel of the Void), a spill of casino chips, a
## speed trap by the casino, limos and haulers going back and forth, and
## spaceway beacons along the lane.
##
## Like build_road.gd (the road to Tidewater), everything is placed by "km
## along the road", "meters to the side" and "meters up":
##     godot --headless --path . -s tools/build_glimmer_road.gd
##
## Careful: running it OVERWRITES that scene.


## Where the road starts (the truck stop) and which way it runs (toward the
## casino). Must match the places in FlightSandbox.tscn.
const START := Vector3(0.0, 0.0, -10600.0)
const ALONG := Vector3(-0.7727, -0.2588, -0.5796)
## Turns things so their front (+Z) faces travelers coming from the truck stop.
const FACING_YAW: float = 0.927

const LANDMARK := "res://scenes/flight/events/Landmark.gd"
const BILLBOARD := "res://scenes/flight/events/Billboard.gd"
const HAZARD := "res://scenes/flight/events/HazardZone.gd"
const FIELD := "res://scenes/flight/AsteroidField.gd"
const TRAFFIC := "res://scenes/flight/TrafficShip.gd"
const SPACEWAY := "res://scenes/flight/Spaceway.gd"
const MAGENTA := Color(1.0, 0.35, 0.8)

## The Glimmer System's neon billboards: km along the road, which side
## (1 = right, -1 = left), and the ad. They get thicker near the casino.
const BILLBOARDS: Array = [
	[32.0, 1.0, "WELCOME TO GLIMMER|WHERE THE NIGHT NEVER ENDS (WE HID THE CLOCKS)"],
	[35.0, -1.0, "THE HIGH ROLLER|EVERYBODY'S A WINNER* · *TERMS APPLY"],
	[38.0, 1.0, "LOOSEST SLOTS IN THE SECTOR|PROBABLY"],
	[41.0, -1.0, "ALL-YOU-CAN-EAT SHRIMP|ALL NIGHT · ALL SHRIMP · ALL YOU"],
	[43.5, 1.0, "LIVE TONIGHT: THE CROONING CRAB|TWO SHOWS · BOTH SIDEWAYS"],
	[46.0, -1.0, "CASH 4 RIGS|WE BUY ANYTHING THAT FLIES (OR USED TO)"],
	[48.0, 1.0, "FEELING LUCKY?|YOU SHOULD. YOU REALLY SHOULD."],
	[49.5, -1.0, "FREE DRINKS FOR PLAYERS|DEFINE 'PLAYER'"],
	[51.0, 1.0, "SAL SAYS: COME ON IN|SAL ALWAYS SAYS THAT"],
	[52.5, -1.0, "LITTLE CHAPEL OF THE VOID|WEDDINGS · VOW RENEWALS · NO REFUNDS"],
	[54.0, 1.0, "LOST? GOOD.|THE HIGH ROLLER · NEXT EXIT"],
	[55.0, -1.0, "DON'T FORGET YOUR RIG|(PEOPLE DO)"],
]


func _initialize() -> void:
	var road := Node3D.new()
	road.name = "GlimmerRoad"

	# (No highway signs or border gate: the developer found the giant signs
	# corny. The HUD still says when you enter a system.)

	# Roadside attractions.
	var slots := _thing(road, LANDMARK, "BiggestSlotMachine", 22.0, 2600.0, 300.0)
	slots.set("kind", 5)  # SLOT_MACHINE
	slots.set("log_id", "biggest_slot")
	var dice := _thing(road, LANDMARK, "GiantDice", 37.0, -2800.0, 500.0)
	dice.set("kind", 6)  # DICE
	dice.set("log_id", "giant_dice")
	var chapel := _thing(road, LANDMARK, "LittleChapel", 45.0, 1700.0, -100.0)
	chapel.set("kind", 7)  # CHAPEL
	chapel.set("log_id", "void_chapel")

	# The neon billboards: the Glimmer System's gimmick.
	for board: Array in BILLBOARDS:
		var ad := (board[2] as String).split("|")
		var billboard := _thing(road, BILLBOARD, "Billboard%dKm" % roundi(board[0] * 10.0), board[0], board[1] * 520.0, 120.0)
		billboard.set("headline", ad[0])
		billboard.set("tagline", ad[1])
		billboard.set("log_id", "billboard")

	# A spill of casino chips across the lane (bonkable), and the space
	# patrol's speed trap outside the casino.
	var chips := _field(road, "ChipSpill", 12.0, 0.0, Vector3(1600.0, 400.0, 2800.0), 220, 2801)
	chips.set("rock_radius_range", Vector2(2.0, 10.0))
	chips.set("rock_colors", PackedColorArray([Color(1.0, 0.3, 0.6), Color(0.3, 0.6, 1.0), Color(1.0, 0.85, 0.3),
			Color(0.95, 0.95, 0.9), Color(0.2, 0.2, 0.25)]))
	var trap := _thing(road, HAZARD, "SpeedTrap", 53.5, 260.0, 60.0)
	trap.set("kind", 1)
	trap.set("radius", 2500.0)
	trap.set("log_id", "speed_trap")

	# Limos and haulers going back and forth along the road.
	_hauler(road, "Limo", 220.0, 90.0, 85.0, 0.2, "res://scenes/flight/traffic/CourierVisual.tscn", MAGENTA, "HIGH ROLLER LIMO")
	_hauler(road, "ChipHauler", -300.0, -70.0, 55.0, 0.55, "res://scenes/flight/traffic/BoxHaulerVisual.tscn", Color(1.0, 0.8, 0.35), "")
	_hauler(road, "PartyBus", 160.0, 200.0, 70.0, 0.8, "res://scenes/flight/traffic/CapsuleHaulerVisual.tscn", Color(0.5, 0.9, 1.0), "BACHELOR PARTY BUS")

	# The spaceway: magenta and gold reflector beacons all the way.
	_spaceway(road, "SpacewayGlimmer", [spot(0.9, 0.0, 0.0), spot(55.6, 0.0, 0.0)], 200.0, 80.0, MAGENTA, Color(1.0, 0.85, 0.45))

	_save(road, "res://scenes/flight/GlimmerRoad.tscn")
	quit()


## A spot on the road: `km` along it, `side` meters to the right (negative =
## left), `up` meters above.
static func spot(km: float, side: float, up: float) -> Vector3:
	var right := ALONG.cross(Vector3.UP).normalized()
	return START + ALONG * km * 1000.0 + right * side + Vector3.UP * up


func _thing(road: Node3D, script_path: String, thing_name: String, km: float, side: float, up: float) -> Node3D:
	var thing := Node3D.new()
	thing.set_script(load(script_path))
	thing.name = thing_name
	thing.position = spot(km, side, up)
	# Faces travelers coming from the truck stop: turned toward them, and
	# tipped up or down to match the road's climb.
	thing.rotation = Vector3(asin(ALONG.y), FACING_YAW, 0.0)
	road.add_child(thing)
	return thing



func _field(road: Node3D, field_name: String, km: float, side: float, size: Vector3, count: int, seed_number: int) -> Node3D:
	var field := _thing(road, FIELD, field_name, km, side, 0.0)
	field.set("junk", false)  # Lumps, so the chip colors show (junk uses its own colors).
	field.set("field_size", size)
	field.set("rock_count", count)
	field.set("field_seed", seed_number)
	field.set("landmark_count", 0)
	field.set("keep_clear_spots", PackedVector3Array())
	return field


## A trucker (or limo) driving the whole road and back, `side` meters off
## the lane.
func _hauler(road: Node3D, hauler_name: String, side: float, up: float, speed: float, start: float, visual: String, color: Color, label: String) -> void:
	var ship := Node3D.new()
	ship.set_script(load(TRAFFIC))
	ship.name = hauler_name
	ship.set("visual_scene", load(visual))
	ship.set("waypoints", PackedVector3Array([spot(1.5, side, up), spot(20.0, side * 1.2, up), spot(40.0, side, up + 40.0),
			spot(54.0, side, up), spot(54.5, -side, up), spot(40.0, -side, up - 40.0), spot(20.0, -side * 1.2, up), spot(1.5, -side, up)]))
	ship.set("speed", speed)
	ship.set("start_fraction", start)
	ship.set("engine_trail_color", color)
	ship.set("hull_size", Vector3(14.0, 7.0, 34.0))
	if not label.is_empty():
		ship.set("id_label", label)
	road.add_child(ship)


func _spaceway(road: Node3D, way_name: String, lane: Array[Vector3], spacing: float, half_width: float, left: Color, right: Color) -> void:
	var way := MultiMeshInstance3D.new()
	way.set_script(load(SPACEWAY))
	way.name = way_name
	way.set("points", PackedVector3Array(lane))
	way.set("spacing", spacing)
	way.set("half_width", half_width)
	way.set("left_color", left)
	way.set("right_color", right)
	road.add_child(way)


func _save(scene_root: Node, path: String) -> void:
	for child in scene_root.get_children():
		child.owner = scene_root
	var scene := PackedScene.new()
	var error := scene.pack(scene_root)
	if error == OK:
		error = ResourceSaver.save(scene, path)
	print("%s: %s" % [path, error_string(error)])
	scene_root.free()
