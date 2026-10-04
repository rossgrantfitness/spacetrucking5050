class_name CockpitScreen
extends Control
## One of the little monochrome screens on the dashboard, drawn in chunky
## pixel letters. Cockpit.gd shows it on a screen in the cab.
## - STATUS (green): speed, thrust, fuel, boost fuel and hull.
## - NAV (amber): an arrow toward the destination, its distance, a radar
##   with blips for nearby traffic, and the trip odometer.


enum Mode { STATUS, NAV }

const GREEN := Color(0.45, 1.0, 0.55)
const AMBER := Color(1.0, 0.72, 0.3)
const BACKGROUND := Color(0.02, 0.05, 0.03)
## How far the nav radar reaches, in meters.
const RADAR_RANGE: float = 2500.0

var mode := Mode.STATUS
var cockpit: Cockpit
## 1 right after a bonk (the picture jumps and fizzes), fading to 0.
var flicker := 0.0


func _process(delta: float) -> void:
	flicker = maxf(flicker - delta * 2.0, 0.0)


func _draw() -> void:
	var ship := cockpit.ship() if cockpit != null else null
	var tint := GREEN if mode == Mode.STATUS else AMBER
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND.lerp(tint * 0.3, 0.15))
	if ship == null:
		return
	# A bonk makes the picture jump sideways for a moment.
	var jolt := Vector2(sin(flicker * 40.0) * 6.0 * flicker, 0.0)
	draw_set_transform(jolt)
	if mode == Mode.STATUS:
		_draw_status(ship, tint)
	else:
		_draw_nav(ship, tint)
	draw_set_transform(Vector2.ZERO)
	# Scanlines, for that old-monitor glow.
	for y in range(0, int(size.y), 3):
		draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(0, 0, 0, 0.3))


func _draw_status(ship: Ship, tint: Color) -> void:
	var flight := ship.flight
	PixelFont.draw(self, Vector2(10, 8), "%d KM/H" % roundi(flight.speed() * 3.6), 3.0, tint, 0.0, Color(0, 0, 0, 0))
	_bar(Vector2(10, 34), "THR", clampf(absf(flight.thrust), 0.0, 1.0), tint if flight.thrust >= 0.0 else Color(0.4, 0.9, 1.0))
	var low_fuel := flight.fuel < GameState.tuning.low_fuel_warning
	_bar(Vector2(10, 56), "FUL", flight.fuel, Color(1.0, 0.35, 0.3) if low_fuel else tint)
	_bar(Vector2(10, 78), "BST", flight.boost_fuel, tint)
	_bar(Vector2(10, 100), "HUL", ship.hull, tint if ship.hull > 0.33 else Color(1.0, 0.35, 0.3))
	if ship.hull < 0.33 and fposmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.4:
		PixelFont.draw(self, Vector2(150, 8), "PATCH", 2.0, Color(1.0, 0.35, 0.3), 0.0, Color(0, 0, 0, 0))
		PixelFont.draw(self, Vector2(150, 24), "ME!", 2.0, Color(1.0, 0.35, 0.3), 0.0, Color(0, 0, 0, 0))


func _draw_nav(ship: Ship, tint: Color) -> void:
	var center := Vector2(64, 64)
	var radius := 52.0
	draw_arc(center, radius, 0.0, TAU, 32, tint * Color(1, 1, 1, 0.6), 1.0)
	draw_arc(center, radius * 0.5, 0.0, TAU, 24, tint * Color(1, 1, 1, 0.3), 1.0)
	draw_rect(Rect2(center - Vector2(2, 2), Vector2(4, 4)), tint)  # That's us.
	# Traffic blips.
	for other in ship.get_tree().get_nodes_in_group("traffic"):
		var blip := _radar_spot(ship, (other as Node3D).global_position, center, radius)
		if blip.distance_to(center) < radius:
			draw_rect(Rect2(blip - Vector2(2, 2), Vector2(4, 4)), Color(0.4, 0.9, 1.0))
	var target := cockpit.destination
	if target == null:
		return
	var spot := _radar_spot(ship, target.global_position, center, radius)
	var direction := (spot - center).normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	var tip := center + direction * minf(center.distance_to(spot), radius)
	draw_line(center, tip, tint, 2.0)
	draw_circle(tip, 4.0, tint)
	var meters := ship.global_position.distance_to(target.global_position)
	PixelFont.draw(self, Vector2(128, 18), "TRUCK", 2.0, tint, 0.0, Color(0, 0, 0, 0))
	PixelFont.draw(self, Vector2(128, 36), "STOP", 2.0, tint, 0.0, Color(0, 0, 0, 0))
	PixelFont.draw(self, Vector2(128, 62), "%.1f KM" % (meters / 1000.0), 3.0, tint, 0.0, Color(0, 0, 0, 0))
	PixelFont.draw(self, Vector2(128, 100), "ODO %.1f" % (ship.odometer / 1000.0), 2.0, tint * Color(1, 1, 1, 0.7), 0.0, Color(0, 0, 0, 0))


## Where something appears on the radar: seen from above, with the nose
## pointing up the screen.
func _radar_spot(ship: Ship, where: Vector3, center: Vector2, radius: float) -> Vector2:
	var local := ship.global_basis.inverse() * (where - ship.global_position)
	return center + Vector2(local.x, local.z) / RADAR_RANGE * radius


func _bar(where: Vector2, label: String, amount: float, tint: Color) -> void:
	PixelFont.draw(self, where, label, 2.0, tint, 0.0, Color(0, 0, 0, 0))
	var bar := Rect2(where + Vector2(44, 0), Vector2(180, 14))
	draw_rect(bar, tint * Color(1, 1, 1, 0.5), false, 1.0)
	var lit := ceili(clampf(amount, 0.0, 1.0) * 12.0 - 0.01)
	for i in lit:
		draw_rect(Rect2(bar.position + Vector2(2 + i * 15, 2), Vector2(12, 10)), tint)
