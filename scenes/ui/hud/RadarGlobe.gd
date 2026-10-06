class_name RadarGlobe
extends HudWidget
## Bottom middle: a slowly spinning wireframe globe with blips for what's
## around you, like an old space sim's 3D radar.
## - Seen from a little above and behind: blips above the middle ring are
##   ahead of you, below it are behind you. Ships and the destination stand
##   on little stalks showing how far above or below you they are.
## - Rocks are dim green dots (red when they're close), ships are yellow,
##   the destination is a bright green diamond. Your rig is in the middle.
## How far it sees is `radar_range` in tuning.tres.


const RADIUS: float = 24.0
## How far we look down on the globe, in radians.
const TILT: float = 0.5
## How fast the wireframe spins, in radians per second (just for looks).
const SPIN: float = 0.35


func _init() -> void:
	bottom_row = true


func _draw() -> void:
	var rig := ship()
	if rig == null:
		return
	var center := Vector2(floorf(size.x * 0.5), size.y - MARGIN - RADIUS - 2.0)
	draw_circle(center, RADIUS + 3.0, BACKING)
	_draw_wireframe(center)
	_draw_blips(center, rig)
	# Our rig: a tiny arrow pointing ahead.
	pixels(center - Vector2(1, 1), [".#.", "###"], GREEN)


func _draw_wireframe(center: Vector2) -> void:
	var spin := hud.time * SPIN
	# Rings of latitude (the middle one is the "plane" you fly on).
	for height: float in [-0.6, 0.0, 0.6]:
		var ring_radius := sqrt(1.0 - height * height)
		_draw_curve(center, 24, func(a: float) -> Vector3:
			return Vector3(cos(a) * ring_radius, height, sin(a) * ring_radius), 0.9 if height == 0.0 else 0.45)
	# Lines of longitude, spinning slowly.
	for i in 4:
		var turn := spin + i * PI / 4.0
		_draw_curve(center, 24, func(a: float) -> Vector3:
			return Vector3(cos(a) * cos(turn), sin(a), cos(a) * sin(turn)), 0.35)


## Draws a closed curve on the globe, brighter at the front, dimmer behind.
func _draw_curve(center: Vector2, steps: int, point_at: Callable, brightness: float) -> void:
	var previous := Vector2.ZERO
	for i in steps + 1:
		var spot: Vector3 = point_at.call(TAU * i / steps)
		var here := _project(center, spot)
		if i > 0:
			var front := _depth(spot) > 0.0
			line(previous, here, tint(brightness * (0.75 if front else 0.3)))
		previous = here


func _draw_blips(center: Vector2, rig: Ship) -> void:
	var reach := GameState.tuning.radar_range * (ship().ship_data.radar_reach if ship() != null and ship().ship_data != null else 1.0)
	var close := GameState.tuning.proximity_range
	# Turn the world so the rig's nose points "ahead" on the globe. Only its
	# heading counts, so the globe's middle ring stays level with space.
	var facing := Basis(Vector3.UP, rig.flight.heading).inverse()
	for contact in hud.contacts:
		var offset: Vector3 = contact["position"] - rig.global_position
		var on_globe := facing * offset / reach
		if on_globe.length() > 1.0:
			if contact["kind"] != FlightHUD.Kind.STATION:
				continue  # (Other stations only show once they're on the globe.)
			on_globe = on_globe.normalized()  # Far away: pin it to the edge.
		var spot := _project(center, on_globe)
		match contact["kind"]:
			FlightHUD.Kind.ROCK:
				var near := offset.length() - float(contact["radius"]) < close
				box(Rect2(spot, Vector2.ONE), RED if near else Color(GREEN, 0.55))
			FlightHUD.Kind.SHIP:
				line(spot, _project(center, Vector3(on_globe.x, 0.0, on_globe.z)), tint(0.6))
				box(Rect2(spot - Vector2.ONE, Vector2(2, 2)), YELLOW)
			FlightHUD.Kind.PLACE:
				line(spot, _project(center, Vector3(on_globe.x, 0.0, on_globe.z)), Color(GREEN, 0.35))
				pixels(spot - Vector2(1, 1), [".#.", "###", ".#."], Color(GREEN, 0.5))
			FlightHUD.Kind.STATION:
				line(spot, _project(center, Vector3(on_globe.x, 0.0, on_globe.z)), Color(GREEN, 0.6))
				pixels(spot - Vector2(1, 1), [".#.", "###", ".#."], GREEN if blink(0.8) else Color(GREEN, 0.6))


## Where a point on the unit globe lands on screen (x = right, y = up,
## z = toward the back).
func _project(center: Vector2, spot: Vector3) -> Vector2:
	var up := spot.y * cos(TILT) - spot.z * sin(TILT)
	return (center + Vector2(spot.x, -up) * RADIUS).round()


## Positive for the half of the globe facing us.
func _depth(spot: Vector3) -> float:
	return spot.z * cos(TILT) + spot.y * sin(TILT)
