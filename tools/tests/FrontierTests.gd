extends "res://tools/tests/TestSuite.gd"
## Checks for Beta 4's three far systems: the Dustbowl (Mags's salvage yard),
## Greenhouse Reach (Dr. Moss's arboretum) and the Frostline (Penny's
## creamery). Their places in space and on foot, the roads out, the jobs, the
## clients' stories, Raccoony's calls that open each one, and the gentle
## difficulty curve (each farther, steeper and stormier than the last).

const FLIGHT_SCENE := preload("res://scenes/flight/FlightSandbox.tscn")
const SCRATCH_SAVE := "user://test_save.json"

## [system, place, host species, room scene, client node, road scene, station node]
const FRONTIER: Array = [
	["dustbowl", "salvage_yard", "goat", "res://scenes/hub/SalvageYard.tscn", "Mags", "res://scenes/flight/DustbowlRoad.tscn", "SalvageYardStation"],
	["greenhouse", "arboretum", "tortoise", "res://scenes/hub/Arboretum.tscn", "Moss", "res://scenes/flight/GreenhouseRoad.tscn", "ArboretumStation"],
	["frostline", "creamery", "penguin", "res://scenes/hub/Creamery.tscn", "Penny", "res://scenes/flight/FrostlineRoad.tscn", "CreameryStation"],
]


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _fresh() -> Dictionary:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	return before


func _restore(before: Dictionary) -> void:
	GameState.apply_save_data(before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_SAVE))
	SaveSystem.save_path = "user://save.json"


## As if she heard `talk` all the way through: its flags, its order, and
## (if it offers a job) saying yes.
func _hear(talk: Conversation) -> void:
	for flag in talk.sets_flags:
		GameState.set_flag(flag)
	if talk.places_order != null:
		GameState.place_order(talk.places_order.id)
	if talk.offers_job != null:
		GameState.accept_job(talk.offers_job)


func test_each_far_system_has_a_place_to_climb_out() -> void:
	for row: Array in FRONTIER:
		var system := GameState.systems.find(row[0])
		check(system != null, "the %s is in the system list" % row[0])
		var place := GameState.places.find(row[1])
		check(place != null and place.kind == PlaceData.Kind.INTERIOR, "%s is a place you can climb out at" % row[1])
		if place == null:
			continue
		check(place.host != null and place.host.species == row[2], "a %s runs %s" % [row[2], row[1]])
		check(place.interior_scene == row[3] and ResourceLoader.exists(place.interior_scene), "%s's inside exists" % row[1])
		var room := (load(row[3]) as PackedScene).instantiate()
		check(room.get_node_or_null("Spawns/" + place.arrival_spawn) != null, "you climb out at %s's airlock" % row[1])
		check(room.get_node_or_null("People/" + row[4]) != null, "%s is there" % row[4])
		var exit := room.get_node_or_null("Exits/Airlock")
		check(exit != null and exit.get("launch_from") == row[1], "the airlock takes off from %s" % row[1])
		for thing in ["JobBoard", "Pump", "Jukebox", "Window"]:
			check(room.get_node_or_null("Things/" + thing) != null, "%s has a %s" % [row[1], thing])
		check(room.get("place_id") == row[1], "the room knows it's %s" % row[1])
		room.free()


func test_far_stations_are_out_in_space_steep_and_far() -> void:
	var world := FLIGHT_SCENE.instantiate()
	var truck_stop := world.get_node("World/Places/truck_stop") as Node3D
	var launch := truck_stop.transform * (truck_stop.get_node("LaunchPoint") as Node3D).position
	var glimmer := world.get_node("World/Places/high_roller") as Node3D
	var glimmer_ring := glimmer.transform * (glimmer.get_node("ApproachRing") as Node3D).position
	var last_minutes: float = CourseChart.estimate(PackedVector3Array([launch, glimmer_ring]), load("res://data/ships/starter_rig.tres"), GameState.tuning, 1.0)["cruise_seconds"] / 60.0
	for row: Array in FRONTIER:
		var place := world.get_node_or_null("World/Places/" + row[1]) as Node3D
		check(place != null, "%s is in the flight scene" % row[1])
		if place == null:
			continue
		for part in ["DockPoint", "ApproachRing", "LaunchPoint", row[6]]:
			check(place.get_node_or_null(part) != null, "%s has its %s" % [row[1], part])
		var system := GameState.systems.find(row[0])
		check(place.position.distance_to(system.center) < 100.0, "%s sits at the middle of its system" % row[1])
		check(place.position.distance_to(GameState.places.find(row[1]).map_position) < 1.0, "%s's map position matches the flight scene" % row[1])
		check(place.transform.basis.z.dot((truck_stop.position - place.position).normalized()) > 0.9, "%s's docking bay faces the road in" % row[1])
		# Steep: well above or below the lane the first systems sit on.
		var climb := absf(place.position.y - truck_stop.position.y) / place.position.distance_to(truck_stop.position)
		check(climb > 0.45, "the road to %s climbs or dives steeply (%.0f%% grade)" % [row[1], climb * 100.0])
		var ring := place.transform * (place.get_node("ApproachRing") as Node3D).position
		var numbers := CourseChart.estimate(PackedVector3Array([launch, ring]), load("res://data/ships/starter_rig.tres"), GameState.tuning, 1.0)
		var minutes: float = numbers["cruise_seconds"] / 60.0
		check(minutes > last_minutes, "%s is farther than the system before it (%.1f min vs %.1f)" % [row[1], minutes, last_minutes])
		check(float(numbers["fuel"]) < 0.95, "the starter rig can cruise to %s on one tank (%.0f%%)" % [row[1], float(numbers["fuel"]) * 100.0])
		last_minutes = minutes
	for body in ["DustbowlPlanet", "GreenhousePlanet", "FrostlinePlanet"]:
		check(world.get_node_or_null("World/SkyBodies/" + body) != null, "%s hangs in the sky" % body)
	world.free()


func test_the_roads_out_get_stormier() -> void:
	var last_storms := 0
	for row: Array in FRONTIER:
		var road := (load(row[5]) as PackedScene).instantiate()
		var gate := false
		var landmarks := 0
		var storms := 0
		var billboards := 0
		for node in road.get_children():
			var log_id: Variant = node.get("log_id")
			if log_id is String and not (log_id as String).is_empty():
				check(GameState.sights.find(log_id) != null, "%s on the road to %s has a logbook entry" % [node.name, row[1]])
			if node is Landmark:
				if (node as Landmark).kind == Landmark.Kind.BORDER_GATE:
					gate = true
				else:
					landmarks += 1
			if node is HazardZone:
				storms += 1
			if node is Billboard:
				billboards += 1
		check(gate, "a border gate into the %s" % row[0])
		check(landmarks >= 2, "roadside attractions on the way to %s" % row[1])
		check(billboards >= 6, "billboards on the way to %s" % row[1])
		check(storms >= 2 and storms >= last_storms, "weather on the lane to %s, no less than before (%d storms)" % [row[1], storms])
		last_storms = storms
		road.free()
	# The new landmarks build without trouble.
	for kind: Landmark.Kind in [Landmark.Kind.SKULL, Landmark.Kind.WINDMILL, Landmark.Kind.TREE, Landmark.Kind.WATERING_CAN, Landmark.Kind.SNOWMAN, Landmark.Kind.CONE]:
		var landmark := Landmark.new()
		landmark.kind = kind
		_tree().root.add_child(landmark)
		check(landmark.get_child_count() >= 3, "landmark %d builds itself" % kind)
		landmark.free()


func test_frontier_jobs_line_up() -> void:
	var ids := ["dustbowl_scrap", "greenhouse_soil", "frostline_cones", "mags_magnet", "mags_beacon", "mags_bell", "moss_bees", "moss_sapling",
			"moss_chairs", "penny_freezer", "penny_flavors", "penny_sign", "scrap_metal", "hubcaps", "dust_masks", "fresh_herbs", "glow_ferns",
			"compost", "comet_ice_cream", "ice_blocks", "sprinkles"]
	for id in ids:
		var job := GameState.jobs.find(id)
		check(job != null, "job %s is in the job list" % id)
		if job == null:
			continue
		check(GameState.places.find(job.from_place) != null and GameState.places.find(job.to_place) != null, "%s goes between real places" % id)
		check(job.from_place in ["salvage_yard", "arboretum", "creamery"] or job.to_place in ["salvage_yard", "arboretum", "creamery"], "%s touches a far system" % id)
		check(job.requires_flag != "", "%s waits for its system to open" % id)
	for pair: Array in [["dustbowl_scrap", "dustbowl"], ["greenhouse_soil", "greenhouse"], ["frostline_cones", "frostline"]]:
		var job := GameState.jobs.find(pair[0])
		check(job.from_place == "base" and job.requires_flag == pair[1] + "_heard" and job.completes_flag == pair[1] + "_open", "%s comes from dispatch and opens the %s" % [pair[0], pair[1]])
	# Jobs a client orders through the company start at the depot, off the boards.
	for npc_path in ["dustbowl_mags", "greenhouse_moss", "frostline_penny"]:
		var npc: NPCData = load("res://data/npcs/%s.tres" % npc_path)
		for talk in npc.conversations:
			if talk.places_order != null:
				check(talk.places_order.from_place == "truck_stop" and not talk.places_order.on_job_board, "%s is ordered through the company" % talk.places_order.id)
			if talk.offers_job != null:
				# Offered in person, but on the board too in case she says no.
				check(talk.offers_job.on_job_board and talk.offers_job.requires_flag in talk.sets_flags, "%s stays on the board if she says no" % talk.offers_job.id)


func test_raccoony_opens_each_system_in_turn() -> void:
	var before := _fresh()
	for flag in ["opening_called", "met_boss", "first_check", "heard_about_marge", "met_marge", "first_mission_done", "glimmer_heard", "glimmer_open"]:
		GameState.set_flag(flag)
	var raccoony: NPCData = load("res://data/npcs/dispatch_morning.tres")
	GameState.deliveries = 4
	var talk := raccoony.pick_conversation()
	check(talk == null or talk.offers_job == null or talk.offers_job.id != "dustbowl_scrap", "not the Dustbowl yet: too early")
	GameState.deliveries = 5
	talk = raccoony.pick_conversation()
	check(talk != null and talk.offers_job != null and talk.offers_job.id == "dustbowl_scrap", "after five deliveries, Raccoony passes on Mags's call")
	_hear(talk)
	check(GameState.deliver_at("salvage_yard"), "the scrap delivers at the salvage yard")
	check(GameState.has_flag("dustbowl_open"), "...which opens the Dustbowl")
	check(not GameState.board_jobs("salvage_yard").is_empty(), "the yard's board has loads now")
	GameState.deliveries = 7
	talk = raccoony.pick_conversation()
	check(talk == null or talk.offers_job == null or talk.offers_job.id != "greenhouse_soil", "not Greenhouse Reach yet")
	GameState.deliveries = 8
	talk = raccoony.pick_conversation()
	check(talk != null and talk.offers_job != null and talk.offers_job.id == "greenhouse_soil", "then Dr. Moss's soil")
	_hear(talk)
	GameState.deliver_at("arboretum")
	GameState.deliveries = 11
	talk = raccoony.pick_conversation()
	check(talk != null and talk.offers_job != null and talk.offers_job.id == "frostline_cones", "then Penny's cones, way up at the Frostline")
	_hear(talk)
	GameState.deliver_at("creamery")
	check(GameState.has_flag("frostline_open"), "...and the Frostline opens")
	_restore(before)


## Plays a client's whole story: each conversation is heard, each job taken
## and delivered where it goes.
func _play_story(npc_path: String, open_flag: String, expected_jobs: Array, last_flag: String) -> void:
	var before := _fresh()
	for flag in ["opening_called", "met_boss", "first_check", "heard_about_marge", "met_marge", "first_mission_done", open_flag]:
		GameState.set_flag(flag)
	var npc: NPCData = load("res://data/npcs/%s.tres" % npc_path)
	var jobs_seen: Array = []
	for step in 30:
		var talk := npc.pick_conversation()
		if talk == null or talk.sets_flags.is_empty():
			break
		_hear(talk)
		var job: JobData = talk.places_order if talk.places_order != null else talk.offers_job
		if job != null:
			jobs_seen.append(job.id)
			if talk.places_order != null:
				check(GameState.waiting_orders().any(func(order: JobData) -> bool: return order.id == job.id), "%s waits at the office" % job.id)
				GameState.accept_job(job)
			check(GameState.active_job_id == job.id, "she's hauling %s" % job.id)
			check(GameState.deliver_at(job.to_place), "%s delivers at %s" % [job.id, job.to_place])
	check(jobs_seen == expected_jobs, "%s's story runs %s (got %s)" % [npc_path, expected_jobs, jobs_seen])
	check(GameState.has_flag(last_flag), "%s's story reaches its end (%s)" % [npc_path, last_flag])
	_restore(before)


func test_mags_story() -> void:
	_play_story("dustbowl_mags", "dustbowl_open", ["mags_magnet", "mags_beacon", "mags_bell"], "mags_after")


func test_moss_story() -> void:
	_play_story("greenhouse_moss", "greenhouse_open", ["moss_bees", "moss_sapling", "moss_chairs"], "moss_bloom_seen")


func test_penny_story() -> void:
	_play_story("frostline_penny", "frostline_open", ["penny_freezer", "penny_flavors", "penny_sign"], "penny_after")


func test_penny_remembers_him_only_after_his_message() -> void:
	var before := _fresh()
	for flag in ["frostline_open", "penny_met", "penny_freezer_done", "penny_offered_flavors", "penny_flavors_done", "penny_called_sign", "penny_sign_done", "penny_after"]:
		GameState.set_flag(flag)
	var penny: NPCData = load("res://data/npcs/frostline_penny.tres")
	check(not "penny_white" in penny.pick_conversation().sets_flags, "before his message, Penny doesn't bring him up")
	GameState.set_flag("white_voicemail")
	var talk := penny.pick_conversation()
	check(talk != null and "penny_white" in talk.sets_flags and talk.marked, "after it, she remembers a trucker with a rig that coughed")
	_restore(before)


func test_frontier_route_events_stay_home() -> void:
	var expected := {"dustbowl": ["dustbowl_billboard", "dust_storm_amber", "dustbowl_wrecks", "mags_calls"],
			"greenhouse": ["greenhouse_billboard", "jelly_bloom", "pollen_storm", "moss_calls"],
			"frostline": ["frostline_billboard", "frost_hail", "frostline_comets", "penny_calls"]}
	for system: String in expected:
		var found := 0
		for event in RouteEvents.EVENTS.events:
			if event != null and event.id in expected[system]:
				found += 1
				check(event.allowed_in(system) and not event.allowed_in("home") and not event.allowed_in("glimmer"), "%s only happens in the %s" % [event.id, system])
		check(found == 4, "the %s has its own route events" % system)
