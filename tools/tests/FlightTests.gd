extends "res://tools/tests/TestSuite.gd"
## Checks for the flight rules (FlightModel) and the starter rig's data.
## These can't tell whether flying FEELS good (that's the playtest), only that
## the rules do what they promise.
##
## These are the ARCADE rules (still in the game: "Newtonian flight" off in
## tuning.tres), so the model runs with a copy of the tuning that has it off.
## The Newtonian rules are checked in NewtonianTests.gd.


const RIG: ShipData = preload("res://data/ships/starter_rig.tres")
const STEP: float = 1.0 / 60.0  # One physics step.

var _arcade: Tuning


func _init() -> void:
	_arcade = GameState.tuning.duplicate() as Tuning
	_arcade.newtonian_flight = false


## Runs the flight rules for a while with the same controls held.
func _fly(model: FlightModel, controls: FlightControls, seconds: float) -> void:
	for i in roundi(seconds / STEP):
		model.update(STEP, controls, RIG, _arcade)


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
		model.update(STEP, controls, RIG, _arcade)
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
		grippy.update(STEP, controls, RIG, _arcade)
		slidey.update(STEP, controls, loose_rig, _arcade)
	check(slidey.slip > grippy.slip * 1.3, "a ship with less grip should slide wider in the same turn")


func test_boost_rockets_past_top_speed_then_bleeds_off() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.boost = true
	_fly(model, controls, GameState.tuning.boost_spool_seconds * 0.5)
	check(not model.boosting and model.spool > 0.0, "boost spools up for a moment before it lights")
	_fly(model, controls, 2.0)
	check(model.boosting, "holding boost with fuel in the tank should boost")
	check(model.speed() > RIG.max_speed * 2.0, "boost should rocket far past top speed (got %.1f m/s)" % model.speed())
	check(model.speed() <= FlightModel.boosted_top_speed(RIG) + GameState.tuning.overdrive_acceleration * 2.0 + 1.0, "past boost's top speed it only creeps up (overdrive)")
	check(model.boost_fuel < 1.0, "boosting burns boost fuel")
	controls.boost = false
	_fly(model, controls, 0.1)
	check(model.boosting, "once lit, boost keeps burning a few seconds even after letting go")
	_fly(model, controls, GameState.tuning.boost_min_burn_seconds)
	check(not model.boosting, "after its minimum burn, letting go stops the boost")
	_fly(model, controls, 2.0)
	check(model.speed() > RIG.max_speed * 1.5, "after a boost you should keep rocketing for a while")
	_fly(model, controls, 40.0)
	check(model.speed() < RIG.max_speed * 1.1, "the extra boost speed should bleed away eventually")


func test_boost_fuel_runs_dry_and_does_not_refill_itself() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.boost = true
	_fly(model, controls, RIG.boost_fuel_seconds + GameState.tuning.boost_spool_seconds + 0.5)
	check(not model.boosting and model.boost_fuel == 0.0, "boosting long enough should empty the boost tank")
	controls.boost = false
	_fly(model, controls, 10.0)
	check(model.boost_fuel == 0.0, "boost fuel must not refill by itself (you top it up at a station)")


func test_a_tap_of_boost_does_nothing() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.boost = true
	_fly(model, controls, GameState.tuning.boost_spool_seconds * 0.4)
	controls.boost = false
	_fly(model, controls, 1.0)
	check(not model.boosting and is_equal_approx(model.boost_fuel, 1.0), "letting go before it spools up costs nothing")


func test_the_throttle_lever_holds_a_speed() -> void:
	var model := FlightModel.new()
	var controls := FlightControls.new()
	for i in 60 * 30:
		controls.thrust = ShipControls.thrust_for(0.5, model.forward_speed(), RIG.max_speed, GameState.tuning)
		model.update(STEP, controls, RIG, _arcade)
	check(absf(model.speed() - RIG.max_speed * 0.5) < 1.5, "half throttle settles at half speed (got %.1f m/s)" % model.speed())
	for i in 60 * 30:
		controls.thrust = ShipControls.thrust_for(0.0, model.forward_speed(), RIG.max_speed, GameState.tuning)
		model.update(STEP, controls, RIG, _arcade)
	check(model.speed() < 1.0, "idle throttle brings the rig to a stop")
	check(is_equal_approx(ShipControls.thrust_for(1.0, RIG.max_speed, RIG.max_speed, GameState.tuning), 1.0), "full throttle leans on the limiter")


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


func test_on_a_steep_road_the_nose_settles_on_the_climb() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	model.rest_pitch = deg_to_rad(35.0)  # The road to the Frostline climbs about this steeply.
	_fly(model, controls, 25.0)
	check(absf(model.pitch - model.rest_pitch) < 0.03, "hands off on a steep road, the nose settles on the road's climb (pitch %.1f deg)" % rad_to_deg(model.pitch))


func test_the_ship_itself_never_rolls() -> void:
	var model := FlightModel.new()
	model.heading = 1.1
	model.pitch = -0.4
	check(is_zero_approx(model.orientation().get_euler().z), "the ship itself must never roll (only the model leans)")


func test_reset_parks_the_ship() -> void:
	var model := _cruising()
	model.boost_fuel = 0.2
	model.fuel = 0.3
	model.reset(0.5, 0.1)
	check(model.speed() == 0.0, "reset should stop the ship")
	check(model.boost_fuel == 1.0, "reset should refill the boost tank")
	check(model.fuel == 1.0, "reset should refill the fuel tank")
	check(is_equal_approx(model.heading, 0.5) and is_equal_approx(model.pitch, 0.1), "reset should face the given way")


func test_bonks_scale_from_gentle_to_hard() -> void:
	var tuning := GameState.tuning
	check(Ship.bonk_strength(tuning.bonk_min_speed, tuning) == 0.0, "a bump at the minimum speed is the gentlest bonk")
	check(Ship.bonk_strength(tuning.bonk_hard_speed * 3.0, tuning) == 1.0, "a huge crash is capped at the biggest bonk")
	var middle := Ship.bonk_strength((tuning.bonk_min_speed + tuning.bonk_hard_speed) * 0.5, tuning)
	check(absf(middle - 0.5) < 0.01, "bonk strength grows evenly with impact speed")
	check(tuning.bonk_damage_max >= tuning.bonk_damage_min, "the biggest bonk should hurt at least as much as the gentlest")


func test_the_cinema_camera_always_films_the_rig() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var holder := Node3D.new()
	tree.root.add_child(holder)
	var ship := (load("res://scenes/flight/Ship.tscn") as PackedScene).instantiate() as Ship
	holder.add_child(ship)
	ship.flight.velocity = -ship.global_basis.z * 50.0
	var cinema := CinemaCamera.new()
	cinema.target = ship
	holder.add_child(cinema)
	cinema.start()
	check(cinema.current and cinema.mode == CinemaCamera.Mode.DIRECTOR, "the cinema camera starts in director mode")
	for shot: int in CinemaCamera.Shot.values():
		cinema.set_shot(shot as CinemaCamera.Shot)
		for i in 10:
			cinema.call("_film", 0.1)
		var shot_name: String = CinemaCamera.Shot.keys()[shot]
		check(cinema.is_position_in_frustum(ship.global_position), "the %s shot sees the rig" % shot_name)
		var away := cinema.global_position.distance_to(ship.global_position)
		check(away > 5.0 and away < 1000.0, "the %s shot isn't inside the rig or miles away (%.0f m)" % [shot_name, away])
		check(absf(cinema.global_basis.x.y) < 0.01, "the %s shot keeps the horizon level" % shot_name)
	cinema.take_over()
	check(cinema.mode == CinemaCamera.Mode.FREE, "touching the controls hands you the camera")
	cinema.call("_steer_by_hand", Vector2(1.0, 0.0), 1.0)
	cinema.call("_film", 0.0)
	check(cinema.is_position_in_frustum(ship.global_position), "the free camera still looks at the rig after swinging around")
	holder.free()


func test_boost_gives_speed_wobbles_not_a_swerve() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.thrust = 1.0
	controls.boost = true
	var start := model.heading
	_fly(model, controls, GameState.tuning.boost_spool_seconds + 0.5)
	var early := model.shimmy
	_fly(model, controls, GameState.tuning.boost_wobble_build_seconds)
	check(model.boosting and model.shimmy > early and model.shimmy > 0.9, "the longer you boost, the worse the wobbles")
	# Over a few seconds of boosting hands-off, the rig drifts off course,
	# but slowly: a handful of degrees, not a swerve.
	var drift := rad_to_deg(absf(angle_difference(start, model.heading)))
	check(drift < 25.0, "boosting should drift slowly off course, not swerve (drifted %.1f°)" % drift)
	controls.boost = false
	_fly(model, controls, 6.0)
	check(model.shimmy < 0.05, "the wobbles settle down after boosting")


func test_throttle_stops_at_idle_before_reverse() -> void:
	# Holding "down" from cruising: it slides to idle and stops there.
	var lever := 0.3
	for i in 20:
		lever = ShipControls.move_lever(lever, -0.05, 1, 0.25)
	check(is_equal_approx(lever, 0.0), "holding throttle-down from ahead stops at idle, not reverse")
	# Let go, press again: now it goes into reverse.
	for i in 20:
		lever = ShipControls.move_lever(lever, -0.05, 0, 0.25)
	check(is_equal_approx(lever, -0.25), "a fresh press at idle backs up (to full reverse)")
	# And back up the other way: it stops at idle again.
	for i in 20:
		lever = ShipControls.move_lever(lever, 0.05, -1, 0.25)
	check(is_equal_approx(lever, 0.0), "holding throttle-up from reverse stops at idle too")


func test_heavy_loads_are_slower_to_start_stop_and_turn() -> void:
	# Speeding up: 5 seconds of full thrust, empty vs a full load.
	var controls := FlightControls.new()
	controls.thrust = 1.0
	var empty := FlightModel.new()
	var heavy := FlightModel.new()
	heavy.load_share = 1.0
	_fly(empty, controls, 5.0)
	_fly(heavy, controls, 5.0)
	check(heavy.speed() < empty.speed() * 0.8, "a full load should get going noticeably slower")
	# Stopping: from cruise, how far until it's (almost) stopped?
	var brakes := FlightControls.new()
	brakes.thrust = -1.0
	var distances: Array[float] = []
	for share: float in [0.0, 1.0]:
		var model := _cruising()
		model.load_share = share
		var travelled := 0.0
		for i in 60 * 60:
			if model.forward_speed() < 1.0:
				break
			travelled += model.forward_speed() * STEP
			model.update(STEP, brakes, RIG, _arcade)
		distances.append(travelled)
	check(distances[1] > distances[0] * 1.4, "a full load should take noticeably longer to stop (%.0f m vs %.0f m)" % [distances[1], distances[0]])
	# Turning: a full load turns slower, but still goes where the nose points.
	var steer := FlightControls.new()
	steer.steer = Vector2(1.0, 0.0)
	var light := _cruising()
	var loaded := _cruising()
	loaded.load_share = 1.0
	_fly(light, steer, 3.0)
	_fly(loaded, steer, 3.0)
	check(absf(loaded.heading) < absf(light.heading), "a full load should turn slower")
	_fly(loaded, FlightControls.new(), 8.0)
	check(loaded.velocity.normalized().dot(loaded.nose()) > 0.99, "even loaded, the rig ends up going where its nose points (no drift)")


func test_galactic_tons_read_nicely() -> void:
	check(HudWidget.tons_text(450000000.0) == "450M T", "450 million tons is 450M T (got %s)" % HudWidget.tons_text(450000000.0))
	check(HudWidget.tons_text(1800000000.0) == "1.8B T", "1.8 billion tons is 1.8B T")
	check(HudWidget.tons_text(1800000000.0, true) == "1.8 billion tons", "and in words for the job board")


func test_overdrive_keeps_climbing_and_gets_wilder() -> void:
	var model := _cruising()
	var controls := FlightControls.new()
	controls.boost = true
	controls.thrust = 1.0
	_fly(model, controls, 5.0)
	var at_cap := model.speed()
	_fly(model, controls, 60.0)
	check(model.speed() > at_cap + 300.0, "holding boost past its top speed keeps climbing (overdrive): %.0f km/h" % (model.speed() * 3.6))
	check(model.overdrive > 1.0, "far past boost's top speed, the overdrive notches pile up")
	check(model.wander_amount(GameState.tuning) > deg_to_rad(GameState.tuning.overdrive_wander_degrees), "and the nose pulls harder the faster it goes")
	controls.boost = false
	_fly(model, controls, 20.0)
	check(model.speed() < at_cap, "letting go of boost, the speed bleeds back down")
