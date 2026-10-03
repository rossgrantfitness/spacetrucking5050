class_name SpeedGauge
extends Control
## The corner gauge cluster, in the style of late-90s PlayStation HUDs
## (Wipeout 3's slanted bars, Colony Wars' rainbow arc):
## - a chunky segmented arc that fills with speed, green to red, and hot pink
##   into boost territory, with the speed in big slanted pixel digits;
## - a slanted THRUST bar (warm = burning forward, cyan = reverse to brake);
## - a slanted BOOST FUEL bar for the boost tank;
## - a slanted HULL bar that flashes when you bonk into something.
## (Fuel and cargo condition join it in M2.)


## The arc starts at the bottom-left and sweeps three-quarters of a circle,
## clockwise over the top, to the bottom-right. Angles in radians; 0 = right.
const START_ANGLE: float = PI * 0.75
const SWEEP: float = PI * 1.5
const ARC_SEGMENTS: int = 24
const BAR_SEGMENTS: int = 14
## How far the bars lean (the top edge shifts this much right of the bottom).
const LEAN: float = 14.0
const OUTLINE := Color(1.0, 0.85, 0.25)  # Wipeout yellow.
const EMPTY := Color(1, 1, 1, 0.12)
const BACKING := Color(0.02, 0.01, 0.06, 0.45)
const REVERSE_COLOR := Color(0.35, 0.95, 1.0)

## The ship to show. Set by FlightHUD.
var ship: Ship

var _speed_colors := Gradient.new()
var _boost_colors := Gradient.new()
var _thrust_colors := Gradient.new()
var _fuel_colors := Gradient.new()
var _hull_colors := Gradient.new()
var _last_hull := 1.0
var _flash := 0.0  # 1 right after a bonk, fading to 0.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speed_colors.offsets = PackedFloat32Array([0.0, 0.5, 0.8, 1.0])
	_speed_colors.colors = PackedColorArray([Color("38e07b"), Color("d7f03a"), Color("ffb02e"), Color("ff4a3d")])
	_boost_colors.offsets = PackedFloat32Array([0.0, 1.0])
	_boost_colors.colors = PackedColorArray([Color("ff4fd8"), Color("ffffff")])
	_thrust_colors.offsets = PackedFloat32Array([0.0, 0.4, 0.75, 1.0])
	_thrust_colors.colors = PackedColorArray([Color("7a2cff"), Color("ff2f6d"), Color("ffc21a"), Color("fff6c2")])
	_fuel_colors.offsets = PackedFloat32Array([0.0, 1.0])
	_fuel_colors.colors = PackedColorArray([Color("2e7bff"), Color("4ff2ff")])
	_hull_colors.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	_hull_colors.colors = PackedColorArray([Color("ff3b3b"), Color("ff9a2e"), Color("e8f03a"), Color("38e07b")])


func _process(delta: float) -> void:
	if ship == null:
		return
	if ship.hull < _last_hull - 0.0001:
		_flash = 1.0  # Bonk!
	_last_hull = ship.hull
	_flash = maxf(_flash - delta * 2.5, 0.0)


func _draw() -> void:
	if ship == null:
		return
	var radius := 96.0
	var center := Vector2(size.x - radius - 12.0, size.y - radius - 4.0)
	_draw_speed_arc(center, radius)
	var bars_right := center.x - radius - 18.0
	_draw_thrust_bar(Rect2(bars_right - 250.0, size.y - 118.0, 250.0, 26.0))
	_draw_fuel_bar(Rect2(bars_right - 250.0, size.y - 58.0, 250.0, 20.0))
	_draw_hull_bar(Rect2(bars_right - 250.0, size.y - 176.0, 250.0, 20.0))


func _draw_speed_arc(center: Vector2, radius: float) -> void:
	var thickness := 26.0
	var inner := radius - thickness
	var top_speed := FlightModel.boosted_top_speed(ship.ship_data)
	var normal_share := ship.ship_data.max_speed / top_speed  # Where boost begins.
	var fill := clampf(ship.flight.speed() / top_speed, 0.0, 1.0)

	draw_circle(center, radius + 6.0, BACKING)
	var gap := 0.025  # A little gap between segments, in radians.
	for i in ARC_SEGMENTS:
		var from := float(i) / ARC_SEGMENTS
		var to := float(i + 1) / ARC_SEGMENTS
		var middle := (from + to) * 0.5
		var color := EMPTY
		if middle <= fill:
			if middle < normal_share:
				color = _speed_colors.sample(middle / normal_share)
			else:
				color = _boost_colors.sample((middle - normal_share) / (1.0 - normal_share))
		_segment(center, inner, radius, _angle(from) + gap, _angle(to) - gap, color)
	# A chunky outline around the whole arc.
	var outline := PackedVector2Array()
	for i in 41:
		outline.append(center + Vector2.from_angle(_angle(i / 40.0)) * (radius + 3.0))
	for i in 41:
		outline.append(center + Vector2.from_angle(_angle(1.0 - i / 40.0)) * (inner - 3.0))
	outline.append(outline[0])
	draw_polyline(outline, OUTLINE, 2.0)
	# A white notch where boost territory begins.
	var notch := Vector2.from_angle(_angle(normal_share))
	draw_line(center + notch * (inner - 8.0), center + notch * (radius + 8.0), Color.WHITE, 3.0)

	var speed_text := "%d" % roundi(ship.flight.speed() * 3.6)
	PixelFont.draw_centered(self, center + Vector2(0.0, -6.0), speed_text, 6.0, Color.WHITE, 0.2)
	# A little slanted tag under the number, like Wipeout's "KPH".
	var tag := Rect2(center.x - 30.0, center.y + 26.0, 60.0, 20.0)
	_slanted(tag, OUTLINE, 6.0)
	PixelFont.draw_centered(self, tag.get_center(), "KM/H", 2.0, Color(0.1, 0.05, 0.15), 0.15, Color(0, 0, 0, 0))


func _draw_thrust_bar(area: Rect2) -> void:
	var thrust := clampf(ship.flight.thrust, -1.0, 1.0)
	var reversing := thrust < -0.01
	_bar_backing(area)
	var lit := ceili(absf(thrust) * BAR_SEGMENTS - 0.01)
	for i in BAR_SEGMENTS:
		var color := EMPTY
		if i < lit:
			color = REVERSE_COLOR if reversing else _thrust_colors.sample(float(i) / (BAR_SEGMENTS - 1))
		_bar_segment(area, i, color)
	_slanted(area.grow(3.0), OUTLINE, LEAN, false)
	var label := "REVERSE" if reversing else "THRUST"
	PixelFont.draw(self, Vector2(area.end.x - PixelFont.width(label, 2.0) + LEAN, area.position.y - 22.0), label, 2.0, REVERSE_COLOR if reversing else Color.WHITE, 0.2)


func _draw_fuel_bar(area: Rect2) -> void:
	var tank := clampf(ship.flight.boost_fuel, 0.0, 1.0)
	_bar_backing(area)
	var lit := ceili(tank * BAR_SEGMENTS - 0.01)
	for i in BAR_SEGMENTS:
		var color := EMPTY
		if i < lit:
			color = Color.WHITE if ship.flight.boosting else _fuel_colors.sample(float(i) / (BAR_SEGMENTS - 1))
		_bar_segment(area, i, color)
	_slanted(area.grow(3.0), OUTLINE, LEAN, false)
	PixelFont.draw(self, Vector2(area.position.x, area.end.y + 9.0), "BOOST FUEL", 2.0, Color.WHITE, 0.2)


func _draw_hull_bar(area: Rect2) -> void:
	var hull := clampf(ship.hull, 0.0, 1.0)
	_bar_backing(area)
	var lit := ceili(hull * BAR_SEGMENTS - 0.01)
	var color := _hull_colors.sample(hull).lerp(Color.WHITE, _flash)
	for i in BAR_SEGMENTS:
		_bar_segment(area, i, color if i < lit else EMPTY)
	_slanted(area.grow(3.0), OUTLINE.lerp(Color(1.0, 0.3, 0.3), _flash), LEAN, false)
	var label := "HULL %d%%" % roundi(hull * 100.0)
	PixelFont.draw(self, Vector2(area.end.x - PixelFont.width(label, 2.0) + LEAN, area.position.y - 22.0), label, 2.0, Color.WHITE.lerp(Color(1.0, 0.4, 0.4), _flash), 0.2)


## One segment of a slanted bar.
func _bar_segment(area: Rect2, index: int, color: Color) -> void:
	var step := area.size.x / BAR_SEGMENTS
	var piece := Rect2(area.position.x + step * index + 1.5, area.position.y, step - 3.0, area.size.y)
	_slanted(piece, color, LEAN * piece.size.y / area.size.y)


func _bar_backing(area: Rect2) -> void:
	_slanted(area.grow(6.0), BACKING, LEAN)


## A parallelogram leaning forward by `lean` (filled, or just its outline).
func _slanted(area: Rect2, color: Color, lean: float, filled: bool = true) -> void:
	var corners := PackedVector2Array([
		Vector2(area.position.x + lean, area.position.y), Vector2(area.end.x + lean, area.position.y),
		Vector2(area.end.x, area.end.y), Vector2(area.position.x, area.end.y)])
	if filled:
		draw_colored_polygon(corners, color)
	else:
		corners.append(corners[0])
		draw_polyline(corners, color, 2.0)


## One chunky curved segment of the speed arc.
func _segment(center: Vector2, inner: float, outer: float, from_angle: float, to_angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	var steps := 3
	for i in steps + 1:
		points.append(center + Vector2.from_angle(lerpf(from_angle, to_angle, float(i) / steps)) * outer)
	for i in steps + 1:
		points.append(center + Vector2.from_angle(lerpf(to_angle, from_angle, float(i) / steps)) * inner)
	draw_colored_polygon(points, color)


func _angle(amount: float) -> float:
	return START_ANGLE + SWEEP * amount
