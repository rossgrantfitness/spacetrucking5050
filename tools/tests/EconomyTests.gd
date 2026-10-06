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


func test_bills_come_weekly() -> void:
	var before := _fresh()
	var tuning := GameState.tuning
	GameState.credits = 5000
	check(Economy.pass_days(3).is_empty() and GameState.day == 4, "three days in, no bills yet")
	var bill := Economy.pass_days(4)
	check(GameState.day == 8 and int(bill.get("weeks", 0)) == 1, "crossing into week 2 brings the week's bills")
	check(GameState.credits == 5000 - tuning.weekly_dispatch_fee, "the bills come out of the wallet")
	bill = Economy.pass_days(14)
	check(int(bill["weeks"]) == 2, "two weeks gone by, two weeks of bills")
	GameState.pending_bills = {}
	_restore(before)


func test_the_calendar_has_twelve_named_months() -> void:
	var calendar := Economy.calendar
	check(calendar.month_names.size() == 12 and calendar.month_days.size() == 12 and calendar.month_notes.size() == 12, "12 months, each with a length and a line")
	check(calendar.days_in_year() == 365, "a year is 365 days")
	var date := calendar.date_of(1)
	check(date["day"] == 1 and date["month"] == 0 and date["year"] == calendar.start_year, "day 1 is the 1st of the first month")
	date = calendar.date_of(calendar.month_days[0] + 1)
	check(date["day"] == 1 and date["month"] == 1, "after the first month comes the second")
	date = calendar.date_of(365)
	check(date["day"] == calendar.month_days[11] and date["month"] == 11, "day 365 is the last day of the year")
	date = calendar.date_of(366)
	check(date["day"] == 1 and date["month"] == 0 and date["year"] == calendar.start_year + 1, "then it's a new year")
	check(Economy.date_text(1) == "1 %s %d" % [calendar.month_names[0], calendar.start_year], "dates read like 1 KINDLING 5050")


func test_the_clock_runs_and_rolls_into_new_days() -> void:
	var before := _fresh()
	GameState.credits = 99999
	check(Economy.clock_text().begins_with("%02d:00" % GameState.tuning.start_hour), "a new game starts in the morning")
	GameState.minute = 23.0 * 60.0
	check(Economy.advance_minutes(120.0) == 1 and GameState.day == 2 and is_equal_approx(GameState.minute, 60.0), "past midnight is a new day")
	check(Economy.clock_text().begins_with("01:00"), "and the clock starts over")
	GameState.minute = 22.0 * 60.0
	check(Economy.sleep_until_morning() == 1 and Economy.hour() == GameState.tuning.wake_up_hour, "sleeping wakes you up the next morning")
	var started_day := GameState.day
	Economy.advance_minutes(Economy.MINUTES_PER_DAY * 6.0)
	check(GameState.day == started_day + 6, "six days of driving is six days on the calendar")
	GameState.pending_bills = {}
	_restore(before)


func test_trips_take_a_day_or_two() -> void:
	var before := _fresh()
	var long_haul := Economy.job_trip_minutes(GameState.jobs.find("first_long_haul"), "truck_stop")
	check(long_haul > Economy.MINUTES_PER_DAY * 0.5 and long_haul < Economy.MINUTES_PER_DAY * 5.0, "the long haul to Tidewater is a day or few on the road")
	var ten_minutes := 600.0 * GameState.tuning.flight_minutes_per_second
	check(ten_minutes >= Economy.MINUTES_PER_DAY and ten_minutes <= Economy.MINUTES_PER_DAY * 3.0, "ten minutes of flying is one to three days")
	GameState.accept_job(GameState.jobs.find("first_long_haul"))
	Economy.advance_minutes(Economy.MINUTES_PER_DAY * 1.5)
	GameState.deliver_at("tidewater")
	check(absf(float(GameState.pending_payout["road_minutes"]) - Economy.MINUTES_PER_DAY * 1.5) < 1.0, "the payout knows how long it was on the road")
	check(Economy.span_text(Economy.MINUTES_PER_DAY * 1.5) == "1 DAY 12 HRS", "spans read like 1 DAY 12 HRS")
	GameState.pending_bills = {}
	_restore(before)


func test_places_on_the_map_match_the_flight_scene() -> void:
	var state := (load("res://scenes/flight/FlightSandbox.tscn") as PackedScene).get_state()
	var found := 0
	for node in state.get_node_count():
		if not str(state.get_node_path(node, true)).ends_with("World/Places"):
			continue
		var place := GameState.places.find(state.get_node_name(node))
		if place == null:
			continue
		for property in state.get_node_property_count(node):
			if state.get_node_property_name(node, property) == "transform":
				var where: Vector3 = (state.get_node_property_value(node, property) as Transform3D).origin
				check(place.on_the_map and where.distance_to(place.map_position) < 50.0, "%s's map_position matches the flight scene" % place.id)
				found += 1
	check(found >= 4, "every station out in space has a spot on the map")


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
	check("D " in HubServices.job_tags(GameState.jobs.find("first_long_haul")), "jobs say about how many days they take")
