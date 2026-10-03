extends "res://tools/tests/TestSuite.gd"
## Checks for the flight rules (FlightModel) and the starter rig's data.
## These can't tell whether flying FEELS good (that's the playtest), only that
## the rules do what they promise.


const RIG: ShipData = preload("res://data/ships/starter_rig.tres")
const STEP: float = 1.0 / 60.0  # One physics step.


## Runs the flight rules for a while with the same controls held.
func _fly(model: FlightModel, controls: FlightControls, seconds: float) -> void:
	for i in roundi(seconds / STEP):
		model.update(STEP, controls, RIG, GameState.tuning)


func _cruising() -> FlightModel:
	var model := FlightModel.new()
	model.velocity = model.nose() * RIG.max_speed
	return model


func test_starter_rig_data_is_sane() -> void:
	check(RIG.max_speed > 0.0 and RIG.acceleration > 0.0 and RIG.retro_thrust > 0.0, "speed numbers must be above 0")
	check(RIG.turn_rate > 0.0 and RIG.pitch_rate > 0.0 and RIG.turn_response > 0.0 and RIG.grip > 0.0, "handling numbers must be above 0")
	check(RIG.boost_fuel_seconds > 0.0 and RIG.boost_acceleration > 0.0, "boost numbers must be above 0")


func test_thrust_reaches_top_speed_and_no_further() -> void:
	var model := FlightModel.new()
	var controls := FlightControls.new()
	controls.thrust = 1.0
	var fastest := 0.0
	for i in 60 * 30:
		model.update(STEP, controls, RIG, GameState.tuning)
		fastest = maxf(fastest, model.speed())
	check(absf(model.speed() - RIG.max_speed) < 1.0, "holding thrust should reach top speed (got %.2f m/s)" % model.speed())
	check(fastest <= RIG.max_speed + 0.5, "the main engines alone must not go past top speed")


func test_letting_go_coasts_with_momentum() -> void:
	var model := _cruising()
	_fly(model, FlightControls.new(), 5.0)
	check(model.speed() > RIG.max_speed * 0.9, "with no thrust the ship should keep (almost all of) its speed")


func test_reverse_thrust_brakes_and_backs_up_a_little() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.thrust = -1.0
	_fly(model, controls, RIG.max_speed / RIG.retro_thrust * 0.5)
	check(model.forward_speed() > 0.0, "braking takes a while: halfway through you should still be moving forward")
	_fly(model, controls, 30.0)
	var reverse_limit := RIG.max_speed * GameState.tuning.reverse_speed_fraction
	check(model.forward_speed() < 0.0, "keep braking and the ship should start backing up")
	check(-model.forward_speed() <= reverse_limit + 0.5, "reversing should stop at the reverse speed limit")


func test_turning_carves_without_losing_speed() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.steer = Vector2(1.0, 0.0)
	_fly(model, controls, 1.5)
	check(model.velocity.x > 0.0, "steering right should swing the ship's path to the right (+X)")
	check(model.slip > 0.5, "right after a turn, momentum should still carry the ship a bit sideways")
	check(model.bank < 0.0, "turning right should lean the rig to the right (negative roll)")
	controls.steer = Vector2.ZERO
	_fly(model, controls, 6.0)
	check(model.slip < 0.5, "with hands off, grip should line the path back up with the nose")
	check(model.speed() > RIG.max_speed * 0.9, "carving a turn shouldn't scrub off speed")
	check(absf(model.bank) < 0.01, "letting go of the stick should level the rig out")


func test_low_grip_slides_more() -> void:
	var grippy := _cruising()
	var slidey := _cruising()
	var controls := FlightControls.new()
	controls.steer = Vector2(1.0, 0.0)
	var loose_rig: ShipData = RIG.duplicate()
	loose_rig.grip = RIG.grip * 0.25
	for i in 60 * 3:
		grippy.update(STEP, controls, RIG, GameState.tuning)
		slidey.update(STEP, controls, loose_rig, GameState.tuning)
	check(slidey.slip > grippy.slip * 1.3, "a ship with less grip should slide wider in the same turn")


func test_boost_rockets_past_top_speed_then_bleeds_off() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.boost = true
	_fly(model, controls, 2.0)
	check(model.boosting, "holding boost with fuel in the tank should boost")
	check(model.speed() > RIG.max_speed * 2.0, "boost should rocket far past top speed (got %.1f m/s)" % model.speed())
	check(model.speed() <= FlightModel.boosted_top_speed(RIG) + 1.0, "boost has a top speed too")
	check(model.boost_fuel < 1.0, "boosting burns boost fuel")
	controls.boost = false
	_fly(model, controls, 2.0)
	check(model.speed() > RIG.max_speed * 1.5, "after a boost you should keep rocketing for a while")
	_fly(model, controls, 40.0)
	check(model.speed() < RIG.max_speed * 1.1, "the extra boost speed should bleed away eventually")


func test_boost_fuel_runs_dry_and_does_not_refill_itself() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.boost = true
	_fly(model, controls, RIG.boost_fuel_seconds + 0.5)
	check(not model.boosting and model.boost_fuel == 0.0, "boosting long enough should empty the boost tank")
	controls.boost = false
	_fly(model, controls, 10.0)
	check(model.boost_fuel == 0.0, "boost fuel must not refill by itself (you top it up at a station)")


func test_pitch_never_passes_the_limit() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.steer = Vector2(0.0, 1.0)
	_fly(model, controls, 10.0)
	var limit := deg_to_rad(GameState.tuning.max_pitch_degrees)
	check(model.pitch <= limit + 0.0001, "the nose must never go past the pitch limit")
	check(model.pitch > limit * 0.95, "holding nose-up should reach the pitch limit")


func test_nose_drifts_back_to_level_when_let_go() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.steer = Vector2(0.0, 1.0)
	_fly(model, controls, 1.0)
	controls.steer = Vector2.ZERO
	_fly(model, controls, 20.0)
	check(absf(model.pitch) < 0.03, "with hands off, the nose should drift back to level (pitch %.3f)" % model.pitch)


func test_the_ship_itself_never_rolls() -> void:
	var model := FlightModel.new()
	model.heading = 1.1
	model.pitch = -0.4
	check(is_zero_approx(model.orientation().get_euler().z), "the ship itself must never roll (only the model leans)")


func test_reset_parks_the_ship() -> void:
	var model := _cruising()
	model.boost_fuel = 0.2
	model.reset(0.5, 0.1)
	check(model.speed() == 0.0, "reset should stop the ship")
	check(model.boost_fuel == 1.0, "reset should refill the boost tank")
	check(is_equal_approx(model.heading, 0.5) and is_equal_approx(model.pitch, 0.1), "reset should face the given way")
