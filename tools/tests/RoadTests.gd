extends "res://tools/tests/TestSuite.gd"
## Checks for the round-8 long haul: the size of the road to Tidewater,
## the course chart's numbers and choices, the cruise autopilot, solar
## system colors, sky bodies and hazards. (The route events have their own
## tests: RouteEventTests.gd.)

const FLIGHT_SCENE := preload("res://scenes/flight/FlightSandbox.tscn")
const SHIP_SCENE := preload("res://scenes/flight/Ship.tscn")


## Where each place is in the flight scene, and its first approach ring.
func _place_spots() -> Dictionary:
	var world := FLIGHT_SCENE.instantiate()
	var spots := {}
	for place: Node3D in world.get_node("World/Places").get_children():
		var ring := place.get_node_or_null("ApproachRing") as Node3D
		spots[place.name] = {"place": place.position, "ring": place.transform * ring.position if ring != null else place.position,
				"launch": place.transform * (place.get_node("LaunchPoint") as Node3D).position}
	world.free()
	return spots


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func test_the_long_haul_is_18_minutes_cruising_and_4_5_on_full_boost() -> void:
	var spots := _place_spots()
	var route := PackedVector3Array([spots["truck_stop"]["launch"], spots["tidewater"]["ring"]])
	var rig := load("res://data/ships/starter_rig.tres") as ShipData
	var numbers := CourseChart.estimate(route, rig, GameState.tuning, 1.0)
	var minutes: float = numbers["cruise_seconds"] / 60.0
	var boost_minutes: float = numbers["boost_seconds"] / 60.0
	check(minutes > 16.5 and minutes < 19.0, "cruising to Tidewater should take about 18 minutes (it's %.1f)" % minutes)
	check(boost_minutes > 4.0 and boost_minutes < 5.0, "boosting all the way should take about 4.5 minutes (it's %.1f)" % boost_minutes)
	check(numbers["boost_needed"] <= 1.0, "a full boost tank should last the whole way")
	check(numbers["fuel"] < 0.8, "a full fuel tank should cruise there with fuel to spare")
	var half := CourseChart.estimate(route, rig, GameState.tuning, 0.5)
	check(half["boost_seconds"] > numbers["boost_seconds"], "with half a boost tank, it takes longer")


func test_course_chart_offers_the_gas_n_go_when_its_on_the_way() -> void:
	var spots := _place_spots()
	var places := {}
	for id: String in spots:
		places[id] = spots[id]["place"]
	var from_truck_stop := CourseChart.possible_courses(spots["truck_stop"]["launch"], places, "tidewater")
	check(not from_truck_stop.is_empty() and from_truck_stop[0] == PackedStringArray(["tidewater"]), "the job's destination comes first")
	check(PackedStringArray(["gas_n_go", "tidewater"]) in from_truck_stop, "Tidewater via the Gas-N-Go is offered (it's on the way)")
	check(not PackedStringArray(["truck_stop"]) in from_truck_stop, "the place you're sitting at isn't offered")
	var from_base := CourseChart.possible_courses(spots["base"]["launch"], places, "")
	check(not PackedStringArray(["gas_n_go", "truck_stop"]) in from_base, "the Gas-N-Go isn't on the way to the truck stop")


func test_systems_blend_by_distance() -> void:
	var world := FLIGHT_SCENE.instantiate()
	var systems: Array[SystemData] = GameState.systems.systems
	world.set("systems", systems)  # (The scene fills this in itself when it starts.)
	check(systems.size() == 3, "there are three systems: home, Tidewater and Glimmer")
	var at_home: PackedFloat32Array = world.call("system_weights", systems[0].center)
	var halfway: PackedFloat32Array = world.call("system_weights", (systems[0].center + systems[1].center) * 0.5)
	var at_tidewater: PackedFloat32Array = world.call("system_weights", systems[1].center)
	var at_glimmer: PackedFloat32Array = world.call("system_weights", systems[2].center)
	check(at_home[0] > 0.99, "at home, it's all home colors")
	check(absf(halfway[0] - halfway[1]) < 0.01 and halfway[0] > 0.45, "halfway to Tidewater, the colors are half and half")
	check(at_tidewater[1] > 0.99, "at Tidewater, it's all Tidewater colors")
	check(at_glimmer[2] > 0.99, "at Glimmer, it's all Glimmer colors")
	check(systems[1].signature_color != systems[0].signature_color, "Tidewater has its own color")
	check(systems[2].signature_color != systems[0].signature_color and systems[2].signature_color != systems[1].signature_color, "Glimmer has its own color")
	world.free()


func test_sky_bodies_look_the_right_size() -> void:
	var planet := SkyBody.new()
	planet.true_radius = 1000.0
	planet.true_position = Vector3(0.0, 0.0, -1000.0)
	check(is_equal_approx(planet.apparent_size(Vector3.ZERO), PI / 4.0), "a planet as far away as it is wide looks 45 degrees big")
	check(planet.apparent_size(Vector3(0.0, 0.0, 50000.0)) < 0.03, "from far away it's small")
	check(planet.direction_from(Vector3.ZERO).is_equal_approx(Vector3.FORWARD), "it's straight ahead")
	planet.free()


func test_cruise_autopilot_steers_gently_toward_its_course() -> void:
	var ship: Ship = SHIP_SCENE.instantiate()
	_tree().root.add_child(ship)
	ship.teleport(Transform3D.IDENTITY)  # At the middle of the world, nose along -Z.
	var pilot := CruisePilot.new()
	pilot.waypoints = [Vector3(800.0, 0.0, -1000.0)]
	var hands := pilot.steer(ship, 0.016)
	check(hands.steer.x > 0.0 and hands.thrust > 0.0 and not hands.boost, "a spot ahead and to the right: steer right, throttle on, no boost")
	pilot.waypoints = [Vector3(-800.0, 400.0, -1000.0)]
	hands = pilot.steer(ship, 0.016)
	check(hands.steer.x < 0.0 and hands.steer.y > 0.0, "a spot to the left and up: steer left, nose up")
	ship.flight.velocity = Vector3(0.0, 0.0, -55.0)
	var gentle := GameState.tuning.cargo_comfy_accel / 55.0
	pilot.waypoints = [Vector3(3000.0, 0.0, 0.0)]
	hands = pilot.steer(ship, 0.016)
	var turn := absf(hands.steer.x) * deg_to_rad(ship.ship_data.turn_rate)
	check(turn <= gentle, "even a hard turn is gentle enough not to rattle the cargo")
	pilot.waypoints = [Vector3(0.0, 0.0, -100.0)]
	pilot.steer(ship, 0.016)
	check(pilot.is_done(), "reaching the last spot finishes the course")
	ship.free()


func test_cruise_autopilot_steers_around_things() -> void:
	var ship: Ship = SHIP_SCENE.instantiate()
	_tree().root.add_child(ship)
	ship.teleport(Transform3D.IDENTITY)
	var junk := RoadsideThing.new()
	_tree().root.add_child(junk)
	junk.global_position = Vector3(8.0, 0.0, -200.0)  # Dead ahead, a little right.
	junk.show_on_radar("SPILLED LOAD", 30.0)
	check(CruisePilot.avoidance(ship).x < 0.0, "something ahead and a little right: lean left")
	junk.global_position = Vector3(400.0, 0.0, -200.0)
	check(CruisePilot.avoidance(ship).is_zero_approx(), "something well off to the side: carry on")
	junk.free()
	ship.free()


func test_touching_the_controls_takes_over() -> void:
	var hands := FlightControls.new()
	check(not hands.is_touched(), "hands off the controls")
	hands.steer = Vector2(0.1, 0.05)
	check(not hands.is_touched(), "a tiny nudge doesn't count")
	hands.steer = Vector2(0.6, 0.0)
	check(hands.is_touched(), "a real steer takes over")
	hands.steer = Vector2.ZERO
	hands.boost = true
	check(hands.is_touched(), "boosting takes over")


func test_the_autopilot_forgives_small_nudges() -> void:
	var tuning := GameState.tuning
	var pilot := CruisePilot.new()
	var hands := FlightControls.new()
	hands.steer = Vector2(tuning.autopilot_tolerance * 0.8, 0.0)
	var taken := false
	for i in 120:  # Two seconds of a small nudge.
		taken = taken or pilot.feel_hands(hands, 1.0 / 60.0)
	check(not taken, "a small nudge, even held, doesn't take over from the autopilot")
	var auto := FlightControls.new()
	CruisePilot.mix_in(auto, hands, tuning)
	check(auto.steer.x > 0.0, "the nudge still moves the rig a little")
	hands.steer = Vector2(1.0, 0.0)
	var frames := 0
	while not pilot.feel_hands(hands, 1.0 / 60.0) and frames < 600:
		frames += 1
	check(frames > 5 and frames < 60, "a full push held for a moment takes over (took %d frames)" % frames)
	var flick := CruisePilot.new()
	hands.steer = Vector2(1.0, 0.0)
	var flicked := false
	for i in 6:  # A tenth of a second.
		flicked = flicked or flick.feel_hands(hands, 1.0 / 60.0)
	hands.steer = Vector2.ZERO
	for i in 60:
		flicked = flicked or flick.feel_hands(hands, 1.0 / 60.0)
	check(not flicked and flick.grab == 0.0, "a quick flick is forgiven, and the grab fades away")
	hands.boost = true
	check(CruisePilot.new().feel_hands(hands, 1.0 / 60.0), "boost takes over at once")


func test_hazards_affect_the_rig() -> void:
	var ship: Ship = SHIP_SCENE.instantiate()
	_tree().root.add_child(ship)
	ship.teleport(Transform3D.IDENTITY)
	var storm := HazardZone.new()
	storm.kind = HazardZone.Kind.ION_STORM
	storm.radius = 1000.0
	_tree().root.add_child(storm)
	check(storm.influence(ship).get("storm", 0.0) > 0.9, "in the middle of a storm, it's stormy")
	storm.global_position = Vector3(0.0, 0.0, -5000.0)
	check(is_zero_approx(storm.influence(ship).get("storm", 1.0)), "far from the storm, it's calm")
	var trap := HazardZone.new()
	trap.kind = HazardZone.Kind.SPEED_TRAP
	trap.radius = 1000.0
	_tree().root.add_child(trap)
	var tickets: Array[int] = []
	trap.caught_speeding.connect(func(kmh: int) -> void: tickets.append(kmh))
	ship.flight.velocity = Vector3(0.0, 0.0, -30.0)  # 108 km/h: legal.
	trap.influence(ship)
	check(tickets.is_empty(), "under the limit, no ticket")
	ship.flight.velocity = Vector3(0.0, 0.0, -150.0)  # 540 km/h: boosting past the cops.
	trap.influence(ship)
	trap.influence(ship)
	check(tickets.size() == 1, "speeding past gets one ticket, not one per frame")
	check(trap.influence(ship).get("speed_trap", 0.0) > 0.9, "the radar detector lights up near a trap")
	storm.free()
	trap.free()
	ship.free()
