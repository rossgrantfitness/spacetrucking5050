extends SceneTree
## Builds the roads out to the three far systems, everything fixed along each
## one (like build_glimmer_road.gd does for the casino):
##     res://scenes/flight/DustbowlRoad.tscn   - down to Hoof & Hull Salvage
##     res://scenes/flight/GreenhouseRoad.tscn - up to The Orbital Arboretum
##     res://scenes/flight/FrostlineRoad.tscn  - the long climb to Flurry's
##
## Each road gets its system's roadside attractions and billboards, and its gimmick on the lane itself: dust
## storms and a junk spill (Dustbowl), pollen clouds and a mossy rock field
## (Greenhouse Reach), comet-hail storms and ice fields (the Frostline). The
## farther out the road, the more of the lane is weather: a gentle
## difficulty curve, never a wall.
##
## Everything is placed by "km along the road", "meters to the side" and
## "meters up". Run it with:
##     godot --headless --path . -s tools/build_frontier_roads.gd
##
## Careful: running it OVERWRITES those scenes.


## Where every road starts: the truck stop. Must match FlightSandbox.tscn.
const START := Vector3(0.0, 0.0, -10600.0)

const LANDMARK := "res://scenes/flight/events/Landmark.gd"
const BILLBOARD := "res://scenes/flight/events/Billboard.gd"
const HAZARD := "res://scenes/flight/events/HazardZone.gd"
const FIELD := "res://scenes/flight/AsteroidField.gd"
const TRAFFIC := "res://scenes/flight/TrafficShip.gd"
const SPACEWAY := "res://scenes/flight/Spaceway.gd"
const BOX_HAULER := "res://scenes/flight/traffic/BoxHaulerVisual.tscn"
const CAPSULE_HAULER := "res://scenes/flight/traffic/CapsuleHaulerVisual.tscn"
const COURIER := "res://scenes/flight/traffic/CourierVisual.tscn"

## Landmark.Kind numbers (see scenes/flight/events/Landmark.gd).
const DERELICT := 3
const SKULL := 8
const WINDMILL := 9
const TREE := 10
const WATERING_CAN := 11
const SNOWMAN := 12
const CONE := 13

## The road being built (set by _build_road): where it ends and which way.
var _along := Vector3.FORWARD
var _yaw: float = 0.0


func _initialize() -> void:
	_build_road({
		"name": "DustbowlRoad", "end": Vector3(52000.0, -34000.0, 12000.0), "color": Color(1.0, 0.65, 0.25),
		"second_color": Color(0.85, 0.4, 0.2), "board_color": Color(0.35, 0.2, 0.08), "place": "HOOF & HULL",
		"system": "THE DUSTBOWL", "gate_km": 33.0,
		"signs": [[3.0, "HOOF & HULL SALVAGE  61 KM\nTHE DUSTBOWL · STEEP DESCENT", "TRUCK STOP  3 KM\nHOME SPACE"],
				[18.0, "HOOF & HULL  46 KM\nCHECK YOUR AIR FILTER", "TRUCK STOP  18 KM\nALMOST HOME"],
				[30.0, "THE DUSTBOWL  3 KM\nSTORMS LIKELY · ALWAYS", "TRUCK STOP  30 KM\nYOU MADE IT OUT"],
				[50.0, "HOOF & HULL  14 KM\nSEE THE BIG STEER", "TRUCK STOP  50 KM\nKEEP CLIMBING"],
				[61.0, "HOOF & HULL  3 KM\nMIND THE CRANE", "LEAVING THE YARD\nTRUCK STOP  61 KM"]],
		"landmarks": [[SKULL, "BigSteer", 24.0, 2400.0, -300.0, "big_steer", ""], [WINDMILL, "OldWindmill", 45.0, -1800.0, 200.0, "old_windmill", ""],
				[DERELICT, "DustyRose", 54.0, 900.0, -150.0, "derelict", "THE DUSTY ROSE"]],
		"billboards": [[36.0, "WELCOME TO THE DUSTBOWL|WIPE YOUR FEET · WIPE EVERYTHING"], [41.0, "CACTUS JUICE|IT'S MOSTLY WATER. MOSTLY."],
				[47.0, "LAST WATER FOR 40 KM|(THERE IS NO WATER)"], [52.0, "USED RIGS · LIKE NEW|IF NEW WAS A LONG TIME AGO"],
				[57.0, "HOOF & HULL SALVAGE|WE BUY WRECKS · WE SELL WRECKS · WE ARE WRECKS"], [62.0, "LOST: ONE FRIDGE|ANSWERS TO NOTHING"]],
		"storms": [[40.0, 0.0, 2200.0], [56.0, 300.0, 2000.0]],
		"fields": [["JunkSpill", 28.0, true, Vector3(1800.0, 500.0, 2600.0), 260, 3301, PackedColorArray()]],
		"haulers": [["ScrapHauler", BOX_HAULER, Color(1.0, 0.6, 0.25), "SCRAP HAULER (FULL)"], ["DustRunner", COURIER, Color(1.0, 0.85, 0.5), "DUST RUNNER"]],
	})
	_build_road({
		"name": "GreenhouseRoad", "end": Vector3(-50000.0, 36000.0, 24000.0), "color": Color(0.45, 1.0, 0.45),
		"second_color": Color(1.0, 0.6, 0.85), "board_color": Color(0.1, 0.3, 0.12), "place": "THE ARBORETUM",
		"system": "GREENHOUSE REACH", "gate_km": 35.0,
		"signs": [[3.0, "THE ARBORETUM  66 KM\nGREENHOUSE REACH · STEEP CLIMB", "TRUCK STOP  3 KM\nHOME SPACE"],
				[18.0, "THE ARBORETUM  51 KM\nJELLYFISH CROSSING AHEAD", "TRUCK STOP  18 KM\nALMOST HOME"],
				[32.0, "GREENHOUSE REACH  3 KM\nPOLLEN COUNT: HIGH", "TRUCK STOP  32 KM\nDOWNHILL FROM HERE"],
				[52.0, "THE ARBORETUM  17 KM\nDRIFT SLOW THROUGH THE BLOOM", "TRUCK STOP  52 KM\nMIND THE JELLIES"],
				[65.0, "THE ARBORETUM  4 KM\nNO RUSH · NEVER A RUSH", "LEAVING THE ARBORETUM\nTRUCK STOP  65 KM"]],
		"landmarks": [[TREE, "FloatingTree", 26.0, -2200.0, 300.0, "floating_tree", ""], [WATERING_CAN, "WateringCan", 48.0, 2400.0, -200.0, "watering_can", ""]],
		"billboards": [[38.0, "WELCOME TO GREENHOUSE REACH|PLEASE DON'T PICK THE NEBULA"], [43.0, "TALK TO YOUR PLANTS|THEY'RE LISTENING"],
				[49.0, "U-PICK MOONBERRIES|BRING YOUR OWN SPACESUIT"], [55.0, "JELLYFISH CROSSING|NEXT 20 KM · DRIFT SLOW"],
				[61.0, "COMPOST: IT'S THE GOOD STUFF|DR. MOSS AGREES"], [66.0, "THE ORBITAL ARBORETUM|91 YEARS · 1 TREE · WORTH IT"]],
		"storms": [[44.0, 0.0, 2200.0], [60.0, -300.0, 2400.0]],
		"fields": [["MossyRocks", 54.0, false, Vector3(2000.0, 600.0, 2400.0), 240, 3401,
				PackedColorArray([Color(0.35, 0.55, 0.3), Color(0.45, 0.65, 0.35), Color(0.3, 0.45, 0.3), Color(0.55, 0.6, 0.4), Color(0.4, 0.5, 0.45)])]],
		"haulers": [["SeedBarge", CAPSULE_HAULER, Color(0.5, 1.0, 0.5), "SEED BARGE (SLOW)"], ["FlowerVan", COURIER, Color(1.0, 0.6, 0.85), "FLOWER DELIVERY"]],
	})
	_build_road({
		"name": "FrostlineRoad", "end": Vector3(10000.0, 50000.0, -74000.0), "color": Color(0.8, 0.65, 1.0),
		"second_color": Color(0.6, 0.85, 1.0), "board_color": Color(0.22, 0.16, 0.38), "place": "FLURRY'S",
		"system": "THE FROSTLINE", "gate_km": 41.0,
		"signs": [[3.0, "FLURRY'S COMET CREAMERY  76 KM\nTHE FROSTLINE · LONG CLIMB", "TRUCK STOP  3 KM\nHOME SPACE"],
				[18.0, "FLURRY'S  61 KM\nFILL UP NOW · LAST PUMPS", "TRUCK STOP  18 KM\nALMOST HOME"],
				[38.0, "THE FROSTLINE  3 KM\nCHAINS REQUIRED (FOR WHAT?)", "TRUCK STOP  38 KM\nDOWNHILL ALL THE WAY"],
				[55.0, "FLURRY'S  24 KM\nHAIL LIKELY · KEEP IT STEADY", "TRUCK STOP  55 KM\nWARMER THAT WAY"],
				[76.0, "FLURRY'S  3 KM\nALMOST THERE (REALLY)", "LEAVING THE TOP OF THE MAP\nTRUCK STOP  76 KM"]],
		"landmarks": [[SNOWMAN, "BigSnowman", 30.0, 2600.0, 0.0, "big_snowman", ""], [CONE, "GiantCone", 60.0, -2200.0, 400.0, "giant_cone", ""],
				[DERELICT, "LastScoop", 70.0, 1000.0, -200.0, "derelict", "THE LAST SCOOP"]],
		"billboards": [[44.0, "WELCOME TO THE FROSTLINE|TOP OF THE MAP · BRING A SWEATER"], [49.0, "ALMOST THERE|(NO YOU'RE NOT)"],
				[54.0, "HAVE YOU SEEN THE SNOWMAN?|WHO BUILT IT? WE NEED TO KNOW"], [61.0, "TRY: NEBULA SWIRL|OR PLAIN. PLAIN IS ALSO GOOD."],
				[67.0, "BRAIN FREEZE?|KEEP DRIVING"], [74.0, "FLURRY'S COMET CREAMERY|COLDEST CONES IN THE GALAXY"]],
		"storms": [[48.0, 0.0, 2400.0], [58.0, 300.0, 2200.0], [68.0, -300.0, 2400.0]],
		"fields": [["IceField", 52.0, false, Vector3(2200.0, 700.0, 2600.0), 300, 3501,
				PackedColorArray([Color(0.75, 0.9, 1.0), Color(0.6, 0.8, 0.9), Color(0.85, 0.95, 0.95), Color(0.75, 0.7, 0.95)])],
				["IceField2", 64.0, false, Vector3(2200.0, 700.0, 2600.0), 320, 3502,
				PackedColorArray([Color(0.75, 0.9, 1.0), Color(0.6, 0.8, 0.9), Color(0.85, 0.95, 0.95), Color(0.75, 0.7, 0.95)])]],
		"haulers": [["IceHauler", BOX_HAULER, Color(0.75, 0.85, 1.0), "COMET ICE HAULER"], ["SnowPlow", CAPSULE_HAULER, Color(1.0, 0.75, 0.3), "SPACE SNOWPLOW (OFF DUTY)"]],
	})
	quit()


func _build_road(road_data: Dictionary) -> void:
	var end: Vector3 = road_data["end"]
	_along = (end - START).normalized()
	_yaw = atan2(-_along.x, -_along.z)
	var length := START.distance_to(end) / 1000.0
	var last := length - 2.4  # The road ends where the station's rock shell begins.
	var color: Color = road_data["color"]
	var road := Node3D.new()
	road.name = road_data["name"]

	# (No highway signs or border gate: the developer found the giant signs
	# corny. The HUD still says when you enter a system.)

	for mark: Array in road_data["landmarks"]:
		var landmark := _thing(road, LANDMARK, mark[1], mark[2], mark[3], mark[4])
		landmark.set("kind", mark[0])
		landmark.set("log_id", mark[5])
		if not (mark[6] as String).is_empty():
			landmark.set("label", mark[6])

	var side := 1.0
	for board_data: Array in road_data["billboards"]:
		var ad := (board_data[1] as String).split("|")
		var billboard := _thing(road, BILLBOARD, "Billboard%dKm" % roundi(board_data[0] * 10.0), board_data[0], side * 520.0, 120.0)
		billboard.set("headline", ad[0])
		billboard.set("tagline", ad[1])
		billboard.set("log_id", "billboard")
		side = -side

	# The gimmick on the lane: weather you drive right through.
	for storm_data: Array in road_data["storms"]:
		var storm := _thing(road, HAZARD, "Storm%dKm" % roundi(storm_data[0]), storm_data[0], storm_data[1], 0.0)
		storm.set("kind", 0)  # HazardZone.Kind.ION_STORM
		storm.set("radius", storm_data[2])
		storm.set("tint", color)
		storm.set("log_id", "ion_storm")

	# Things to weave through (bonkable).
	for field_data: Array in road_data["fields"]:
		var field := _thing(road, FIELD, field_data[0], field_data[1], 0.0, 0.0)
		field.set("junk", field_data[2])
		field.set("field_size", field_data[3])
		field.set("rock_count", field_data[4])
		field.set("field_seed", field_data[5])
		field.set("landmark_count", 0)
		field.set("keep_clear_spots", PackedVector3Array())
		if not field_data[2]:
			field.set("rock_radius_range", Vector2(4.0, 30.0))
		if not (field_data[6] as PackedColorArray).is_empty():
			field.set("rock_colors", field_data[6])

	# Traffic going back and forth along the road.
	var haulers: Array = road_data["haulers"]
	for i in haulers.size():
		var hauler: Array = haulers[i]
		var off := 240.0 if i % 2 == 0 else -280.0
		var up := 90.0 if i % 2 == 0 else -70.0
		var ship := Node3D.new()
		ship.set_script(load(TRAFFIC))
		ship.name = hauler[0]
		ship.set("visual_scene", load(hauler[1]))
		ship.set("waypoints", PackedVector3Array([spot(1.5, off, up), spot(last * 0.35, off * 1.2, up), spot(last * 0.7, off, up + 40.0),
				spot(last - 1.0, off, up), spot(last - 0.5, -off, up), spot(last * 0.7, -off, up - 40.0), spot(last * 0.35, -off * 1.2, up), spot(1.5, -off, up)]))
		ship.set("speed", 60.0 + i * 20.0)
		ship.set("start_fraction", 0.25 + i * 0.4)
		ship.set("engine_trail_color", hauler[2])
		ship.set("hull_size", Vector3(14.0, 7.0, 34.0))
		ship.set("id_label", hauler[3])
		road.add_child(ship)

	# The spaceway: reflector beacons in the system's colors all the way.
	var way := MultiMeshInstance3D.new()
	way.set_script(load(SPACEWAY))
	way.name = "Spaceway" + String(road_data["name"]).trim_suffix("Road")
	way.set("points", PackedVector3Array([spot(0.9, 0.0, 0.0), spot(last, 0.0, 0.0)]))
	way.set("spacing", 200.0)
	way.set("half_width", 80.0)
	way.set("left_color", color)
	way.set("right_color", road_data["second_color"])
	road.add_child(way)

	_save(road, "res://scenes/flight/%s.tscn" % road_data["name"])


## A spot on the current road: `km` along it, `side` meters to the right
## (negative = left), `up` meters above.
func spot(km: float, side: float, up: float) -> Vector3:
	var right := _along.cross(Vector3.UP).normalized()
	var road_up := right.cross(_along).normalized()
	return START + _along * km * 1000.0 + right * side + road_up * up


func _thing(road: Node3D, script_path: String, thing_name: String, km: float, side: float, up: float) -> Node3D:
	var thing := Node3D.new()
	thing.set_script(load(script_path))
	thing.name = thing_name
	thing.position = spot(km, side, up)
	# Faces travelers coming from the truck stop, tipped to match the road's
	# climb (these roads climb and dive steeply).
	thing.rotation = Vector3(asin(_along.y), _yaw, 0.0)
	road.add_child(thing)
	return thing


func _save(scene_root: Node, path: String) -> void:
	for child in scene_root.get_children():
		child.owner = scene_root
	var scene := PackedScene.new()
	var error := scene.pack(scene_root)
	if error == OK:
		error = ResourceSaver.save(scene, path)
	print("%s: %s" % [path, error_string(error)])
	scene_root.free()
