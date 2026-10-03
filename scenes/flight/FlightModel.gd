class_name FlightModel
extends RefCounted
## The rules of flying, with no graphics attached: thrust, momentum, grip,
## boost, turning, and how far the rig leans. Ship.gd feeds it the pilot's
## controls every physics tick, then moves the actual ship to match.
##
## How it works (after the M1 playtest asked for real momentum):
##   - Thrust pushes the ship along its nose. W / RT burns forward, S / LT
##     burns backward, and burning backward is how you brake.
##   - Let go and you COAST: the ship keeps its momentum.
##   - "Grip" gradually swings your direction of travel around to where the
##     nose points, without losing speed, like carving a turn. Low grip =
##     wide, slidey arcs and easy overshooting; high grip = on rails.
##   - Spin the nose more than 90 degrees away from where you're going and
##     grip won't save you: burn the engines to brake.
##   - Boost shoves you far past top speed and makes grip much weaker, so the
##     rig gets wild. Afterwards the extra speed bleeds off slowly.
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
## Boost fuel, 0 (empty) to 1 (a full tank), and whether boost is firing.
var boost_fuel := 1.0
var boosting := false
## How fast we're sliding sideways (m/s): the part of our movement that isn't
## where the nose points. The engine sound and HUD use it.
var slip := 0.0
## How far the rig visibly leans into a turn, and tips its nose, in radians.
## Purely for looks: neither changes where the ship goes.
var bank := 0.0
var nose_tilt := 0.0


## Advances the flight by one step of `delta` seconds.
func update(delta: float, controls: FlightControls, ship: ShipData, tuning: Tuning) -> void:
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


## Puts everything back to "parked": stopped, engines idle, boost tank full.
func reset(new_heading: float, new_pitch: float) -> void:
	heading = new_heading
	pitch = new_pitch
	velocity = Vector3.ZERO
	turn_speed = 0.0
	pitch_speed = 0.0
	thrust = 0.0
	boost_fuel = 1.0
	boosting = false
	slip = 0.0
	bank = 0.0
	nose_tilt = 0.0


func _update_motion(delta: float, controls: FlightControls, ship: ShipData, tuning: Tuning) -> void:
	var forward := nose()
	thrust = clampf(controls.thrust, -1.0, 1.0)
	boosting = controls.boost and boost_fuel > 0.0
	if boosting:
		boost_fuel = maxf(boost_fuel - delta / ship.boost_fuel_seconds, 0.0)

	# 1. The engines push along the nose. The ship's own limiter stops the
	#    main engines adding speed past top speed; only boost goes beyond.
	var push := 0.0
	var going := forward_speed()
	if thrust > 0.0 and going < ship.max_speed:
		push = thrust * ship.acceleration
	elif thrust < 0.0 and going > -ship.max_speed * tuning.reverse_speed_fraction:
		push = thrust * ship.retro_thrust
	if boosting and going < boosted_top_speed(ship):
		push += ship.boost_acceleration
	velocity += forward * push * delta

	# 2. Grip: swing our direction of travel toward the nose, keeping speed.
	#    Boosting and going over top speed both loosen the grip.
	var current_speed := velocity.length()
	if current_speed > 0.01:
		var grip := ship.grip
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
	if is_zero_approx(thrust) and not boosting:
		velocity *= exp(-tuning.coast_drag * delta)


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
