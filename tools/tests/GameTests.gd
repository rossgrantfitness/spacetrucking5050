extends "res://tools/tests/TestSuite.gd"
## Checks for the round-7 game: places, jobs and the first mission, money,
## saving, upgrades, conversations, comm chatter and the radio.
## Every test puts GameState back the way it found it, and saving goes to a
## scratch file, so the player's real save is never touched.

const SCRATCH_SAVE: String = "user://self_test_save.json"
const RADIO_SCRIPT := preload("res://autoload/Radio.gd")


func _fresh() -> Dictionary:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	return before


func _restore(before: Dictionary) -> void:
	GameState.apply_save_data(before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_SAVE))
	SaveSystem.save_path = "user://save.json"


func test_places_and_jobs_data_line_up() -> void:
	for place in GameState.places.places:
		check(ResourceLoader.exists(place.interior_scene), "%s needs an interior scene that exists" % place.id)
	var ids := {}
	for job in GameState.jobs.jobs:
		check(not ids.has(job.id), "job ids must be unique (%s)" % job.id)
		ids[job.id] = true
		check(GameState.places.find(job.from_place) != null, "%s starts at a place that exists" % job.id)
		check(GameState.places.find(job.to_place) != null, "%s goes to a place that exists" % job.id)
		check(job.from_place != job.to_place, "%s should go somewhere else" % job.id)


func test_first_mission_unlocks_the_job_boards() -> void:
	var before := _fresh()
	check(GameState.board_jobs("base").is_empty(), "before the first mission, the base's board is empty")
	var first := GameState.jobs.find("first_pie_run")
	check(first != null and not first.on_job_board, "the first mission is offered in person, not on a board")
	check(GameState.accept_job(first), "taking the first mission should work")
	check(not GameState.accept_job(GameState.jobs.find("gnome_run")), "only one job at a time")
	check(not GameState.deliver_at("truck_stop"), "delivering at the wrong place does nothing")
	var credits := GameState.credits
	check(GameState.deliver_at("base"), "delivering at the base should work")
	check(GameState.credits == credits + first.base_pay + first.care_bonus, "perfect cargo, no rush: base pay plus the full care bonus")
	check(GameState.has_flag("first_mission_done"), "the first mission sets its story flag")
	check(not GameState.pending_payout.is_empty(), "a delivery leaves a payout card to show")
	check(not GameState.job_available(first), "the first mission can't be done twice")
	check(not GameState.board_jobs("base").is_empty(), "after the first mission, the base's board has work")
	check(not GameState.board_jobs("truck_stop").is_empty(), "after the first mission, the truck stop's board has work")
	_restore(before)


func test_rush_and_care_bonuses() -> void:
	var job: JobData = GameState.jobs.find("gnome_run")
	var pay := job.pay_breakdown(0.5, job.rush_seconds - 1.0)
	check(pay["rush"] == job.rush_bonus, "on time earns the rush bonus")
	check(pay["care"] == roundi(job.care_bonus * 0.5), "half-wrecked cargo earns half the care bonus")
	check(job.pay_breakdown(1.0, job.rush_seconds + 1.0)["rush"] == 0, "late earns no rush bonus (but never fails)")


func test_money_cant_go_negative() -> void:
	var before := _fresh()
	check(not GameState.spend(GameState.credits + 1), "you can't spend more than you have")
	check(GameState.spend(GameState.credits), "you can spend everything")
	check(GameState.credits == 0, "spending everything leaves zero")
	_restore(before)


func test_save_round_trip() -> void:
	var before := _fresh()
	GameState.add_credits(1234)
	GameState.set_flag("met_marge")
	GameState.accept_job(GameState.jobs.find("first_pie_run"))
	GameState.job_seconds = 42.0
	GameState.rig["hull"] = 0.5
	GameState.owned_upgrades.append("speed_1")
	GameState.launch_from = "truck_stop"
	GameState.current_room = "res://scenes/hub/TruckStop.tscn"
	GameState.save_game()
	var credits := GameState.credits
	GameState.new_game()
	check(GameState.load_game(), "the save should load")
	check(GameState.credits == credits, "money survives a save")
	check(GameState.has_flag("met_marge"), "story flags survive a save")
	check(GameState.active_job_id == "first_pie_run" and is_equal_approx(GameState.job_seconds, 42.0), "the job in progress survives a save")
	check(is_equal_approx(GameState.rig["hull"], 0.5), "the rig's hull survives a save")
	check(GameState.owns_upgrade("speed_1"), "upgrades survive a save")
	check(GameState.launch_from == "truck_stop" and GameState.current_room.ends_with("TruckStop.tscn"), "where you are survives a save")
	GameState.apply_save_data({"credits": "lots", "active_job": "not_a_job", "rig": {"fuel": 99}, "upgrades": ["nope"]})
	check(GameState.credits == GameState.STARTING_CREDITS, "a hand-edited save with nonsense money is ignored")
	check(GameState.active_job_id.is_empty() and GameState.owned_upgrades.is_empty(), "unknown jobs and upgrades are ignored")
	check(GameState.rig["fuel"] <= 1.0, "tanks can't be overfilled from a save")
	_restore(before)


func test_upgrades_are_felt() -> void:
	var before := _fresh()
	var rig: ShipData = load("res://data/ships/starter_rig.tres")
	var stock := GameState.upgraded_ship(rig)
	GameState.owned_upgrades.append("speed_1")
	var fast := GameState.upgraded_ship(rig)
	check(fast.max_speed > stock.max_speed * 1.15, "the first speed upgrade should be a big, felt jump in top speed")
	check(fast.acceleration > stock.acceleration, "it should also pick up speed quicker")
	check(is_equal_approx(rig.max_speed, stock.max_speed), "upgrades never change the ship's data file itself")
	for upgrade in GameState.upgrades.upgrades:
		check(upgrade.requires_upgrade.is_empty() or GameState.upgrades.find(upgrade.requires_upgrade) != null, "%s needs an upgrade that exists" % upgrade.id)
	_restore(before)


func test_conversations_follow_the_story() -> void:
	var before := _fresh()
	var marge: NPCData = load("res://data/npcs/truckstop_control.tres")
	var first := marge.pick_conversation()
	check(first != null and first.offers_job != null and first.offers_job.id == "first_pie_run", "meeting Marge offers the first mission")
	GameState.set_flag("met_marge")
	GameState.accept_job(GameState.jobs.find("first_pie_run"))
	var hauling := marge.pick_conversation()
	check(hauling != null and hauling.offers_job == null, "while hauling her pies, Marge doesn't offer them again")
	GameState.deliver_at("base")
	var dottie: NPCData = load("res://data/npcs/dispatch_morning.tres")
	var after := dottie.pick_conversation()
	check(after != null and after.opens_menu == "job_board", "after the first mission, Dottie opens the job board")
	for npc_file in ["dispatch_morning", "truckstop_control", "truckstop_mechanic", "truckstop_pumps", "trucker_wendell", "trucker_pip"]:
		var npc: NPCData = load("res://data/npcs/%s.tres" % npc_file)
		check(not npc.comm_name.is_empty(), "%s needs a comm name" % npc_file)
	_restore(before)


func test_chatter_knows_places() -> void:
	var chatter: FlightChatter = load("res://data/dialogue/flight_chatter.tres")
	var at_truck_stop := chatter.lines_for(ChatterSet.Situation.APPROACH, "truck_stop")
	var at_base := chatter.lines_for(ChatterSet.Situation.APPROACH, "base")
	check(not at_truck_stop.is_empty() and not at_base.is_empty(), "both places need approach calls")
	for pair: Array in at_truck_stop:
		check(not pair in at_base, "the truck stop's approach calls shouldn't play at the base")


func test_radio_titles_and_playlists() -> void:
	check(RADIO_SCRIPT.title_from_file("Some Artist - Night_Drive.ogg") == "SOME ARTIST - NIGHT DRIVE", "file names become ticker titles")
	for station in Radio.lineup.stations:
		check(station.reads_player_folder or station.placeholder_loop != null, "%s needs a placeholder until it has music" % station.display_name)
		if not station.reads_player_folder:
			check(not Radio.build_playlist(station).is_empty(), "%s should have something to play" % station.display_name)


func test_player_music_folder_loads_wav_files() -> void:
	var folder := Radio.PLAYER_FOLDER
	Radio.make_player_folder()
	check(FileAccess.file_exists(folder.path_join("README.txt")), "the player's music folder gets instructions")
	var song := SfxSynth.make_blip()
	var path := folder.path_join("Self Test - Blip.wav")
	song.save_to_wav(ProjectSettings.globalize_path(path))
	var custom: RadioStation
	for station in Radio.lineup.stations:
		if station.reads_player_folder:
			custom = station
	check(custom != null, "there should be a station for the player's own music")
	var titles := Radio.build_playlist(custom).map(func(item: Dictionary) -> String: return item["title"])
	check("SELF TEST - BLIP" in titles, "a .wav dropped in the folder should show up on MY TUNES")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_approach_ring_catches_ships() -> void:
	check(ApproachRing.hole_contains(Vector3(0, 10, 5), 60.0), "flying through the middle counts")
	check(not ApproachRing.hole_contains(Vector3(0, 70, 0), 60.0), "flying past the edge doesn't")
	check(not ApproachRing.hole_contains(Vector3(0, 0, 100), 60.0), "being in front of it doesn't")
