extends "res://tools/tests/TestSuite.gd"
## Checks for money and time on the road (autoload/Economy.gd): trips take
## days, bills come weekly (and go on a tab if you're short), insurance,
## and rigs that level up from their deliveries.

const SCRATCH_SAVE: String = "user://self_test_save.json"


func _fresh() -> Dictionary:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	return before


func _restore(before: Dictionary) -> void:
	GameState.apply_save_data(before)
	SaveSystem.save_path = "user://save.json"


func test_trips_take_days_and_bills_come_weekly() -> void:
	var before := _fresh()
	var tuning := GameState.tuning
	check(Economy.trip_days(GameState.jobs.find("first_long_haul")) >= 5, "a long haul takes about a week")
	GameState.credits = 5000
	check(Economy.pass_days(3).is_empty() and GameState.day == 4, "three days in, no bills yet")
	var bill := Economy.pass_days(4)
	check(GameState.day == 8 and int(bill.get("weeks", 0)) == 1, "crossing into week 2 brings the week's bills")
	check(GameState.credits == 5000 - tuning.weekly_dispatch_fee, "the bills come out of the wallet")
	bill = Economy.pass_days(14)
	check(int(bill["weeks"]) == 2, "two weeks gone by, two weeks of bills")
	GameState.pending_bills = {}
	_restore(before)


func test_short_on_money_it_goes_on_the_tab() -> void:
	var before := _fresh()
	GameState.credits = 400
	Economy.pass_days(7)
	check(GameState.credits == 0 and GameState.tab == GameState.tuning.weekly_dispatch_fee - 400, "what you can't pay goes on the tab")
	GameState.accept_job(GameState.jobs.find("first_long_haul"))
	GameState.deliver_at("tidewater")
	check(int(GameState.pending_payout["tab_paid"]) > 0, "the next delivery pays off the tab")
	check(GameState.tab == 0 or GameState.credits == 0, "the tab gets paid as far as the money goes")
	GameState.pending_bills = {}
	_restore(before)


func test_insurance_halves_repairs_and_costs_weekly() -> void:
	var before := _fresh()
	GameState.rig["hull"] = 0.5
	var full := Economy.repair_cost()
	GameState.insured = true
	check(Economy.repair_cost() == ceili(full * GameState.tuning.insured_repair_share), "insured repairs cost less")
	check(int(Economy.weekly_bill()["insurance"]) == GameState.tuning.weekly_insurance, "insurance is on the weekly bills")
	var saved := JSON.parse_string(JSON.stringify(GameState.to_save_data())) as Dictionary
	GameState.new_game()
	GameState.apply_save_data(saved)
	check(GameState.insured, "insurance is saved")
	_restore(before)


func test_rigs_level_up_and_feel_it() -> void:
	var before := _fresh()
	var base := GameState.active_ship_data()
	var green := GameState.upgraded_ship(base)
	check(Economy.level_of() == 1, "a new rig starts at level 1")
	var gained := Economy.add_xp(GameState.tuning.level_xp[2])
	check(gained == 2 and Economy.level_of() == 3, "enough XP takes it up levels")
	var seasoned := GameState.upgraded_ship(base)
	check(seasoned.max_speed > green.max_speed and seasoned.turn_rate > green.turn_rate and seasoned.grip > green.grip, "a higher level rig is faster, nimbler and grippier")
	check(Economy.level_for_xp(999999) == GameState.tuning.level_xp.size(), "it tops out at the last level")
	GameState.accept_job(GameState.jobs.find("first_long_haul"))
	var xp_before := int(GameState.ship_xp.get(GameState.active_ship, 0))
	GameState.deliver_at("tidewater")
	check(int(GameState.ship_xp[GameState.active_ship]) > xp_before and int(GameState.pending_payout["xp"]) > 0, "deliveries earn XP")
	GameState.pending_bills = {}
	_restore(before)


func test_upgrades_wait_for_the_right_level() -> void:
	var gated := 0
	for upgrade in GameState.upgrades.upgrades:
		check(upgrade.min_level >= 1 and upgrade.min_level <= GameState.tuning.level_xp.size(), "%s needs a level that exists" % upgrade.id)
		if upgrade.min_level > 1:
			gated += 1
	check(gated >= 4, "some upgrades only fit seasoned rigs")


func test_job_board_tags() -> void:
	check(HubServices.job_tags(GameState.jobs.find("spare_parts")).begins_with("RUSH"), "rush jobs are tagged RUSH")
	check("PERISHABLE" in HubServices.job_tags(GameState.jobs.find("kelp_caviar")), "caviar is tagged perishable")
	check(not "PERISHABLE" in HubServices.job_tags(GameState.jobs.find("pie_run")), "no tag when the name already says perishable")
	check("D" in HubServices.job_tags(GameState.jobs.find("mail_bags")), "every job says how many days it takes")
