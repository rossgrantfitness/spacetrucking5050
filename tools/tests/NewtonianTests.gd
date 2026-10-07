extends "res://tools/tests/TestSuite.gd"
## Checks for Newtonian flight (the newtonian-fork branch; "Newtonian flight"
## in tuning.tres): momentum that lasts, spin that lasts, rolling, strafing,
## flying any way up, and Flight Assist tidying it all up when it's on.
## These can't tell whether it FEELS good (that's the playtest), only that
## the rules do what they promise.

const RIG: ShipData = preload("res://data/ships/starter_rig.tres")
const STEP: float = 1.0 / 60.0

var _newton: Tuning


func _init() -> void:
	_newton = GameState.tuning.duplicate() as Tuning
	_newton.newtonian_flight = true


func _fly(model: FlightModel, controls: FlightControls, seconds: float) -> void:
	for i in roundi(seconds / STEP):
		model.update(STEP, controls, RIG, _newton)


func _model(assist: bool) -> FlightModel:
	var model := FlightModel.new()
	model.newtonian = true
	model.reset(0.0, 0.0)
	model.flight_assist = assist
	return model


func test_assist_off_keeps_coasting_forever() -> void:
	var model := _model(false)
	model.velocity = model.nose() * 40.0
	_fly(model, FlightControls.new(), 30.0)
	check(absf(model.speed() - 40.0) < 0.01, "Flight Assist off: with the engines off, the rig coasts forever (%.2f m/s)" % model.speed())


func test_assist_off_turning_the_nose_does_not_turn_the_rig() -> void:
	var model := _model(false)
	model.velocity = model.nose() * 40.0
	var controls := FlightControls.new()
	controls.steer = Vector2(1.0, 0.0)
	_fly(model, controls, 1.5)
	controls.steer = Vector2.ZERO
	_fly(model, controls, 1.0)
	check(model.velocity.normalized().dot(Vector3.FORWARD) > 0.999, "Flight Assist off: turning the nose doesn't change where the rig is going")
	check(model.nose().dot(Vector3.FORWARD) < 0.95, "...but the nose did turn")
	check(absf(model.spin.y) > 0.05, "...and it keeps spinning after you let go")


func test_assist_on_stops_the_spin_and_kills_the_drift() -> void:
	var model := _model(true)
	model.velocity = model.nose() * RIG.max_speed
	var controls := FlightControls.new()
	controls.thrust = 1.0
	controls.steer = Vector2(1.0, 0.0)
	_fly(model, controls, 3.0)
	check(model.slip > 3.0, "Flight Assist on: turning hard at speed, the rig still slides wide (slip %.1f m/s)" % model.slip)
	controls.steer = Vector2.ZERO
	_fly(model, controls, 3.0)
	check(absf(model.spin.y) < 0.001, "letting go of the stick stops the spin")
	_fly(model, controls, 20.0)
	check(model.velocity.normalized().dot(model.nose()) > 0.995, "and the thrusters line the path back up with the nose")
	check(model.speed() <= RIG.max_speed + 0.5, "the engines' limiter still holds top speed (%.1f m/s)" % model.speed())


func test_rolling() -> void:
	var model := _model(true)
	var controls := FlightControls.new()
	controls.roll = 1.0
	_fly(model, controls, 1.0)
	check(model.attitude.x.y < -0.1, "rolling right dips the right wing")
	controls.roll = 0.0
	_fly(model, controls, 3.0)
	var tilt := model.attitude.x.y
	_fly(model, controls, 2.0)
	check(absf(model.attitude.x.y - tilt) < 0.001, "with Flight Assist, the roll stops where you leave it (nothing levels you)")


func test_strafing() -> void:
	var model := _model(true)
	var controls := FlightControls.new()
	controls.strafe = Vector2(1.0, 0.0)
	_fly(model, controls, 15.0)
	var local := model.attitude.inverse() * model.velocity
	var goal := RIG.max_speed * _newton.strafe_top_speed
	check(absf(local.x - goal) < 0.5, "Flight Assist on: strafing right holds a sideways speed (%.1f of %.1f m/s)" % [local.x, goal])
	controls.strafe = Vector2.ZERO
	_fly(model, controls, 15.0)
	check(model.speed() < 0.5, "and letting go stops the slide")


func test_flying_any_way_up() -> void:
	var model := _model(true)
	var controls := FlightControls.new()
	controls.steer = Vector2(0.0, 1.0)
	var highest := -1.0
	var went_over := false
	for i in roundi(30.0 / STEP):
		model.update(STEP, controls, RIG, _newton)
		highest = maxf(highest, model.nose().y)
		went_over = went_over or (model.nose().z > 0.5 and model.attitude.y.y < -0.5)
	check(highest > 0.99, "holding the nose up points it straight up (no pitch limit)")
	check(went_over, "and keeps going over the top, upside down: a full loop")


func test_assist_off_throttle_is_raw_thrust() -> void:
	var model := _model(false)
	var controls := FlightControls.new()
	controls.thrust = 0.5
	_fly(model, controls, 40.0)
	check(model.speed() > RIG.max_speed * 0.9, "Flight Assist off: half throttle keeps pushing, way past half speed (%.1f m/s)" % model.speed())
	check(model.speed() > RIG.max_speed * 1.5, "and with no limiter, past the rig's top speed (no speed cap in space)")
	controls.thrust = 0.0
	var before := model.speed()
	_fly(model, controls, 10.0)
	check(absf(model.speed() - before) < 0.01, "throttle off: it just keeps going")


func test_switching_back_to_arcade_still_works() -> void:
	var arcade := GameState.tuning.duplicate() as Tuning
	arcade.newtonian_flight = false
	var model := FlightModel.new()
	model.reset(0.0, 0.0)
	var controls := FlightControls.new()
	controls.thrust = 1.0
	for i in 600:
		model.update(STEP, controls, RIG, arcade)
	check(not model.newtonian and model.speed() > RIG.max_speed * 0.5, "with the switch off, the arcade rules fly the rig")
	check(absf(model.orientation().x.y) < 0.0001, "and the arcade rig never rolls")


func test_what_a_boost_gives_you_keep() -> void:
	for assist: bool in [true, false]:
		var model := _model(assist)
		model.velocity = model.nose() * (2000.0 / 3.6)  # Just boosted up to 2000 km/h.
		var controls := FlightControls.new()
		controls.thrust = 1.0 if assist else 0.0  # Throttle at full (assist) or engines off.
		var fuel := model.fuel
		_fly(model, controls, 60.0)
		check(absf(model.speed() * 3.6 - 2000.0) < 0.5, "Flight Assist %s: a minute later she's still doing 2000 km/h (%.0f)" % ["on" if assist else "off", model.speed() * 3.6])
		check(absf(model.fuel - fuel) < 0.0001, "and coasting at 2000 km/h costs no fuel")


func test_only_thrust_slows_you_down() -> void:
	var model := _model(false)
	model.velocity = model.nose() * (2000.0 / 3.6)
	var controls := FlightControls.new()
	controls.thrust = -1.0  # The retro thrusters.
	_fly(model, controls, 10.0)
	var expected := 2000.0 / 3.6 - RIG.retro_thrust * 10.0
	check(absf(model.speed() - expected) < 1.0, "the retro thrusters take off exactly their push (%.1f m/s, expected %.1f)" % [model.speed(), expected])
	var assisted := _model(true)
	assisted.velocity = assisted.nose() * (2000.0 / 3.6)
	var lever := FlightControls.new()
	lever.thrust = ShipControls.thrust_for(0.5, assisted.forward_speed(), RIG.max_speed, _newton)
	assisted.update(STEP, lever, RIG, _newton)
	check(assisted.thrust < 0.0, "Flight Assist on, throttle pulled back to half: it brakes with the retros")
