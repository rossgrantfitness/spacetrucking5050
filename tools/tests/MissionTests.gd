extends "res://tools/tests/TestSuite.gd"
## Checks for the boss's missions: one at a time, in order, spread out
## between other deliveries, and buying the company only once they're all
## done.

const SCRATCH_SAVE := "user://test_save.json"
const COMPANY := preload("res://data/company/company.tres")


func _fresh() -> Dictionary:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	return before


func _restore(before: Dictionary) -> void:
	GameState.apply_save_data(before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_SAVE))
	SaveSystem.save_path = "user://save.json"


func _deliver(mission: CompanyMission) -> void:
	GameState.set_flag(mission.job.completes_flag)
	GameState.finished_jobs.append(mission.job.id)


func test_the_missions_are_one_offs_he_hands_out() -> void:
	check(COMPANY.missions.size() >= 5, "the boss has a string of missions (%d)" % COMPANY.missions.size())
	for mission in COMPANY.missions:
		check(mission.job != null and GameState.jobs.find(mission.job.id) != null, "each mission is a job in the job list")
		if mission.job == null:
			continue
		check(not mission.job.on_job_board and not mission.job.repeatable, "%s is his, once" % mission.job.id)
		check(mission.job.from_place == "truck_stop", "%s starts at the truck stop (his office)" % mission.job.id)
		check(GameState.places.find(mission.job.to_place) != null, "%s goes somewhere real" % mission.job.id)
		check(mission.pitch.size() > 0 and mission.done.size() > 0, "%s comes with insults, both ends" % mission.job.id)


func test_one_at_a_time_in_order() -> void:
	var before := _fresh()
	check(COMPANY.next_mission() == null, "no missions before the first pie run")
	GameState.set_flag("first_mission_done")
	GameState.deliveries = 1
	var first := COMPANY.next_mission()
	check(first == COMPANY.missions[0], "then the first mission")
	_deliver(first)
	GameState.deliveries = 2
	check(COMPANY.next_mission() == null, "the next one waits until you've done some other work")
	GameState.deliveries = 100
	check(COMPANY.next_mission() == COMPANY.missions[1], "then the second, in order")
	_restore(before)


func test_buying_the_company_waits_for_the_missions() -> void:
	var before := _fresh()
	check(not COMPANY.all_missions_done(), "a new game hasn't done them")
	GameState.deliveries = 100
	GameState.set_flag("first_mission_done")
	for i in COMPANY.missions.size() - 1:
		_deliver(COMPANY.missions[i])
	check(not COMPANY.all_missions_done(), "all but one isn't all")
	_deliver(COMPANY.missions[-1])
	check(COMPANY.all_missions_done() and COMPANY.next_mission() == null, "every mission done: the company's for sale, no more missions")
	_restore(before)
	before = _fresh()
	DebugMenu.finish_missions()
	check(COMPANY.all_missions_done(), "the debug menu can finish them all")
	_restore(before)
