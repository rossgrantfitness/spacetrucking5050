extends "res://tools/tests/TestSuite.gd"
## Checks for the M1 flight rules (FlightModel) and the starter rig's data.
## These can't tell whether flying FEELS good (that's the playtest), only that
## the rules do what they promise.


const RIG: ShipData = preload("res://data/ships/starter_rig.tres")
const STEP: float = 1.0 / 60.0  # One physics step.


## Runs the flight rules for a while with the same controls held.
func _fly(model: FlightModel, controls: FlightControls, seconds: float) -> void:
	for i in roundi(seconds / STEP):
		model.update(STEP, controls, RIG, GameState.tuning)


func _cruising_at_full_throttle() -> FlightModel:
	var model := FlightModel.new()
	model.throttle = 1.0
	model.speed = RIG.max_speed
	return model


func test_starter_rig_data_is_sane() -> void:
	check(RIG.max_speed > 0.0 and RIG.acceleration > 0.0 and RIG.braking > 0.0, "speed numbers must be above 0")
	check(RIG.turn_rate > 0.0 and RIG.pitch_rate > 0.0 and RIG.turn_response > 0.0, "handling numbers must be above 0")
	check(RIG.boost_duration > 0.0 and RIG.boost_recharge_time > 0.0, "boost times must be above 0")


func test_full_throttle_settles_at_top_speed_without_overshooting() -> void:
	var model := FlightModel.new()
	var controls := FlightControls.new()
	controls.throttle_change = 1.0
	_fly(model, controls, 3.0)
	check(is_equal_approx(model.throttle, 1.0), "holding throttle up for 3 seconds should reach full throttle")
	controls.throttle_change = 0.0
	var fastest := 0.0
	for i in 60 * 30:
		model.update(STEP, controls, RIG, GameState.tuning)
		fastest = maxf(fastest, model.speed)
	check(absf(model.speed - RIG.max_speed) < 0.5, "full throttle should settle at top speed (got %.2f m/s)" % model.speed)
	check(fastest <= RIG.max_speed + 0.001, "without boost, speed must never go over top speed")


func test_pulling_the_throttle_back_slows_to_a_stop() -> void:
	var model := _cruising_at_full_throttle()
	var controls := FlightControls.new()
	controls.throttle_change = -1.0
	_fly(model, controls, 20.0)
	check(model.throttle == 0.0, "holding throttle down should close the throttle")
	check(model.speed < 0.5, "with the throttle closed the ship should come to a stop (got %.2f m/s)" % model.speed)


func test_boost_goes_faster_then_settles_back() -> void:
	var model := _cruising_at_full_throttle()
	var controls := FlightControls.new()
	controls.boost = true
	_fly(model, controls, 2.0)
	check(model.boosting, "holding boost with a full tank should boost")
	check(model.speed > RIG.max_speed * 1.2, "boosting should go well past normal top speed")
	check(model.speed <= FlightModel.boosted_top_speed(RIG) + 0.001, "boost has a top speed too")
	check(model.boost_tank < 1.0, "boosting should use up the tank")
	controls.boost = false
	_fly(model, controls, 20.0)
	check(not model.boosting, "letting go of boost should stop boosting")
	check(absf(model.speed - RIG.max_speed) < 0.5, "after a boost the ship should settle back to cruising speed")
	check(is_equal_approx(model.boost_tank, 1.0), "the boost tank should refill")


func test_an_empty_boost_tank_waits_for_a_fresh_press() -> void:
	var model := _cruising_at_full_throttle()
	var controls := FlightControls.new()
	controls.boost = true
	_fly(model, controls, RIG.boost_duration + STEP * 3.0)
	check(not model.boosting and model.boost_tank < 0.01, "holding boost should eventually empty the tank")
	_fly(model, controls, 2.0)
	check(not model.boosting, "still holding boost after the tank ran dry shouldn't pulse it back on")
	controls.boost = false
	_fly(model, controls, 2.0)
	controls.boost = true
	_fly(model, controls, STEP)
	check(model.boosting, "a fresh press after a short recharge should boost again")


func test_steering_right_turns_right_and_leans_right() -> void:
	var model := _cruising_at_full_throttle()
	var controls := FlightControls.new()
	controls.steer = Vector2(1.0, 0.0)
	_fly(model, controls, 1.0)
	check(model.velocity().x > 0.0, "steering right should swing the nose to the right (+X)")
	check(model.bank < 0.0, "turning right should lean the rig to the right (negative roll)")


func test_letting_go_levels_out() -> void:
	var model := _cruising_at_full_throttle()
	var controls := FlightControls.new()
	controls.steer = Vector2(-1.0, 0.0)
	_fly(model, controls, 2.0)
	controls.steer = Vector2.ZERO
	_fly(model, controls, 6.0)
	check(absf(model.turn_speed) < 0.01, "letting go of the stick should stop the turn")
	check(absf(model.bank) < 0.01, "letting go of the stick should level the rig out")


func test_pitch_never_passes_the_limit() -> void:
	var model := _cruising_at_full_throttle()
	var controls := FlightControls.new()
	controls.steer = Vector2(0.0, 1.0)
	_fly(model, controls, 10.0)
	var limit := deg_to_rad(GameState.tuning.max_pitch_degrees)
	check(model.pitch <= limit + 0.0001, "the nose must never go past the pitch limit")
	check(model.pitch > limit * 0.95, "holding nose-up should reach the pitch limit")


func test_nose_drifts_back_to_level_when_let_go() -> void:
	var model := _cruising_at_full_throttle()
	var controls := FlightControls.new()
	controls.steer = Vector2(0.0, 1.0)
	_fly(model, controls, 1.0)
	controls.steer = Vector2.ZERO
	_fly(model, controls, 20.0)
	check(absf(model.pitch) < 0.03, "with hands off, the nose should drift back to level (pitch %.3f)" % model.pitch)


func test_ship_moves_exactly_where_it_points() -> void:
	var model := FlightModel.new()
	model.heading = 1.1
	model.pitch = -0.4
	model.speed = 30.0
	var forward := -model.orientation().z
	check(model.velocity().normalized().is_equal_approx(forward), "velocity should point straight out of the nose")
	check(is_equal_approx(model.velocity().length(), 30.0), "velocity should match the speed")
	check(is_zero_approx(model.orientation().get_euler().z), "the ship itself must never roll")


func test_reset_parks_the_ship() -> void:
	var model := _cruising_at_full_throttle()
	model.boost_tank = 0.2
	model.reset(0.5, 0.1)
	check(model.speed == 0.0 and model.throttle == 0.0, "reset should stop the ship and close the throttle")
	check(model.boost_tank == 1.0, "reset should refill the boost tank")
	check(is_equal_approx(model.heading, 0.5) and is_equal_approx(model.pitch, 0.1), "reset should face the given way")
