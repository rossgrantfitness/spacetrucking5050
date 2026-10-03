class_name SpeedGauge
extends Control
## The corner speedometer: a gradient arc that fills up with speed, a tick
## where boost speed begins, the speed in km/h, a little thrust bar (warm =
## burning forward, cyan = burning backward to brake), and a thin inner arc
## for the boost fuel tank. (The fuel and cargo gauges join it in M2.)


## The arc starts at the bottom-left and sweeps three-quarters of a circle,
## clockwise, to the bottom-right. Angles are in radians; 0 points right.
const START_ANGLE: float = PI * 0.75
const SWEEP: float = PI * 1.5
const ARC_WIDTH: float = 12.0
const BOOST_COLOR := Color(0.45, 0.95, 1.0)

## The ship to show. Set by FlightHUD.
var ship: Ship

var _gradient := Gradient.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Cool colors at cruising speed, warming up as you go faster.
	_gradient.offsets = PackedFloat32Array([0.0, 0.35, 0.62, 0.8, 1.0])
	_gradient.colors = PackedColorArray([
		Color(0.4, 0.9, 1.0), Color(0.55, 1.0, 0.55), Color(1.0, 0.9, 0.35),
		Color(1.0, 0.6, 0.3), Color(1.0, 0.4, 0.75)])


func _draw() -> void:
	if ship == null:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - ARC_WIDTH
	var top_speed := FlightModel.boosted_top_speed(ship.ship_data)
	var fill := clampf(ship.flight.speed() / top_speed, 0.0, 1.0)

	# The empty track, then the filled part, drawn in small colored slices.
	draw_arc(center, radius, START_ANGLE, START_ANGLE + SWEEP, 64, Color(1, 1, 1, 0.14), ARC_WIDTH, true)
	var slices := 48
	for i in slices:
		var from := float(i) / slices
		if from >= fill:
			break
		var to := minf(float(i + 1) / slices, fill)
		draw_arc(center, radius, _angle(from), _angle(to), 3, _gradient.sample(from), ARC_WIDTH, true)

	# A tick where normal top speed ends and boost territory begins.
	var normal_top := ship.ship_data.max_speed / top_speed
	_tick(center, radius - ARC_WIDTH * 0.5, radius + ARC_WIDTH * 1.2, normal_top, Color(1, 1, 1, 0.7), 2.0)

	# The thrust bar: grows right while burning forward, left while braking.
	var bar_center := center + Vector2(0.0, 52.0)
	draw_rect(Rect2(bar_center - Vector2(40.0, 3.0), Vector2(80.0, 6.0)), Color(1, 1, 1, 0.14))
	var thrust := ship.flight.thrust
	if absf(thrust) > 0.01:
		var thrust_color := Color(1.0, 0.65, 0.3) if thrust > 0.0 else BOOST_COLOR
		var width := 40.0 * absf(thrust)
		var left := bar_center.x if thrust > 0.0 else bar_center.x - width
		draw_rect(Rect2(Vector2(left, bar_center.y - 3.0), Vector2(width, 6.0)), thrust_color)

	# The boost fuel tank: a thin inner arc.
	var boost_radius := radius - ARC_WIDTH - 6.0
	draw_arc(center, boost_radius, START_ANGLE, START_ANGLE + SWEEP, 48, Color(1, 1, 1, 0.1), 5.0, true)
	var tank := ship.flight.boost_fuel
	if tank > 0.0:
		var glow := BOOST_COLOR if not ship.flight.boosting else Color.WHITE
		draw_arc(center, boost_radius, START_ANGLE, _angle(tank), 32, glow, 5.0, true)

	var font := get_theme_default_font()
	var speed_text := "%d" % roundi(ship.flight.speed() * 3.6)
	draw_string_outline(font, center + Vector2(-70.0, 12.0), speed_text, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 40, 6, Color(0, 0, 0, 0.6))
	draw_string(font, center + Vector2(-70.0, 12.0), speed_text, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 40, Color.WHITE)
	draw_string(font, center + Vector2(-70.0, 32.0), "km/h", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 14, Color(1, 1, 1, 0.65))
	draw_string(font, center + Vector2(-70.0, radius + 8.0), "BOOST FUEL", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 12, BOOST_COLOR)


func _angle(amount: float) -> float:
	return START_ANGLE + SWEEP * amount


func _tick(center: Vector2, inner: float, outer: float, amount: float, color: Color, width: float) -> void:
	var direction := Vector2.from_angle(_angle(amount))
	draw_line(center + direction * inner, center + direction * outer, color, width, true)
