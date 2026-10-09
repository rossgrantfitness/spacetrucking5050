extends "res://tools/tests/TestSuite.gd"
## Checks for {husband}'s story (beta step 3, docs/STORY.md): each beat
## leads to the next in the right order, nobody jumps ahead, the story
## calls play once each, his old logs come back a delivery at a time, and
## his tapes go on the radio dial at the end.

const SCRATCH_SAVE := "user://test_save.json"
const MARGE := preload("res://data/npcs/truckstop_control.tres")
const GILL := preload("res://data/npcs/tidewater_gill.tres")
const DUSTY := preload("res://data/npcs/truckstop_mechanic.tres")
const LILY := preload("res://data/npcs/truckstop_pumps.tres")
const BOSS := preload("res://data/npcs/company_boss.tres")
const CALLS := preload("res://data/dialogue/story_calls.tres")
const LOGS := preload("res://data/pc/trip_logs.tres")


func _fresh() -> Dictionary:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	return before


func _restore(before: Dictionary) -> void:
	GameState.apply_save_data(before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_SAVE))
	SaveSystem.save_path = "user://save.json"


## What `npc` would say first right now (all their lines, joined).
func _says(npc: NPCData) -> String:
	var conversation := npc.pick_conversation()
	return " ".join(conversation.lines) if conversation != null else ""


func _offers(npc: NPCData) -> String:
	var conversation := npc.pick_conversation()
	return conversation.offers_job.id if conversation != null and conversation.offers_job != null else ""


func test_each_beat_leads_to_the_next() -> void:
	var before := _fresh()
	# Beat 0: Marge recognizes the rig (after a couple of deliveries).
	DebugMenu.story_jump(0)
	check(_says(MARGE).contains("cough"), "after two deliveries, Marge recognizes the rig's cough")
	GameState.set_flag("marge_mentioned_white")
	GameState.set_flag("met_lily")  # (Her hello comes first, the first time.)
	check(_says(LILY).contains("next guy's fuel"), "once Marge has said, Lily mentions his fuel tab")
	# Beat 1: the standing order.
	DebugMenu.story_jump(1)
	check(_offers(MARGE) == "white_pie", "Marge offers his standing order (a pie for Gill)")
	check(GameState.job_available(GameState.jobs.find("white_pie")), "the pie job can be taken")
	# Beat 2: Gill and the pie.
	DebugMenu.story_jump(2)
	check(_says(GILL).contains("whale buoy"), "Gill talks about the whale buoy when the pie arrives")
	check(not _says(DUSTY).contains("message chip"), "Dusty doesn't have the chip until Gill has talked")
	# Beat 3: Dusty's chip (after the intro, if they've never met).
	DebugMenu.story_jump(3)
	GameState.set_flag("met_dusty")
	check(_says(DUSTY).contains("message chip"), "Dusty hands over the message chip")
	check(CALLS.next_call() == null or CALLS.next_call().id != "white_message", "the message doesn't play before she has the chip")
	# Beat 4: the message plays in flight.
	DebugMenu.story_jump(4)
	check(CALLS.next_call() != null and CALLS.next_call().id == "white_message", "with the chip, his message is the next story call")
	# Beat 5: the boss and the last load.
	DebugMenu.story_jump(5)
	check(_offers(BOSS) == "white_last_load", "after the message, the boss hands over his last load")
	check(CALLS.next_call() != null and CALLS.next_call().id == "raccoony_after_message", "Raccoony calls after the message (once)")
	# Beat 6: Gill opens the crate.
	DebugMenu.story_jump(6)
	check(_says(GILL).contains("FOR THE LONG HAULS"), "Gill finds the tapes in the crate")
	# Beat 7: after.
	DebugMenu.story_jump(7)
	GameState.set_flag("marge_heard_white_pie")  # (She'd have said that already.)
	check(CALLS.next_call() != null and CALLS.next_call().id == "white_tape_one", "the first tape plays on the next trip")
	check(_says(MARGE).contains("jukebox"), "Marge wants a tape for the jukebox")
	_restore(before)


func test_nobody_jumps_ahead() -> void:
	var before := _fresh()
	DebugMenu.skip_opening()
	GameState.set_flag("first_mission_done")
	GameState.deliveries = 1
	check(not _says(MARGE).contains("cough"), "Marge waits until a couple of deliveries in")
	check(CALLS.next_call() == null, "no story call plays one delivery in")
	GameState.deliveries = 3
	check(CALLS.next_call() != null and CALLS.next_call().id == "wendell_scope", "three deliveries in, Big Wendell mistakes her for him")
	# Hauling something else, nobody hands her a story job.
	DebugMenu.story_jump(1)
	GameState.accept_job(GameState.jobs.find("pie_run"))
	check(_offers(MARGE) != "white_pie", "Marge doesn't offer the standing order mid-haul")
	_restore(before)


func test_story_calls_play_once() -> void:
	var before := _fresh()
	DebugMenu.story_jump(4)
	var story_call := CALLS.next_call()
	check(story_call != null and story_call.id == "white_message", "the message is ready")
	if story_call != null:
		check(not story_call.repliable, "nobody answers a saved message")
		check(story_call.lines.size() >= 4, "it's a few cards long")
		GameState.set_flag(story_call.played_flag())
		for flag in story_call.sets_flags:
			GameState.set_flag(flag)
		check(CALLS.next_call() == null or CALLS.next_call().id != "white_message", "it never plays twice")
	_restore(before)


func test_old_logs_come_back_slowly() -> void:
	var before := _fresh()
	check(LOGS.recovered().is_empty(), "no logs before the first delivery")
	GameState.deliveries = 1
	check(LOGS.recovered().size() == 1, "one log after one delivery")
	GameState.deliveries = 100
	check(LOGS.recovered().size() == LOGS.logs.size() - 1, "all but his last log, however many deliveries")
	GameState.set_flag("white_voicemail")
	check(LOGS.recovered().size() == LOGS.logs.size(), "his last log comes back after the message")
	check(LOGS.recovered()[-1].body.contains("Not going around"), "the last log is his last run")
	var ids := {}
	for log_entry in LOGS.logs:
		check(not ids.has(log_entry.id), "log ids are unique (%s)" % log_entry.id)
		ids[log_entry.id] = true
	_restore(before)


func test_his_tapes_go_on_the_dial_at_the_end() -> void:
	var before := _fresh()
	var station_before := Radio.station_index
	var tapes := -1
	for i in Radio.lineup.stations.size():
		if Radio.lineup.stations[i].display_name == "WHITE NOISE":
			tapes = i
	check(tapes >= 0, "his tapes are a station on the radio")
	if tapes >= 0:
		check(not Radio.lineup.stations[tapes].on_the_dial(), "not before the story's done")
		Radio.tune_to(tapes)
		check(Radio.station_index != tapes, "tuning skips it until then")
		GameState.set_flag("white_story_done")
		check(Radio.lineup.stations[tapes].on_the_dial(), "after, it's on the dial")
		Radio.tune_to(tapes)
		check(Radio.station_index == tapes, "and you can tune to it")
	Radio.tune_to(station_before)
	_restore(before)


func test_story_jobs_are_one_offs_that_count() -> void:
	for id in ["white_pie", "white_last_load"]:
		var job := GameState.jobs.find(id)
		check(job != null, "%s is in the job list" % id)
		if job != null:
			check(not job.on_job_board and not job.repeatable, "%s is offered in person, once" % id)
			check(job.to_place == "tidewater", "%s goes to Tidewater" % id)
