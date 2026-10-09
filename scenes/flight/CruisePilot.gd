class_name CruisePilot
extends RefCounted
## The cruise autopilot: flies the rig along a charted course (press M in
## flight) at cruise speed, on the limiter so it only sips fuel. It drives
## like a careful trucker: gentle turns that never rattle the cargo, and it
## steers around rocks, junk and traffic it sees coming.
##
## It "holds the stick" by filling in FlightControls, exactly like your
## hands do, so the rig flies the same way it does for you (same handling,
## same fuel burn). It forgives small inputs: a nudge of the stick moves
## the rig a little and it steers back on course. Push harder (or work the
## throttle) for a moment and it lets go (see feel_hands and Ship.gd). It
## never boosts on its own: that's your call. Hold boost and it keeps
## steering the course while you boost (Ship.gd).


## The spots to fly through, in order (in the world). The course chart
## fills these in: usually "line up outside a place's approach ring", then
## "the ring itself" (flying through it starts the docking autopilot).
var waypoints: Array[Vector3] = []
## How close (in meters) counts as having reached a waypoint.
var reach: float = 120.0
## Eases off to this speed (m/s) for the last waypoint (0 = full cruise
## speed all the way).
var arrival_speed: float = 0.0

var _controls := FlightControls.new()
## How close the pilot is to taking over: 0 = hands off, 1 = theirs.
var grab: float = 0.0
var _avoid := Vector3.ZERO
var _avoid_clock: float = 0.0


## Feels the pilot's hands on the controls this step. Returns true when
## they've taken over (a firm push held for a moment, or the throttle).
## Small nudges don't count: they're mixed into the autopilot's own steering
## by mix_in. Boost doesn't count either: the autopilot keeps flying.
func feel_hands(hands: FlightControls, delta: float) -> bool:
	var tuning := GameState.tuning
	var push := maxf(hands.steer.length(), maxf(absf(hands.roll), hands.strafe.length()))
	var rate := 0.0
	if push > tuning.autopilot_tolerance:
		rate = 2.0 if push > 0.95 else 1.0
	if absf(hands.throttle_push) > 0.1:
		rate = maxf(rate, 1.0)
	if rate > 0.0:
		grab += rate * delta / maxf(tuning.autopilot_grab_seconds, 0.01)
	else:
		grab = maxf(grab - delta / maxf(tuning.autopilot_grab_seconds, 0.01), 0.0)
	return grab >= 1.0


## Mixes a small nudge from the pilot into the autopilot's steering.
static func mix_in(auto: FlightControls, hands: FlightControls, tuning: Tuning) -> void:
	auto.steer = (auto.steer + hands.steer * tuning.autopilot_nudge_share).limit_length(1.0)
	auto.roll = clampf(auto.roll + hands.roll * tuning.autopilot_nudge_share, -1.0, 1.0)
	auto.strafe = (auto.strafe + hands.strafe * tuning.autopilot_nudge_share).limit_length(1.0)


## Whether it has reached the end of its course.
func is_done() -> bool:
	return waypoints.is_empty()


## The pilot's hands for this physics step.
func steer(ship: Ship, delta: float) -> FlightControls:
	var here := ship.global_position
	while not waypoints.is_empty() and here.distance_to(waypoints[0]) < reach:
		waypoints.pop_front()
	# Already past this one (carried on by a toll lane's current, say)?
	# Don't turn back for it: on to the next.
	while waypoints.size() >= 2 and (here - waypoints[0]).dot(waypoints[1] - waypoints[0]) > 0.0 \
			and here.distance_to(Geometry3D.get_closest_point_to_segment(here, waypoints[0], waypoints[1])) < reach * 3.0:
		waypoints.pop_front()
	_controls.boost = false
	if waypoints.is_empty():
		_controls.steer = Vector2.ZERO
		_controls.roll = 0.0
		_controls.strafe = Vector2.ZERO
		_controls.thrust = 0.0
		return _controls
	var flight := ship.flight
	var to_target := waypoints[0] - here
	var distance := to_target.length()
	var wanted := to_target / distance

	# Look ahead for things in the way (a few times a second is plenty).
	_avoid_clock -= delta
	if _avoid_clock <= 0.0:
		_avoid_clock = 0.15
		_avoid = avoidance(ship)
	if not _avoid.is_zero_approx():
		wanted = (wanted + _avoid * 1.6).normalized()

	# Turn toward `wanted`, gently: never so hard that the sideways push
	# rattles the cargo (see Ship._shake_cargo).
	var tuning := GameState.tuning
	var speed := maxf(flight.speed(), 1.0)
	var gentle := tuning.cargo_comfy_accel * 0.6 / speed
	var max_turn := deg_to_rad(ship.ship_data.turn_rate)
	var max_pitch := deg_to_rad(ship.ship_data.pitch_rate)
	var yaw_error := wrapf(atan2(-wanted.x, -wanted.z) - flight.heading, -PI, PI)
	var pitch_error := asin(clampf(wanted.y, -0.95, 0.95)) - flight.pitch
	_controls.roll = 0.0
	_controls.strafe = Vector2.ZERO
	if flight.newtonian:
		# Newtonian: aim in the rig's own frame (it can be rolled), turn no
		# harder than the side thrusters can keep the drift in check, and
		# keep the wings level with the road like a careful trucker.
		var local := flight.attitude.inverse() * wanted
		yaw_error = atan2(-local.x, -local.z)
		pitch_error = atan2(local.y, Vector2(local.x, local.z).length())
		var side := ship.ship_data.acceleration * tuning.strafe_thrust
		gentle = minf(gentle, side * 0.8 / speed)
		var world_up := flight.attitude.inverse() * Vector3.UP
		var tilt := atan2(world_up.x, world_up.y)
		var max_roll := max_turn * tuning.roll_rate
		_controls.roll = clampf(tilt * 1.2, -max_roll, max_roll) / max_roll
	var turn_rate := clampf(yaw_error * 0.9, -minf(gentle, max_turn), minf(gentle, max_turn))
	var pitch_rate := clampf(pitch_error * 0.9, -minf(gentle, max_pitch), minf(gentle, max_pitch))
	# Turning left is a positive change of heading, but steering right is +x.
	_controls.steer = Vector2(-turn_rate / max_turn, pitch_rate / max_pitch)

	# Speed: cruise on the limiter; slow down for sharp turns (so the rig
	# doesn't slide) and for the last waypoint.
	var goal := ship.ship_data.max_speed
	if absf(yaw_error) > 0.5:
		goal *= 0.6
	if arrival_speed > 0.0 and waypoints.size() == 1:
		goal = minf(goal, arrival_speed + distance * 0.03)
	var going := flight.forward_speed()
	if flight.newtonian:
		# Newtonian: momentum is free, so keep whatever speed she's built up
		# (a boost to 2000 km/h stays 2000 km/h), and plan the braking burn
		# so the retro thrusters slow her in time for the end of the course.
		# (But not while swinging round a sharp turn: slow for that.)
		if absf(yaw_error) <= 0.5:
			goal = maxf(goal, going)
		var remaining := distance
		for i in range(1, waypoints.size()):
			remaining += waypoints[i - 1].distance_to(waypoints[i])
		var brakes := ship.ship_data.retro_thrust * flight.heft(tuning.load_braking_drag) * 0.75
		var end_speed := arrival_speed if arrival_speed > 0.0 else ship.ship_data.max_speed
		goal = minf(goal, sqrt(end_speed * end_speed + 2.0 * brakes * maxf(remaining - 300.0, 0.0)))
		# And brake in time for a sharp corner at the next waypoint, so the
		# rig can actually make the turn (coming off a toll lane fast, say).
		if waypoints.size() >= 2:
			var corner := wanted.angle_to((waypoints[1] - waypoints[0]).normalized())
			if corner > deg_to_rad(35.0):
				var corner_speed := ship.ship_data.max_speed
				goal = minf(goal, sqrt(corner_speed * corner_speed + 2.0 * brakes * maxf(distance - 300.0, 0.0)))
	if going < goal - 1.0:
		_controls.thrust = 1.0
	elif going > goal + 6.0:
		_controls.thrust = -1.0 if flight.newtonian else -0.6
	else:
		# At the limiter, holding the throttle just sips fuel; below it, coast.
		_controls.thrust = 1.0 if goal >= ship.ship_data.max_speed - 0.5 else 0.0
	return _controls


## Which way to lean to miss whatever is in the path ahead (zero if the
## way is clear). Looks at rocks, junk and traffic.
static func avoidance(ship: Ship) -> Vector3:
	var here := ship.global_position
	var ahead := ship.flight.velocity.normalized() if ship.flight.speed() > 5.0 else ship.flight.nose()
	var look := maxf(ship.flight.speed() * 9.0, 300.0)
	var obstacles: Array[Vector4] = []
	for field: AsteroidField in ship.get_tree().get_nodes_in_group("asteroid_fields"):
		obstacles.append_array(field.rocks_within(here, look))
	for other: Node3D in ship.get_tree().get_nodes_in_group("traffic"):
		var radius := 30.0
		if other is RoadsideThing:
			radius = (other as RoadsideThing).contact_radius
		elif other is TrafficShip:
			radius = (other as TrafficShip).hull_size.length() * 0.5
		if here.distance_to(other.global_position) < look + radius:
			var spot := other.global_position
			obstacles.append(Vector4(spot.x, spot.y, spot.z, radius))
	var push := Vector3.ZERO
	for obstacle in obstacles:
		var offset := Vector3(obstacle.x, obstacle.y, obstacle.z) - here
		var along := offset.dot(ahead)
		if along <= 0.0 or along > look:
			continue
		var miss := offset - ahead * along  # From our path to its middle.
		var clearance := obstacle.w + 40.0
		if miss.length() >= clearance:
			continue
		var away := -miss.normalized() if miss.length() > 0.5 else ahead.cross(Vector3.UP).normalized()
		# Closer and more head-on = lean harder.
		push += away * (1.0 - miss.length() / clearance) * (1.0 - along / look)
	return push.limit_length(1.0)
