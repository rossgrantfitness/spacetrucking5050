extends SceneTree
## Builds res://scenes/flight/TidewaterRoad.tscn: everything fixed along the
## long haul from the truck stop to Tidewater Cannery (about 59 km):
## highway signs, the border gate between the systems, roadside attractions
## (a lighthouse, the world's biggest donut, an old derelict), a junk field,
## an icy rock field, a speed trap, an ion storm, a pod of whales, and a
## couple of long-haul truckers going back and forth.
##
## Everything is placed by "how far along the road" (in km from the truck
## stop), "how far to the side" and "how high", so it's easy to move things
## by editing the numbers below and running this again:
##     godot --headless --path . -s tools/build_road.gd
##
## Careful: running it OVERWRITES that scene. (The random sights you pass,
## like big ships and convoys, aren't here: see RouteEvents.gd.)


## Where the road starts (the truck stop) and which way it runs (toward
## Tidewater). Must match the places in FlightSandbox.tscn.
const START := Vector3(0.0, 0.0, -10600.0)
const ALONG := Vector3(0.7407, 0.04, -0.6706)
## Turns things so their front (+Z) faces travelers coming from the truck stop.
const FACING_YAW: float = -0.835

## The scripts, loaded by path when the tool runs (a tool script can't
## preload game scripts that use the autoloads).
const ROUTE_SIGN := "res://scenes/flight/events/RouteSign.gd"
const LANDMARK := "res://scenes/flight/events/Landmark.gd"
const HAZARD := "res://scenes/flight/events/HazardZone.gd"
const WHALES := "res://scenes/flight/events/WhalePod.gd"
const FIELD := "res://scenes/flight/AsteroidField.gd"
const TRAFFIC := "res://scenes/flight/TrafficShip.gd"


func _initialize() -> void:
	var road := Node3D.new()
	road.name = "TidewaterRoad"

	# Highway signs: front for the trip out, back for the trip home.
	_sign(road, 3.0, "TIDEWATER  56 KM\nGAS-N-GO 47  27 KM", "TRUCK STOP  3 KM\nHOME BASE  13 KM")
	_sign(road, 13.0, "GAS-N-GO 47  17 KM\nTIDEWATER  46 KM", "TRUCK STOP  13 KM\nHOME BASE  23 KM")
	_sign(road, 25.0, "GAS-N-GO 47  NEXT RIGHT\nWORLD'S BIGGEST DONUT!", "TRUCK STOP  25 KM\nHOME BASE  35 KM")
	_sign(road, 36.0, "WELCOME TO TIDEWATER\nPLEASE DON'T FEED THE WHALES", "GAS-N-GO 47  6 KM\nTRUCK STOP  36 KM")
	_sign(road, 47.0, "TIDEWATER CANNERY  12 KM\nION STORMS POSSIBLE", "GAS-N-GO 47  17 KM\nDRIVE SAFE")
	_sign(road, 56.0, "TIDEWATER CANNERY  3 KM\nWE CAN, THEREFORE WE ARE", "LEAVING TIDEWATER\nHOME BASE  67 KM")

	# Where the home system ends and Tidewater begins.
	var gate := _thing(road, LANDMARK, "BorderGate", 31.0, 0.0, 0.0)
	gate.set("kind", 4)  # Landmark.Kind.BORDER_GATE
	gate.set("label", "NOW ENTERING TIDEWATER SYSTEM")

	# Roadside attractions.
	_thing(road, LANDMARK, "Lighthouse", 33.5, -2000.0, -100.0).set("kind", 0)
	var donut := _thing(road, LANDMARK, "BiggestDonut", 28.0, 3400.0, 400.0)
	donut.set("kind", 1)
	var derelict := _thing(road, LANDMARK, "Derelict", 40.0, -900.0, 150.0)
	derelict.set("kind", 3)
	derelict.set("label", "THE DOROTHY MAE (ABANDONED)")

	# Hazards: an ion storm hanging just off the lane, and the space
	# patrol's speed trap before the cannery.
	var storm := _thing(road, HAZARD, "IonStorm", 44.0, -700.0, 0.0)
	storm.set("kind", 0)
	storm.set("radius", 1600.0)
	var trap := _thing(road, HAZARD, "SpeedTrap", 55.0, 260.0, 60.0)
	trap.set("kind", 1)
	trap.set("radius", 2500.0)

	# Tidewater's whales, swimming in lazy circles near the cannery.
	_thing(road, WHALES, "Whales", 52.0, 2500.0, 300.0)

	# Debris: an old spill along the lane, and junk around the cannery.
	var spill := _field(road, "JunkField", 18.0, 0.0, Vector3(1800.0, 500.0, 3200.0), 260, true, 1801)
	spill.set("rock_radius_range", Vector2(2.0, 16.0))
	var scrap := _field(road, "CanneryJunk", 57.5, 700.0, Vector3(900.0, 300.0, 900.0), 90, true, 1802)
	scrap.set("rock_radius_range", Vector2(2.0, 12.0))
	# Icy rocks: Tidewater's own little asteroid belt.
	var ice := _field(road, "IceField", 50.5, 0.0, Vector3(2400.0, 700.0, 5000.0), 520, false, 1803)
	ice.set("rock_colors", PackedColorArray([Color(0.75, 0.9, 1.0), Color(0.6, 0.8, 0.9), Color(0.85, 0.95, 0.95),
			Color(0.5, 0.75, 0.85), Color(0.7, 0.85, 0.8)]))
	ice.set("landmark_count", 6)

	# Long-haul truckers going back and forth along the road.
	_hauler(road, "LongHaulerA", 280.0, 120.0, 60.0, 0.15, "res://scenes/flight/traffic/CapsuleHaulerVisual.tscn", Color(1.0, 0.75, 0.35))
	_hauler(road, "LongHaulerB", -320.0, -80.0, 52.0, 0.6, "res://scenes/flight/traffic/BoxHaulerVisual.tscn", Color(0.6, 1.0, 0.5))
	_hauler(road, "Courier", 180.0, 250.0, 90.0, 0.35, "res://scenes/flight/traffic/CourierVisual.tscn", Color(1.0, 0.45, 0.8))

	_save(road, "res://scenes/flight/TidewaterRoad.tscn")
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
	thing.rotation = Vector3(0.0, FACING_YAW, 0.0)
	road.add_child(thing)
	return thing


func _sign(road: Node3D, km: float, front: String, back: String) -> void:
	var board := _thing(road, ROUTE_SIGN, "Sign%dKm" % roundi(km), km, -330.0, 160.0)
	board.set("front_text", front)
	board.set("back_text", back)


func _field(road: Node3D, field_name: String, km: float, side: float, size: Vector3, count: int, junk: bool, seed_number: int) -> Node3D:
	var field := _thing(road, FIELD, field_name, km, side, 0.0)
	field.set("junk", junk)
	field.set("field_size", size)
	field.set("rock_count", count)
	field.set("field_seed", seed_number)
	field.set("landmark_count", 0 if junk else 4)
	field.set("keep_clear_spots", PackedVector3Array())
	return field


## A trucker flying the whole road and back, `side` meters off the lane.
func _hauler(road: Node3D, hauler_name: String, side: float, up: float, speed: float, start: float, visual: String, color: Color) -> void:
	var ship := Node3D.new()
	ship.set_script(load(TRAFFIC))
	ship.name = hauler_name
	ship.set("visual_scene", load(visual))
	ship.set("waypoints", PackedVector3Array([spot(1.5, side, up), spot(20.0, side * 1.2, up), spot(40.0, side, up + 40.0),
			spot(57.0, side, up), spot(57.5, -side, up), spot(40.0, -side, up - 40.0), spot(20.0, -side * 1.2, up), spot(1.5, -side, up)]))
	ship.set("speed", speed)
	ship.set("start_fraction", start)
	ship.set("engine_trail_color", color)
	ship.set("hull_size", Vector3(14.0, 7.0, 34.0))
	road.add_child(ship)


func _save(scene_root: Node, path: String) -> void:
	for child in scene_root.get_children():
		child.owner = scene_root
	var scene := PackedScene.new()
	var error := scene.pack(scene_root)
	if error == OK:
		error = ResourceSaver.save(scene, path)
	print("%s: %s" % [path, error_string(error)])
	scene_root.free()
