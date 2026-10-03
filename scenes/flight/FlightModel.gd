class_name FlightModel
extends RefCounted
## The rules of flying, with no graphics attached: the throttle lever, speed,
## boost, turning, and how far the rig leans. Ship.gd feeds it the pilot's
## controls every physics tick, then moves the actual ship to match.
##
## It's "an airplane in space": the ship always flies exactly where its nose
## points (no sliding sideways, no endless drifting), the throttle sets a
## target speed that the ship eases toward, and turns ramp up and down
## according to how heavy the ship is.
##
## Keeping these rules separate makes them easy to read and to test (see
## tools/tests/FlightTests.gd).


## Boosting needs at least this much in the tank to START, so tapping boost on
## a nearly empty tank doesn't stutter on and off.
const BOOST_START_MINIMUM: float = 0.15

## Throttle lever position, 0 (stopped) to 1 (full).
var throttle := 0.0
## Current forward speed, in meters per second.
var speed := 0.0
## Where the nose points, in radians: heading is left/right, pitch is up/down.
var heading := 0.0
var pitch := 0.0
## How fast we're turning right now, in radians per second.
var turn_speed := 0.0
var pitch_speed := 0.0
## Boost tank, 0 (empty) to 1 (full), and whether boost is firing.
var boost_tank := 1.0
var boosting := false
## How far the rig visibly leans into a turn, and tips its nose, in radians.
## Purely for looks: neither changes where the ship goes.
var bank := 0.0
var nose_tilt := 0.0

# Set when the tank runs dry mid-boost: boost must be let go of before it can
# fire again (otherwise holding the button would pulse it on and off).
var _boost_locked := false


## Advances the flight by one step of `delta` seconds.
func update(delta: float, controls: FlightControls, ship: ShipData, tuning: Tuning) -> void:
	_update_throttle_and_boost(delta, controls, ship, tuning)
	_update_speed(delta, ship, tuning)
	_update_turning(delta, controls, ship, tuning)
	_update_lean(delta, ship, tuning)


## Which way the ship faces. It never contains any roll (the lean is only
## visual), and that's what keeps the horizon level.
func orientation() -> Basis:
	return Basis.from_euler(Vector3(pitch, heading, 0.0))


## The ship always moves exactly where its nose points. (In Godot, "forward"
## is the -Z direction.)
func velocity() -> Vector3:
	return -orientation().z * speed


## The fastest this ship can ever go: top speed plus the boost bonus.
static func boosted_top_speed(ship: ShipData) -> float:
	return ship.max_speed * (1.0 + ship.boost_speed_bonus)


## How hard we're turning, from -1 (full left) to 1 (full right).
func turn_amount(ship: ShipData) -> float:
	return -turn_speed / deg_to_rad(ship.turn_rate)


## Puts everything back to "parked": stopped, throttle off, tank full.
func reset(new_heading: float, new_pitch: float) -> void:
	heading = new_heading
	pitch = new_pitch
	throttle = 0.0
	speed = 0.0
	turn_speed = 0.0
	pitch_speed = 0.0
	boost_tank = 1.0
	boosting = false
	bank = 0.0
	nose_tilt = 0.0
	_boost_locked = false


func _update_throttle_and_boost(delta: float, controls: FlightControls, ship: ShipData, tuning: Tuning) -> void:
	throttle = clampf(throttle + controls.throttle_change * tuning.throttle_lever_speed * delta, 0.0, 1.0)

	if not controls.boost:
		_boost_locked = false
	var can_start := boost_tank >= BOOST_START_MINIMUM and not _boost_locked
	boosting = controls.boost and boost_tank > 0.0 and (boosting or can_start)
	if boosting:
		boost_tank = maxf(boost_tank - delta / ship.boost_duration, 0.0)
		if boost_tank <= 0.0:
			boosting = false
			_boost_locked = true
	else:
		boost_tank = minf(boost_tank + delta / ship.boost_recharge_time, 1.0)


func _update_speed(delta: float, ship: ShipData, tuning: Tuning) -> void:
	var target := throttle * ship.max_speed
	var push := ship.acceleration
	if boosting:
		target = boosted_top_speed(ship)
		push = ship.boost_acceleration
	var difference := target - speed
	# Far from the target speed, change at the ship's full acceleration (or
	# braking) rate. Close to it, ease in gently, like a heavy truck settling
	# into cruise.
	var rate_limit := push if difference > 0.0 else ship.braking
	var change := clampf(difference * tuning.speed_settle, -rate_limit, rate_limit) * delta
	if absf(change) > absf(difference):
		change = difference  # Never overshoot the target.
	speed = maxf(speed + change, 0.0)


func _update_turning(delta: float, controls: FlightControls, ship: ShipData, tuning: Tuning) -> void:
	var max_turn := deg_to_rad(ship.turn_rate)
	var max_pitch := deg_to_rad(ship.pitch_rate)
	# Turning right means clockwise seen from above, which Godot counts as a
	# NEGATIVE change of heading.
	var wanted_turn := -controls.steer.x * max_turn
	var wanted_pitch := controls.steer.y * max_pitch
	if absf(controls.steer.y) < 0.05:
		# Hands off up/down: let the nose drift gently back toward level.
		wanted_pitch = clampf(-pitch * tuning.nose_auto_level, -max_pitch, max_pitch)

	# Heavy ships (low turn_response) take a moment to start and stop turning.
	var catch_up := 1.0 - exp(-ship.turn_response * delta)
	turn_speed = lerpf(turn_speed, wanted_turn, catch_up)
	pitch_speed = lerpf(pitch_speed, wanted_pitch, catch_up)

	heading = wrapf(heading + turn_speed * delta, -PI, PI)
	var pitch_limit := deg_to_rad(tuning.max_pitch_degrees)
	pitch = clampf(pitch + pitch_speed * delta, -pitch_limit, pitch_limit)
	if absf(pitch) >= pitch_limit and signf(pitch_speed) == signf(pitch):
		pitch_speed = 0.0  # Stop pushing against the limit.


func _update_lean(delta: float, ship: ShipData, tuning: Tuning) -> void:
	# Lean into the turn like a plane: turning left (positive turn_speed) leans
	# left, which is a positive roll in Godot.
	var max_turn := deg_to_rad(ship.turn_rate)
	var wanted_bank := turn_speed / max_turn * deg_to_rad(ship.max_bank)
	var max_pitch := deg_to_rad(ship.pitch_rate)
	var wanted_tilt := pitch_speed / max_pitch * deg_to_rad(tuning.nose_tilt_degrees)
	var catch_up := 1.0 - exp(-tuning.bank_response * delta)
	bank = lerpf(bank, wanted_bank, catch_up)
	nose_tilt = lerpf(nose_tilt, wanted_tilt, catch_up)
