extends "res://tools/tests/TestSuite.gd"
## Checks for round 9: Jack's name and replies, people remembering things,
## the 20-station radio (regional, pirate, night-only and mystery stations),
## the logbook and rare sights, and the loading screen's lines.
## Every test puts GameState back the way it found it, and saving goes to a
## scratch file, so the player's real save is never touched.

const SCRATCH_SAVE: String = "user://self_test_save.json"
const ROAD_SCENE := preload("res://scenes/flight/TidewaterRoad.tscn")


func _fresh() -> Dictionary:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	return before


func _restore(before: Dictionary) -> void:
	GameState.apply_save_data(before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_SAVE))
	SaveSystem.save_path = "user://save.json"


func test_her_name_is_jack_rabbit() -> void:
	check(GameState.names.bunny_name == "Jack Rabbit", "the bunny's name is Jack Rabbit")
	check(GameState.names.fill_in("Hi, {bunny}.") == "Hi, Jack Rabbit.", "{bunny} fills in her name")


func test_jack_always_has_three_things_to_say_back() -> void:
	var replies: BunnyReplies = load("res://data/dialogue/bunny_replies.tres")
	var rng := RandomNumberGenerator.new()
	check(replies.voice != null and replies.voice.species == "bunny", "Jack replies in her own voice")
	for situation in ChatterSet.Situation.values():
		var picked := replies.pick(situation, 3, rng)
		check(picked.size() == 3, "three replies for situation %d" % situation)
		check(picked[0] != picked[1] and picked[1] != picked[2] and picked[0] != picked[2], "the three replies are all different")


func test_marge_remembers_how_the_pies_arrived() -> void:
	var marge: NPCData = load("res://data/npcs/truckstop_control.tres")
	for cargo: float in [1.0, 0.8, 0.3]:
		var before := _fresh()
		GameState.set_flag("met_marge")
		GameState.accept_job(GameState.jobs.find("first_long_haul"))
		GameState.rig["cargo"] = cargo
		GameState.deliver_at("tidewater")
		var talk := marge.pick_conversation()
		var words := " ".join(talk.lines) if talk != null else ""
		if cargo >= 0.95:
			check("Not one bruised pie" in words, "perfect pies: Marge heard they were perfect")
		elif cargo >= 0.7:
			check("rearranged" in words, "a bit bumped: Marge heard they were rearranged")
		else:
			check("FILLING" in words, "wrecked pies: Marge heard it was pie filling")
		check(GameState.deliveries == 1, "deliveries are counted")
		_restore(before)


func test_moe_finishes_his_sentence_next_visit() -> void:
	var before := _fresh()
	var moe: PlaceData = GameState.places.find("gas_n_go")
	var rng := RandomNumberGenerator.new()
	check(moe.host_lines_in_order, "Moe talks in order, one line per visit")
	var first := moe.host_line(GameState.visit("gas_n_go"), rng)
	var second := moe.host_line(GameState.visit("gas_n_go"), rng)
	check(first != second and second.begins_with("..."), "the second visit carries on where the first left off")
	check(moe.host_line(1 + moe.host_lines.size(), rng) == first, "after the last line he starts over")
	check(moe.fuel_price_factor < 1.0, "fuel at the Gas-N-Go is cheaper than at the truck stop")
	GameState.save_game()
	GameState.new_game()
	GameState.load_game()
	check(int(GameState.visits.get("gas_n_go", 0)) == 2, "visits are saved")
	_restore(before)


func test_the_radio_dial() -> void:
	var stations := Radio.lineup.stations
	check(stations.size() == 21, "20 stations plus MY TUNES (got %d)" % stations.size())
	var names := {}
	for radio_station in stations:
		check(not names.has(radio_station.display_name), "station names are unique (%s)" % radio_station.display_name)
		names[radio_station.display_name] = true
		check(radio_station.reads_player_folder or radio_station.placeholder_loop != null, "%s has a placeholder" % radio_station.display_name)


func test_regional_pirate_night_and_mystery_stations() -> void:
	var tide: RadioStation = load("res://data/radio/tide_77.tres")
	check(is_equal_approx(tide.reception(tide.signal_center, false), 1.0), "Tide 77 comes in clear at Tidewater")
	check(is_zero_approx(tide.reception(Vector3(0, 0, -5000), false)), "Tide 77 is only static at home")
	var pirate: RadioStation = load("res://data/radio/fuel_injection.tres")
	check(pirate.reception(Vector3.ZERO, false) < 0.6, "the pirate station is always crackly")
	var night: RadioStation = load("res://data/radio/afterglow_block.tres")
	check(is_zero_approx(night.reception(Vector3.ZERO, false)) and is_equal_approx(night.reception(Vector3.ZERO, true), 1.0), "Afterglow Block only broadcasts at night")
	var mystery: RadioStation = load("res://data/radio/numbers.tres")
	check(mystery.hidden and is_zero_approx(mystery.reception(Vector3.ZERO, true)), "the numbers station only comes in out on the road")
	var asteroid: RadioStation = load("res://data/radio/asteroid_rock.tres")
	check(not asteroid.reaction_lines("delivery").is_empty(), "DJs react to deliveries")


func test_logbook() -> void:
	var before := _fresh()
	check(not GameState.log_sight("not_a_real_sight"), "made-up sights don't go in the logbook")
	check(GameState.log_sight("donut"), "the first look at the donut is new")
	check(not GameState.log_sight("donut"), "the second look isn't")
	check(int(GameState.logbook["donut"]) == 2, "the logbook counts how many times")
	GameState.save_game()
	GameState.new_game()
	GameState.load_game()
	check(GameState.logbook.has("donut"), "the logbook is saved")
	_restore(before)


func test_every_sight_has_a_logbook_entry() -> void:
	var rares := 0
	for event in RouteEvents.EVENTS.events:
		check(event != null and GameState.sights.find(event.log_id) != null, "route event %s has a logbook entry" % (event.log_id if event != null else "?"))
		if event != null and event.rare:
			rares += 1
			check(GameState.sights.find(event.log_id).rare, "rare event %s is rare in the logbook too" % event.log_id)
	check(rares >= 3, "there are a few rare sights to brag about")
	var road := ROAD_SCENE.instantiate()
	for node in road.get_children():
		var log_id: Variant = node.get("log_id")
		if log_id is String and not (log_id as String).is_empty():
			check(GameState.sights.find(log_id) != null, "%s on the road has a logbook entry" % node.name)
	road.free()
	check(GameState.tuning.event_rare_chance < 0.05, "rare sights are rare")


func test_loading_screen_has_lines() -> void:
	for kind: String in ["flight", "place", "start"]:
		check((LoadingScreen.LINES[kind] as Array).size() >= 3, "the %s loading screen has a few lines to pick from" % kind)


func test_rigs_for_sale_feel_different_and_pay_differently() -> void:
	var ids := {}
	for rig in GameState.ships.ships:
		check(rig != null and not ids.has(rig.id), "rig ids are unique")
		ids[rig.id] = true
	check(GameState.ships.ships[0].id == "lazy_susan" and GameState.ships.ships[0].price == 0, "the inherited rig comes first, and it's free")
	var zippy := GameState.ships.find("zippy_courier")
	var bertha := GameState.ships.find("big_bertha")
	check(zippy.turn_rate > GameState.ships.ships[0].turn_rate and zippy.max_speed > GameState.ships.ships[0].max_speed, "the courier is quicker and nimbler than the old rig")
	check(bertha.turn_rate < GameState.ships.ships[0].turn_rate and bertha.pay_bonus > 1.0, "Big Bertha is heavier but pays more")
	check(GameState.ships.find("megahauler").special_order, "the megahauler is a special order to save up for")
	var before := _fresh()
	GameState.owned_ships.append("big_bertha")
	GameState.active_ship = "big_bertha"
	check(is_equal_approx(GameState.upgraded_ship(GameState.active_ship_data()).turn_rate, bertha.turn_rate), "flying uses the rig you picked")
	var job := GameState.jobs.find("gnome_run")
	GameState.set_flag("first_mission_done")
	GameState.accept_job(job)
	var credits := GameState.credits
	GameState.deliver_at("truck_stop")
	var hold := roundi(job.base_pay * (bertha.pay_bonus - 1.0))
	check(int(GameState.pending_payout["hold"]) == hold and GameState.credits > credits + job.base_pay, "a big hold pays a bonus")
	GameState.paint = "teal_tide"
	GameState.save_game()
	GameState.new_game()
	GameState.load_game()
	check(GameState.active_ship == "big_bertha" and "big_bertha" in GameState.owned_ships and GameState.paint == "teal_tide", "rigs and paint are saved")
	_restore(before)
	for paint in GameState.paints.paints:
		check(paint != null and not paint.id.is_empty(), "every paint job has an id")
