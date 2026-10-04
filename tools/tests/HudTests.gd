extends "res://tools/tests/TestSuite.gd"
## Checks for the round-6 HUD and the things it reads: fuel and economy,
## the practice job's pay, the radio and chatter data, the small pixel font
## and the HUD's little bits of math. (How the HUD LOOKS is for the playtest.)


const RIG: ShipData = preload("res://data/ships/starter_rig.tres")
const JOB: JobData = preload("res://data/jobs/gnome_run.tres")
const STEP: float = 1.0 / 60.0


func _fly(model: FlightModel, controls: FlightControls, seconds: float) -> void:
	for i in roundi(seconds / STEP):
		model.update(STEP, controls, RIG, GameState.tuning)


func test_small_font_letters_are_all_3x5() -> void:
	for letter: String in PixelFont.SMALL_GLYPHS:
		var rows: Array = PixelFont.SMALL_GLYPHS[letter]
		check(rows.size() == PixelFont.SMALL_HEIGHT, "small letter '%s' should be 5 rows tall" % letter)
		for row: String in rows:
			check(row.length() == 3, "small letter '%s' should be 3 squares wide (same width for the ticker)" % letter)
	for letter: String in PixelFont.GLYPHS:
		check((PixelFont.GLYPHS[letter] as Array).size() == PixelFont.HEIGHT, "big letter '%s' should be 7 rows tall" % letter)


func test_word_wrap_keeps_lines_inside_the_width() -> void:
	var lines := PixelFont.wrap("TRY NOT TO BONK THE GNOMES THEY BRUISE", 60.0, 1.0)
	check(lines.size() > 1, "a long line should wrap")
	for line in lines:
		check(PixelFont.width(line, 1.0) <= 60.0, "wrapped line '%s' should fit" % line)
	check(" ".join(lines) == "TRY NOT TO BONK THE GNOMES THEY BRUISE", "wrapping must not lose or add words")


func test_coasting_is_free_and_thrusting_burns_fuel() -> void:
	var model := FlightModel.new()
	model.velocity = model.nose() * RIG.max_speed * 0.5
	_fly(model, FlightControls.new(), 5.0)
	check(model.fuel == 1.0, "coasting should burn no fuel")
	check(model.economy_rating(GameState.tuning) == 0, "coasting should show the green economy arrow")
	var controls := FlightControls.new()
	controls.thrust = 1.0
	_fly(model, controls, 5.0)
	check(model.fuel < 1.0, "thrusting should burn fuel")


func test_faster_burns_more_fuel_but_cruising_sips() -> void:
	var slow := FlightModel.new()
	var fast := FlightModel.new()
	var cruising := FlightModel.new()
	fast.velocity = fast.nose() * RIG.max_speed * 0.8
	cruising.velocity = cruising.nose() * RIG.max_speed
	var controls := FlightControls.new()
	controls.thrust = 1.0
	for model in [slow, fast, cruising]:
		(model as FlightModel).update(STEP, controls, RIG, GameState.tuning)
	check(fast.fuel < slow.fuel, "speeding up at high speed should burn more fuel than at low speed")
	check(cruising.fuel > slow.fuel, "holding top speed on the limiter should only sip fuel")
	check(fast.economy_rating(GameState.tuning) >= 1, "flooring it at high speed shouldn't show the green arrow")
	check(cruising.economy_rating(GameState.tuning) == 0, "cruising on the limiter should show the green arrow")


func test_a_full_tank_lasts_a_long_cruise() -> void:
	var model := FlightModel.new()
	model.velocity = model.nose() * RIG.max_speed
	var controls := FlightControls.new()
	controls.thrust = 1.0
	for i in 60 * 60 * 18:  # 18 minutes at top speed.
		model.update(1.0 / 60.0, controls, RIG, GameState.tuning)
	check(model.fuel > 0.0, "a full tank should last an 18-minute cruise at top speed (%.2f left)" % model.fuel)


func test_empty_tank_limps_instead_of_stranding() -> void:
	var model := FlightModel.new()
	model.fuel = 0.0
	var controls := FlightControls.new()
	controls.thrust = 1.0
	_fly(model, controls, 2.0)
	check(model.speed() > 0.5, "an empty tank should still crawl along on fumes")
	check(absf(model.thrust - GameState.tuning.empty_tank_thrust) < 0.001, "on fumes, thrust should be the empty-tank fraction")


func test_boosting_shows_red_economy() -> void:
	var model := FlightModel.new()
	var controls := FlightControls.new()
	controls.boost = true
	model.update(STEP, controls, RIG, GameState.tuning)
	check(model.economy_rating(GameState.tuning) == 2, "boosting should always show the red arrow")


func test_job_pay_adds_bonuses_and_never_fails() -> void:
	var perfect := JOB.pay_for(1.0, 1.0)
	check(perfect == JOB.base_pay + JOB.care_bonus + JOB.rush_bonus, "perfect and on time should earn every bonus")
	var late_and_battered := JOB.pay_for(0.0, JOB.rush_seconds + 60.0)
	check(late_and_battered == JOB.base_pay, "late with wrecked cargo should still pay the base pay")
	check(JOB.pay_for(0.5, 1.0) < perfect, "damaged cargo should pay less")


func test_compass_and_turns() -> void:
	check(is_zero_approx(NavTape.compass(Vector3.FORWARD)), "straight ahead at the start is north (0)")
	check(is_equal_approx(NavTape.compass(Vector3.RIGHT), 90.0), "to the right at the start is east (90)")
	check(is_equal_approx(NavTape.turn_between(350.0, 10.0), 20.0), "350 to 10 degrees is a 20-degree turn right")
	check(is_equal_approx(NavTape.turn_between(10.0, 350.0), -20.0), "10 to 350 degrees is a 20-degree turn left")


func test_hull_picture_flashes_the_right_spot() -> void:
	check(HullSilhouette.zone_for(Vector3(0, 0, -10)) == HullSilhouette.Zone.NOSE, "a hit up front lights the nose")
	check(HullSilhouette.zone_for(Vector3(0, 0, 10)) == HullSilhouette.Zone.TAIL, "a hit behind lights the tail")
	check(HullSilhouette.zone_for(Vector3(8, 0, 1)) == HullSilhouette.Zone.RIGHT, "a hit on the right lights the right side")
	check(HullSilhouette.zone_for(Vector3(-8, 0, 1)) == HullSilhouette.Zone.LEFT, "a hit on the left lights the left side")


func test_fuel_arc_segments() -> void:
	check(FuelGauge.segment_at(Vector2.ZERO) == -1, "the middle of the gauge isn't part of the arc")
	var top := FuelGauge.segment_at(Vector2(0.5, -FuelGauge.RADIUS + 2.0))
	var middle := floori(FuelGauge.SEGMENTS / 2.0)
	check(top >= middle - 1 and top <= middle + 1, "the top of the arc is its middle segment (got %d)" % top)
	check(FuelGauge.segment_at(Vector2(0.5, FuelGauge.RADIUS - 2.0)) == -1, "the bottom of the arc is open")


func test_every_chatter_situation_has_lines() -> void:
	var chatter: FlightChatter = load("res://data/dialogue/flight_chatter.tres")
	for situation: int in ChatterSet.Situation.values():
		var found := false
		for place in ["", "base", "truck_stop"]:
			found = found or not chatter.lines_for(situation, place).is_empty()
		check(found, "comm chatter needs lines for situation %d" % situation)
	for chatter_set in chatter.sets:
		check(not chatter_set.speaker.comm_name.is_empty(), "%s needs a comm name" % chatter_set.speaker.display_name)


func test_traffic_names_are_stable() -> void:
	var names: TrafficNames = load("res://data/traffic_names.tres")
	check(names.names.size() >= 30, "write lots of funny ship names")
	check(names.pick_for("Commuter") == names.pick_for("Commuter"), "the same ship should always get the same name")


func test_new_tuning_values_are_sane() -> void:
	var tuning := GameState.tuning
	check(tuning.comm_idle_min_seconds <= tuning.comm_idle_max_seconds, "idle chatter: the shortest wait can't be longer than the longest")
	check(tuning.economy_yellow < tuning.economy_red, "the economy arrow should go yellow before red")
	check(tuning.cargo_damage_min <= tuning.cargo_damage_max, "the biggest bonk should hurt cargo at least as much as the gentlest")
	check(RIG.fuel_tank_seconds > 0.0, "the rig needs a fuel tank")


func test_boost_wanders_off_course_and_jerky_hands_make_it_worse() -> void:
	var steady := FlightModel.new()
	var jerky := FlightModel.new()
	var hands := FlightControls.new()
	hands.boost = true
	for i in 60 * 6:
		steady.update(STEP, hands, RIG, GameState.tuning)
	var shaky_hands := FlightControls.new()
	shaky_hands.boost = true
	for i in 60 * 6:
		shaky_hands.steer = Vector2(1.0 if i % 20 < 10 else -1.0, 0.0)
		jerky.update(STEP, shaky_hands, RIG, GameState.tuning)
	check(absf(steady.heading) > 0.005, "even holding steady, boost should drift the nose a little")
	check(steady.wobble < 0.05, "holding steady under boost shouldn't make the rig shaky")
	check(jerky.wobble > 0.3, "jerky steering under boost should make the rig shaky")
	var calm := FlightModel.new()
	_fly(calm, FlightControls.new(), 6.0)
	check(is_zero_approx(calm.heading), "without boost, the nose stays put")


func test_only_rough_forces_shake_the_cargo() -> void:
	var nose := Vector3.FORWARD
	check(is_zero_approx(Ship.rough_g_force(nose * 50.0, nose)), "speeding up straight ahead never hurts the cargo")
	check(is_equal_approx(Ship.rough_g_force(-nose * 30.0, nose), 30.0), "hard braking counts")
	check(is_equal_approx(Ship.rough_g_force(Vector3.RIGHT * 40.0, nose), 40.0), "sideways g-force (turns, slides) counts")
