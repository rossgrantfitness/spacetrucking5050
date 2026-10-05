extends "res://tools/tests/TestSuite.gd"
## Checks for the Glimmer System (round 11): Sal's casino, The High Roller,
## its place in space and on foot, the jobs and Sal's story, the road's
## landmarks, the system's own route events and the slot machine.

const FLIGHT_SCENE := preload("res://scenes/flight/FlightSandbox.tscn")
const LOUNGE_SCENE := preload("res://scenes/hub/HighRollerLounge.tscn")
const ROAD_SCENE := preload("res://scenes/flight/GlimmerRoad.tscn")
const SCRATCH_SAVE := "user://test_save.json"


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


func test_glimmer_is_a_system_with_a_casino() -> void:
	var glimmer := GameState.systems.find("glimmer")
	check(glimmer != null, "the Glimmer System is in the system list")
	var casino := GameState.places.find("high_roller")
	check(casino != null and casino.kind == PlaceData.Kind.INTERIOR, "The High Roller is a place you can climb out at")
	check(casino != null and casino.host != null and casino.host.species == "crocodile", "Sal (a crocodile) hosts it")
	check(ResourceLoader.exists(casino.interior_scene), "its inside exists")
	var lounge := LOUNGE_SCENE.instantiate()
	check(lounge.get_node_or_null("Spawns/" + casino.arrival_spawn) != null, "you climb out at the airlock")
	check(lounge.get_node_or_null("People/Sal") != null, "Sal is there")
	var exit := lounge.get_node_or_null("Exits/Airlock")
	check(exit != null and exit.get("launch_from") == "high_roller", "the airlock takes off from the casino")
	lounge.free()


func test_the_casino_is_out_in_space_a_long_haul_away() -> void:
	var world := FLIGHT_SCENE.instantiate()
	var place := world.get_node_or_null("World/Places/high_roller") as Node3D
	check(place != null, "the casino is in the flight scene")
	if place == null:
		world.free()
		return
	for part in ["DockPoint", "ApproachRing", "LaunchPoint", "HighRollerStation"]:
		check(place.get_node_or_null(part) != null, "the casino has its %s" % part)
	var glimmer := GameState.systems.find("glimmer")
	check(place.position.distance_to(glimmer.center) < 100.0, "the casino is at the middle of the Glimmer System")
	var truck_stop := world.get_node("World/Places/truck_stop") as Node3D
	var launch := truck_stop.transform * (truck_stop.get_node("LaunchPoint") as Node3D).position
	var ring := place.transform * (place.get_node("ApproachRing") as Node3D).position
	var numbers := CourseChart.estimate(PackedVector3Array([launch, ring]), load("res://data/ships/starter_rig.tres"), GameState.tuning, 1.0)
	var minutes: float = numbers["cruise_seconds"] / 60.0
	check(minutes > 14.0 and minutes < 19.0, "cruising to the casino is a long haul, like Tidewater (it's %.1f min)" % minutes)
	# The bay faces the truck stop, so you fly straight in.
	var bay_facing := place.global_transform.basis.z if place.is_inside_tree() else place.transform.basis.z
	check(bay_facing.dot((truck_stop.position - place.position).normalized()) > 0.9, "the casino's docking bay faces the road in")
	world.free()


func test_the_road_to_glimmer() -> void:
	var road := ROAD_SCENE.instantiate()
	var kinds := {}
	var billboards := 0
	for node in road.get_children():
		var log_id: Variant = node.get("log_id")
		if log_id is String and not (log_id as String).is_empty():
			check(GameState.sights.find(log_id) != null, "%s on the Glimmer road has a logbook entry" % node.name)
		if node is Landmark:
			kinds[(node as Landmark).kind] = true
		if node is Billboard:
			billboards += 1
	check(kinds.has(Landmark.Kind.BORDER_GATE), "a border gate into Glimmer")
	check(kinds.has(Landmark.Kind.SLOT_MACHINE) and kinds.has(Landmark.Kind.DICE) and kinds.has(Landmark.Kind.CHAPEL), "the slot machine, the dice and the chapel")
	check(billboards >= 10, "neon billboards everywhere (the Glimmer gimmick)")
	road.free()
	# The new landmarks build without trouble.
	for kind: Landmark.Kind in [Landmark.Kind.SLOT_MACHINE, Landmark.Kind.DICE, Landmark.Kind.CHAPEL]:
		var landmark := Landmark.new()
		landmark.kind = kind
		_tree().root.add_child(landmark)
		check(landmark.get_child_count() >= 3, "landmark %d builds itself" % kind)
		landmark.free()


func test_glimmer_jobs_line_up() -> void:
	for id in ["glimmer_cards", "sal_jumpsuits", "sal_slot_machine", "slot_parts", "poker_chips", "buffet_leftovers", "neon_tubes", "fuzzy_dice", "kelp_caviar"]:
		var job := GameState.jobs.find(id)
		check(job != null, "job %s is in the job list" % id)
		if job == null:
			continue
		check(GameState.places.find(job.from_place) != null and GameState.places.find(job.to_place) != null, "%s goes between real places" % id)
		check(job.from_place == "high_roller" or job.to_place == "high_roller", "%s comes from or goes to the casino" % id)
	var cards := GameState.jobs.find("glimmer_cards")
	check(cards.completes_flag == "glimmer_open" and cards.from_place == "base", "the cards come from dispatch (aboard the rig) and open up Glimmer")
	check(GameState.jobs.find("sal_jumpsuits").requires_flag == "glimmer_open", "Sal's first story job waits for the first delivery")
	check(GameState.jobs.find("sal_slot_machine").requires_flag == "sal_jumpsuits_done", "his second waits for the first")


func test_sals_story_goes_in_order() -> void:
	var before := _fresh()
	var sal: NPCData = load("res://data/npcs/casino_sal.tres")
	check(sal.pick_conversation().offers_job == null, "before the cards, Sal just says hello")
	GameState.set_flag("first_mission_done")
	GameState.set_flag("met_marge")
	check(GameState.board_jobs("high_roller").is_empty(), "nothing on the casino's board before Glimmer opens")
	GameState.set_flag("glimmer_heard")
	GameState.accept_job(GameState.jobs.find("glimmer_cards"))
	check(GameState.deliver_at("high_roller"), "the cards deliver at the casino")
	check(GameState.has_flag("glimmer_open"), "...which opens up Glimmer")
	check(not GameState.board_jobs("high_roller").is_empty(), "the casino's board has loads now")
	var meet := sal.pick_conversation()
	check(meet != null and "sal_met" in meet.sets_flags, "then Sal introduces himself")
	GameState.set_flag("sal_met")
	var pitch := sal.pick_conversation()
	check(pitch != null and pitch.offers_job != null and pitch.offers_job.id == "sal_jumpsuits", "then he offers the jumpsuits")
	GameState.accept_job(GameState.jobs.find("sal_jumpsuits"))
	GameState.deliver_at("truck_stop")
	var marge: NPCData = load("res://data/npcs/truckstop_control.tres")
	var sequins := marge.pick_conversation()
	check(sequins != null and "marge_sequins" in sequins.sets_flags, "Marge loves the sequins")
	var next := sal.pick_conversation()
	check(next != null and next.offers_job != null and next.offers_job.id == "sal_slot_machine", "then the slot machine for Gill")
	GameState.accept_job(GameState.jobs.find("sal_slot_machine"))
	GameState.deliver_at("tidewater")
	var gill: NPCData = load("res://data/npcs/tidewater_gill.tres")
	var why := gill.pick_conversation()
	check(why != null and "gill_slot" in why.sets_flags, "Gill asks why")
	var rig := sal.pick_conversation()
	check(rig != null and "sal_mentioned_rig" in rig.sets_flags, "and Sal remembers someone who drove a rig like hers")
	_restore(before)


func test_glimmer_route_events_stay_in_glimmer() -> void:
	var found := 0
	for event in RouteEvents.EVENTS.events:
		if event != null and event.id in ["glimmer_billboard", "limo_convoy", "channel19_winner", "sal_calls"]:
			found += 1
			check(event.allowed_in("glimmer") and not event.allowed_in("tidewater") and not event.allowed_in("home"), "%s only happens in Glimmer" % event.id)
	check(found == 4, "Glimmer has its own route events")


func test_the_slot_machine_pays_less_than_it_takes() -> void:
	var tuning := GameState.tuning
	check(HubServices.slots_payout(PackedStringArray(["SEVEN", "SEVEN", "SEVEN"]), tuning) == tuning.slots_jackpot_pays, "three SEVENs is the jackpot")
	check(HubServices.slots_payout(PackedStringArray(["BELL", "BELL", "BELL"]), tuning) == tuning.slots_three_pays, "three alike pays")
	check(HubServices.slots_payout(PackedStringArray(["BELL", "BAR", "BELL"]), tuning) == tuning.slots_pair_pays, "two alike pays a little")
	check(HubServices.slots_payout(PackedStringArray(["BELL", "BAR", "CROC"]), tuning) == 0, "nothing alike pays nothing")
	# Every possible spin, equally likely: how much comes back per pull?
	var symbols := HubServices.SLOT_SYMBOLS
	var paid := 0
	var spins := 0
	for a in symbols:
		for b in symbols:
			for c in symbols:
				paid += HubServices.slots_payout(PackedStringArray([a, b, c]), tuning)
				spins += 1
	var back := float(paid) / float(spins * tuning.slots_price)
	check(back < 1.0, "over time, the house wins (it gives back %.0f%%)" % (back * 100.0))
	check(back > 0.75, "...but only a little (it gives back %.0f%%)" % (back * 100.0))
