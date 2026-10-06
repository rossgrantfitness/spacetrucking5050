class_name FlightModel
extends RefCounted
## The rules of flying, with no graphics attached: thrust, momentum, grip,
## boost, turning, and how far the rig leans. Ship.gd feeds it the pilot's
## controls every physics tick, then moves the actual ship to match.
##
## How it works (after the M1 playtest asked for real momentum):
##   - Thrust pushes the ship along its nose (forward, or backward to brake).
##     The pilot sets a throttle LEVER and ShipControls turns it into the
##     thrust that reaches and holds that speed (see ShipControls.gd).
##   - With no thrust you COAST: the ship keeps its momentum.
##   - "Grip" gradually swings your direction of travel around to where the
##     nose points, without losing speed, like carving a turn. Low grip =
##     wide, slidey arcs and easy overshooting; high grip = on rails.
##   - Spin the nose more than 90 degrees away from where you're going and
##     grip won't save you: burn the engines to brake.
##   - Boost shoves you far past top speed and makes grip much weaker, so the
##     rig gets wild. Afterwards the extra speed bleeds off slowly. It's a
##     commitment: it spools up for a moment while you hold the button
##     before it lights, and once lit it burns for a few seconds minimum.
##   - Boosting gives the rig speed wobbles, like a car going too fast on
##     the highway: it shakes harder the longer you hold boost (the nose
##     shimmies side to side and the hull rocks), and while it shakes it
##     slowly drifts off course. Steering gets twitchy too, and jerky
##     steering makes the shakes worse. Let off and it settles down.
##   - Thrusting burns main fuel: speeding up drinks it (more at high
##     speed), holding top speed on the limiter just sips it, coasting is
##     free. An empty tank never strands you: the engines keep going "on
##     fumes".
##
## Keeping these rules separate makes them easy to read and to test (see
## tools/tests/FlightTests.gd).


## Where the ship is going and how fast, in meters per second.
var velocity := Vector3.ZERO
## Where the nose points, in radians: heading is left/right, pitch is up/down.
var heading := 0.0
var pitch := 0.0
## How fast the nose is turning right now, in radians per second.
var turn_speed := 0.0
var pitch_speed := 0.0
## The engine thrust being applied right now, -1 (full reverse) to 1 (full).
var thrust := 0.0
## Main fuel, 0 (empty) to 1 (a full tank).
var fuel := 1.0
## How hard we're burning main fuel right now, from 0 (coasting) to 1
## (flooring it at top speed). The HUD's fuel-economy arrow shows it.
var fuel_burn := 0.0
## Boost fuel, 0 (empty) to 1 (a full tank), and whether boost is firing.
var boost_fuel := 1.0
var boosting := false
## Boost spooling up while the button is held, 0 to 1 (it lights at 1).
var spool := 0.0
## Seconds boost must keep burning before it can stop.
var burn_left := 0.0
## How fast we're sliding sideways (m/s): the part of our movement that isn't
## where the nose points. The engine sound and HUD use it.
var slip := 0.0
## How shaky the rig is under boost, 0 (steady) to 1 (all over the place).
## Jerky steering while boosting raises it; holding steady calms it.
var wobble := 0.0
## How bad the speed wobbles are right now, 0 to 1: builds up the longer you
## boost (and with jerky steering), settles when you stop.
var shimmy := 0.0
## How easily jerky steering shakes the rig (1 = normal; a calming snack
## from the Gas-N-Go makes it 0.5 for the trip).
var shakiness := 1.0
## How far the rig visibly leans into a turn, and tips its nose, in radians.
## Purely for looks: neither changes where the ship goes.
var bank := 0.0
var nose_tilt := 0.0
## How heavy the load is for this rig: 0 = empty, 1 = a full load (the
## job's weight against the rig's load_rating; Ship sets it). See "Load
## weight" in tuning.tres.
var load_share := 0.0
## The extra rock of a loaded rig after a turn starts or stops (radians of
## roll: purely looks).
var cargo_sway := 0.0
var _sway_speed := 0.0
var _last_wanted_bank := 0.0

var _time := 0.0
var _last_steer := Vector2.ZERO


## Advances the flight by one step of `delta` seconds.
func update(delta: float, controls: FlightControls, ship: ShipData, tuning: Tuning) -> void:
	_time += delta
	_update_wobble(delta, controls, tuning)
	_update_turning(delta, controls, ship, tuning)
	_update_motion(delta, controls, ship, tuning)
	_update_lean(delta, ship, tuning)


## Which way the nose points. It never contains any roll (the lean is only
## visual), and that's what keeps the horizon level.
func orientation() -> Basis:
	return Basis.from_euler(Vector3(pitch, heading, 0.0))


## The direction the nose points. (In Godot, "forward" is the -Z direction.)
func nose() -> Vector3:
	return -orientation().z


func speed() -> float:
	return velocity.length()


## How fast we're moving in the direction the nose points (negative when
## drifting backwards).
func forward_speed() -> float:
	return velocity.dot(nose())


## The fastest boost can push this ship.
static func boosted_top_speed(ship: ShipData) -> float:
	return ship.max_speed * (1.0 + ship.boost_speed_bonus)


## How hard we're turning, from -1 (full left) to 1 (full right).
func turn_amount(ship: ShipData) -> float:
	return -turn_speed / deg_to_rad(ship.turn_rate)


## How thriftily we're flying right now: 0 = green (coasting or easy
## thrust), 1 = yellow (working hard), 2 = red (flooring it fast, or boost).
func economy_rating(tuning: Tuning) -> int:
	if boosting or fuel_burn >= tuning.economy_red:
		return 2
	if fuel_burn >= tuning.economy_yellow:
		return 1
	return 0


## Puts everything back to "parked": stopped, engines idle, both tanks full.
func reset(new_heading: float, new_pitch: float) -> void:
	heading = new_heading
	pitch = new_pitch
	velocity = Vector3.ZERO
	turn_speed = 0.0
	pitch_speed = 0.0
	thrust = 0.0
	fuel = 1.0
	fuel_burn = 0.0
	boost_fuel = 1.0
	boosting = false
	spool = 0.0
	burn_left = 0.0
	slip = 0.0
	wobble = 0.0
	shimmy = 0.0
	bank = 0.0
	nose_tilt = 0.0
	cargo_sway = 0.0
	_sway_speed = 0.0


func _update_motion(delta: float, controls: FlightControls, ship: ShipData, tuning: Tuning) -> void:
	var forward := nose()
	thrust = _burn_fuel(delta, clampf(controls.thrust, -1.0, 1.0), ship, tuning)
	_update_boost(delta, controls, tuning)
	if boosting:
		boost_fuel = maxf(boost_fuel - delta / ship.boost_fuel_seconds, 0.0)

	# 1. The engines push along the nose. The ship's own limiter stops the
	#    main engines adding speed past top speed; only boost goes beyond.
	#    A heavy load answers slower, both speeding up and braking.
	var push := 0.0
	var going := forward_speed()
	if thrust > 0.0 and going < ship.max_speed:
		push = thrust * ship.acceleration * heft(tuning.load_acceleration_drag)
	elif thrust < 0.0 and going > -ship.max_speed * tuning.reverse_speed_fraction:
		push = thrust * ship.retro_thrust * heft(tuning.load_braking_drag)
	if boosting and going < boosted_top_speed(ship):
		push += ship.boost_acceleration
	velocity += forward * push * delta

	# 2. Grip: swing our direction of travel toward the nose, keeping speed.
	#    Boosting and going over top speed both loosen the grip.
	var current_speed := velocity.length()
	if current_speed > 0.01:
		var grip := ship.grip * heft(tuning.load_grip_drag)  # Heavy loads swing wide.
		if boosting:
			grip *= tuning.boost_grip
		grip /= 1.0 + maxf(current_speed / ship.max_speed - 1.0, 0.0) * tuning.overspeed_slip
		var catch_up := 1.0 - exp(-grip * delta)
		var direction := velocity / current_speed
		if direction.dot(forward) > 0.0:
			velocity = direction.slerp(forward, catch_up).normalized() * current_speed
		else:
			# Mostly facing backwards: only the sideways slide fades. To stop
			# going backwards, you have to burn the engines.
			var along := forward * velocity.dot(forward)
			velocity = along + (velocity - along) * (1.0 - catch_up)
	slip = (velocity - forward * velocity.dot(forward)).length()

	# 3. Speed above the limit (left over from a boost) bleeds away slowly.
	var limit := boosted_top_speed(ship) if boosting else ship.max_speed
	current_speed = velocity.length()
	if current_speed > limit:
		var bleed := (current_speed - limit) * (1.0 - exp(-tuning.overspeed_drag * delta))
		velocity = velocity.normalized() * (current_speed - bleed)

	# 4. Space is nearly frictionless: just a whisper of drag while coasting,
	#    so a ship left alone does eventually come to rest.
	#    A heavy load carries its momentum further.
	if is_zero_approx(thrust) and not boosting:
		velocity *= exp(-tuning.coast_drag * heft(tuning.load_coast_carry) * delta)


## Boost is a commitment: hold the button and it spools up, then lights;
## once lit it burns at least `boost_min_burn_seconds`, held or not.
func _update_boost(delta: float, controls: FlightControls, tuning: Tuning) -> void:
	if boost_fuel <= 0.0:
		boosting = false
		spool = 0.0
		return
	if boosting:
		burn_left -= delta
		boosting = controls.boost or burn_left > 0.0
		return
	if controls.boost:
		spool += delta / maxf(tuning.boost_spool_seconds, 0.001)
		if spool >= 1.0:
			boosting = true
			spool = 0.0
			burn_left = tuning.boost_min_burn_seconds
	else:
		spool = maxf(spool - delta * 3.0, 0.0)


## Burns main fuel for `throttle` (how hard the pilot is pushing) and
## returns the thrust the engines actually give: all of it, or a little
## "on fumes" when the tank is empty. Speeding up drinks fuel (faster =
## thirstier); holding top speed on the limiter only sips it.
func _burn_fuel(delta: float, throttle: float, ship: ShipData, tuning: Tuning) -> float:
	var speed_share := clampf(speed() / ship.max_speed, 0.0, 1.0)
	var effort := 1.0 + speed_share * speed_share * tuning.fuel_speed_burn
	if throttle > 0.0 and forward_speed() >= ship.max_speed - 0.5:
		effort = tuning.cruise_burn  # On the limiter: just holding speed.
	var burn := absf(throttle) * effort * (1.0 + load_share * tuning.load_fuel_burn)  # Weight drinks fuel.
	fuel_burn = burn / (1.0 + tuning.fuel_speed_burn)
	if fuel <= 0.0:
		return throttle * tuning.empty_tank_thrust
	fuel = maxf(fuel - burn * delta / ship.fuel_tank_seconds, 0.0)
	return throttle


func _update_turning(delta: float, controls: FlightControls, ship: ShipData, tuning: Tuning) -> void:
	var load_turn := heft(tuning.load_turn_drag)  # Heavy loads turn slower.
	var max_turn := deg_to_rad(ship.turn_rate) * load_turn
	var max_pitch := deg_to_rad(ship.pitch_rate) * load_turn
	# Turning right means clockwise seen from above, which Godot counts as a
	# NEGATIVE change of heading.
	# Under boost, steering gets twitchy (easy to over-correct).
	var twitch := tuning.boost_steer_gain if boosting else 1.0
	var wanted_turn := -controls.steer.x * max_turn * twitch
	var wanted_pitch := controls.steer.y * max_pitch * twitch
	if absf(controls.steer.y) < 0.05:
		# Hands off up/down: let the nose drift gently back toward level.
		wanted_pitch = clampf(-pitch * tuning.nose_auto_level, -max_pitch, max_pitch)

	# Heavy ships (low turn_response) take a moment to start and stop turning.
	var catch_up := 1.0 - exp(-ship.turn_response * load_turn * delta)
	turn_speed = lerpf(turn_speed, wanted_turn, catch_up)
	pitch_speed = lerpf(pitch_speed, wanted_pitch, catch_up)

	# Under boost the nose drifts slowly off course by itself (worse the
	# worse the wobbles are), and shimmies quickly side to side.
	var wander := wander_amount(tuning)
	var omega := TAU * tuning.boost_shimmy_hz
	var snap := deg_to_rad(tuning.boost_shimmy_degrees) * shimmy * omega
	heading = wrapf(heading + (turn_speed + wander * _pull(0.0) + snap * cos(_time * omega)) * delta, -PI, PI)
	pitch += (wander * 0.4 * _pull(10.0) + snap * 0.35 * cos(_time * omega * 1.3 + 1.0)) * delta
	var pitch_limit := deg_to_rad(tuning.max_pitch_degrees)
	pitch = clampf(pitch + pitch_speed * delta, -pitch_limit, pitch_limit)
	if absf(pitch) >= pitch_limit and signf(pitch_speed) == signf(pitch):
		pitch_speed = 0.0  # Stop pushing against the limit.


## How hard the nose is being pushed off course right now, in radians per
## second: a little whenever you're boosting, a lot when you're shaky.
func wander_amount(tuning: Tuning) -> float:
	if not boosting:
		return 0.0
	return deg_to_rad(tuning.boost_wander_degrees * shimmy + wobble * tuning.boost_wobble_degrees)


## How far the hull is rocking from the wobbles right now (radians, for the
## model's roll: purely looks).
func shimmy_roll(tuning: Tuning) -> float:
	return deg_to_rad(tuning.boost_shimmy_roll_degrees) * shimmy * sin(_time * TAU * tuning.boost_shimmy_hz * 0.97 + 0.6)


## Jerky steering under boost makes the rig shaky; holding steady calms it.
func _update_wobble(delta: float, controls: FlightControls, tuning: Tuning) -> void:
	var jerk := (controls.steer - _last_steer).length() / maxf(delta, 0.0001)
	_last_steer = controls.steer
	if boosting:
		wobble += jerk * tuning.boost_jerk_shake * shakiness * delta
	wobble = clampf(wobble * exp(-tuning.boost_steady_recovery * delta), 0.0, 1.0)
	# The speed wobbles build while boosting and settle quickly after.
	if boosting:
		shimmy = minf(shimmy + delta / tuning.boost_wobble_build_seconds * shakiness, 1.0)
	else:
		shimmy = maxf(shimmy - delta * 1.5, 0.0)
	shimmy = maxf(shimmy, minf(wobble, 1.0) if boosting else 0.0)


## A slow pull to one side, -1 to 1, that changes its mind only every
## ten seconds or so (so the drift feels like a steady pull, not swerving).
func _pull(offset: float) -> float:
	var t := _time + offset
	return clampf((sin(t * 0.21 + offset) + 0.3 * sin(t * 0.53)) * 1.4, -1.0, 1.0)


## How much of something's strength is left under the load: 1 when empty,
## 1 / (1 + share x drag) loaded (see "Load weight" in tuning.tres).
func heft(drag: float) -> float:
	return 1.0 / (1.0 + load_share * drag)


func _update_lean(delta: float, ship: ShipData, tuning: Tuning) -> void:
	# Lean into the turn like a plane: turning left (positive turn_speed) leans
	# left, which is a positive roll in Godot.
	var max_turn := deg_to_rad(ship.turn_rate) * heft(tuning.load_turn_drag)
	var wanted_bank := turn_speed / max_turn * deg_to_rad(ship.max_bank)
	# A loaded rig rocks a little when a turn starts or stops: a soft
	# spring, kicked by the change in lean and settling on its own.
	var omega := TAU * tuning.load_sway_hz
	_sway_speed += (-cargo_sway * omega * omega - 2.0 * tuning.load_sway_settle * omega * _sway_speed) * delta
	_sway_speed -= (wanted_bank - _last_wanted_bank) * load_share * tuning.load_sway * omega
	_last_wanted_bank = wanted_bank
	cargo_sway = clampf(cargo_sway + _sway_speed * delta, -0.25, 0.25)
	var max_pitch := deg_to_rad(ship.pitch_rate)
	var wanted_tilt := pitch_speed / max_pitch * deg_to_rad(tuning.nose_tilt_degrees)
	var catch_up := 1.0 - exp(-tuning.bank_response * delta)
	bank = lerpf(bank, wanted_bank, catch_up)
	nose_tilt = lerpf(nose_tilt, wanted_tilt, catch_up)
