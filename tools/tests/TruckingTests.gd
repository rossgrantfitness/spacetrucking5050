extends "res://tools/tests/TestSuite.gd"
## Checks the trucker skills and choices: pro docking's rules and tips (the
## flying part is in tools/smoke_pro_docking.gd).


func _fit(across: float, speed: float, facing: float) -> Dictionary:
	return {"across": across, "along": 0.0, "speed": speed, "facing": facing}


func test_parking_needs_slow_centered_and_straight() -> void:
	var tuning := GameState.tuning
	check(ProDocking.is_parked(_fit(0.0, 0.5, 1.0), tuning), "slow, centered, nose in: parked")
	check(ProDocking.is_parked(_fit(0.0, 0.5, -1.0), tuning), "slow, centered, backed in: parked")
	check(not ProDocking.is_parked(_fit(0.0, tuning.pro_dock_max_speed + 1.0, 1.0), tuning), "too fast isn't parked")
	check(not ProDocking.is_parked(_fit(tuning.pro_dock_bay_radius, 0.5, 1.0), tuning), "off to the side isn't parked")
	check(not ProDocking.is_parked(_fit(0.0, 0.5, 0.0), tuning), "sideways isn't parked")
	var far := _fit(0.0, 0.5, 1.0)
	far["along"] = tuning.pro_dock_bay_depth
	check(not ProDocking.is_parked(far, tuning), "out past the end of the bay isn't parked")


func test_neater_parks_and_backing_in_tip_more() -> void:
	var tuning := GameState.tuning
	var perfect := ProDocking.score(_fit(0.0, 0.0, 1.0), tuning)
	var sloppy := ProDocking.score(_fit(tuning.pro_dock_bay_radius * 0.5, tuning.pro_dock_max_speed * 0.9, 0.95), tuning)
	var backed := ProDocking.score(_fit(0.0, 0.0, -1.0), tuning)
	check(perfect["grade"] == "PERFECT" and int(perfect["tip"]) == tuning.pro_dock_tip, "a perfect nose-in park gets the full tip")
	check(int(sloppy["tip"]) < int(perfect["tip"]) and sloppy["grade"] != "PERFECT", "a sloppy park tips less")
	check(backed["backed_in"] and int(backed["tip"]) > int(perfect["tip"]), "backing in tips more")
	check(int(sloppy["tip"]) > 0, "any park gets something")


func test_routes_make_sense() -> void:
	var kinds := {}
	for route in GameState.routes.routes:
		kinds[route.kind] = true
		check(route.length() > 3000.0, "%s should be a proper stretch of road" % route.id)
		if route.kind == "toll":
			check(route.toll > 0 and route.current_speed > 100.0, "%s should cost something and carry you fast" % route.id)
		if route.kind == "scenic":
			check(GameState.sights.find(route.sight_id) != null, "%s's view should be in the logbook" % route.id)
	check(kinds.has("toll") and kinds.has("shortcut") and kinds.has("scenic"), "there should be a toll lane, a shortcut and a scenic way")


func test_the_chart_offers_route_choices() -> void:
	var spots := {}
	for place in GameState.places.places:
		if place.on_the_map:
			spots[place.id] = place.map_position
	var found := {}
	for pair in [["truck_stop", "tidewater"], ["high_roller", "arboretum"], ["truck_stop", "arboretum"]]:
		var from: Vector3 = spots[pair[0]] + Vector3(0.0, 0.0, 3000.0)
		for stops in CourseChart.possible_courses(from, spots, pair[1]):
			if stops[stops.size() - 1] == pair[1] and stops[0].begins_with(CourseChart.ROUTE_PREFIX):
				found[GameState.routes.find(stops[0].trim_prefix(CourseChart.ROUTE_PREFIX)).kind] = true
	check(found.has("toll"), "the truck stop to Tidewater should offer the toll turnpike")
	check(found.has("shortcut"), "the Glimmer System to Greenhouse Reach should offer the shortcut through the rocks")
	check(found.has("scenic"), "the truck stop to Greenhouse Reach should offer the scenic way")


func test_newtonian_fuel_is_the_burns() -> void:
	var rig: ShipData = load("res://data/ships/starter_rig.tres")
	var tuning := GameState.tuning.duplicate() as Tuning
	tuning.newtonian_flight = true
	var straight := PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -60000)])
	var long_straight := PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -120000)])
	var zigzag := PackedVector3Array([Vector3.ZERO, Vector3(20000, 0, -20000), Vector3(0, 0, -40000), Vector3(0, 0, -60000)])
	check(is_equal_approx(CourseChart.fuel_for(straight, rig, tuning), CourseChart.fuel_for(long_straight, rig, tuning)), "coasting is free: a longer straight run costs the same")
	check(CourseChart.fuel_for(zigzag, rig, tuning) > CourseChart.fuel_for(straight, rig, tuning), "turns cost fuel")
	check(CourseChart.fuel_for(straight, rig, tuning, 400.0) > CourseChart.fuel_for(straight, rig, tuning), "braking from the toll lane's current costs fuel")


func test_rest_stops_are_built_from_data() -> void:
	var stops := 0
	for place in GameState.places.places:
		if place.rest_stop == "none":
			continue
		stops += 1
		check(not place.takes_freight and place.kind == PlaceData.Kind.DRIVE_THROUGH, "%s is a drive-through with no freight" % place.id)
		check("fuel" in place.services, "%s sells fuel" % place.id)
		var stop := RestStop.build(place)
		check(stop.has_node("DockPoint") and stop.has_node("ApproachRing") and stop.has_node("ApproachRing2") and stop.has_node("LaunchPoint"), "%s gets a dock, two rings and a launch point" % place.id)
		check(stop.position.is_equal_approx(place.map_position), "%s sits where its data says" % place.id)
		stop.free()
	check(stops >= 3, "a diner, a fuel depot and a weigh station")


func test_a_weigh_slip_pays_a_little_extra() -> void:
	SaveSystem.save_path = "user://test_trucking_save.json"
	var before := GameState.to_save_data()
	GameState.new_game()
	var job := GameState.jobs.find("glow_guppies")
	GameState.accept_job(job)
	check(float(GameState.rig["weighed"]) == 0.0, "a new load isn't weighed yet")
	GameState.rig["weighed"] = 1.0
	GameState.deliver_at(job.to_place)
	var slip := int(GameState.pending_payout.get("weigh", 0))
	check(slip > 0 and slip < job.base_pay * 0.2, "a certified load earns a small weigh slip (%d)" % slip)
	GameState.accept_job(job)
	GameState.rig["weighed"] = 0.5  # (Overweight: fined, no slip.)
	GameState.deliver_at(job.to_place)
	check(int(GameState.pending_payout.get("weigh", 0)) == 0, "an overweight load gets no slip")
	GameState.apply_save_data(before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_trucking_save.json"))
	SaveSystem.save_path = "user://save.json"
