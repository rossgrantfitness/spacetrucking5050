class_name FuelGauge
extends HudWidget
## Bottom right: the main fuel tank as a chunky segmented arc (green, yellow
## when it's getting low, red under the low-fuel line), with the percentage
## in the middle.
##
## Under it, the fuel-economy arrow: green and pointing up when you're
## flying thriftily (coasting is free), yellow and flat when you're working
## the engines, red and pointing down when you're flooring it at speed or
## boosting. Flying faster burns more fuel; the skill is knowing when to coast.


const RADIUS: int = 18
const THICKNESS: int = 5
const SEGMENTS: int = 15
## The arc starts at the bottom-left and sweeps three-quarters of a circle,
## over the top, to the bottom-right (angles in radians; 0 = right).
const START_ANGLE: float = PI * 0.75
const SWEEP: float = PI * 1.5

const ARROWS := [
	["..###", "...##", "..#.#", ".#...", "#...."],  # Thrifty: up and away.
	["..#..", "...#.", "#####", "...#.", "..#.."],  # Working: flat.
	["#....", ".#...", "..#.#", "...##", "..###"],  # Thirsty: down.
]

var _shown_fuel: int = 100
var _rating: int = 0


func _init() -> void:
	bottom_row = true


func hud_step(_delta: float, numbers_due: bool) -> void:
	if numbers_due and ship() != null:
		_shown_fuel = ceili(ship().flight.fuel * 100.0)
		_rating = ship().flight.economy_rating(GameState.tuning)


## Where the middle of the arc is (HullSilhouette sits just right of it).
func arc_center() -> Vector2:
	return Vector2(size.x - MARGIN - 34.0, size.y - MARGIN - RADIUS - 3.0).floor()


func _draw() -> void:
	var rig := ship()
	if rig == null:
		return
	var fuel := rig.flight.fuel
	var low := GameState.tuning.low_fuel_warning
	var center := arc_center()
	draw_circle(center, RADIUS + 3.0, BACKING)
	var lit := ceili(fuel * SEGMENTS - 0.01)
	var color := GREEN
	if fuel < low:
		color = RED
	elif fuel < low * 2.0:
		color = YELLOW
	# The arc is drawn one HUD pixel at a time, so its edges stay crisp.
	for y in range(-RADIUS, RADIUS + 1):
		for x in range(-RADIUS, RADIUS + 1):
			var segment := segment_at(Vector2(x, y) + Vector2(0.5, 0.5))
			if segment < 0:
				continue
			var segment_color := tint(0.18)
			if segment < lit:
				segment_color = color
				if fuel < low and segment == lit - 1 and not blink(0.5):
					segment_color = tint(0.18)  # The last drop blinks.
			box(Rect2(center + Vector2(x, y), Vector2.ONE), segment_color)
	# The percentage and label in the middle.
	text_centered(center + Vector2(0, -6), str(_shown_fuel), color, BIG)
	text_centered(center + Vector2(0, 3), "FUEL", tint(0.85))
	# The economy arrow, in the arc's open bottom.
	var arrow_color: Color = [GREEN, YELLOW, RED][_rating]
	text(center + Vector2(-9, 12), "ECO", tint(0.85))
	pixels(center + Vector2(4, 12), ARROWS[_rating], arrow_color)


## Which segment of the arc the pixel at `offset` (from the middle) belongs
## to, or -1 if it's outside the arc or in a gap between segments.
static func segment_at(offset: Vector2) -> int:
	var distance := offset.length()
	if distance < RADIUS - THICKNESS or distance > RADIUS:
		return -1
	var along := fposmod(offset.angle() - START_ANGLE, TAU)
	if along > SWEEP:
		return -1
	var place := along / SWEEP * SEGMENTS
	if place - floorf(place) < 0.18:
		return -1  # The little gap before each segment.
	return mini(floori(place), SEGMENTS - 1)
