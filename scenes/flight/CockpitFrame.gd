class_name CockpitFrame
extends Control
## The placeholder cockpit, drawn on top of the 3D view: chunky
## yellow-and-black hazard-striped struts framing the windshield like a truck
## cab, a dashboard along the bottom, and a glowing green screen with speed,
## thrust and boost fuel.
##
## The frame sways a little when you turn (the weight of the rig) but never
## tilts, so it also works as a steady reference for motion-sensitive players.
## (M4 and M5 replace this with real instruments, gizmos and a radar globe.)


const HAZARD_TEXTURE := preload("res://textures/generated/hazard_stripes.png")
## Each stripe-texture pixel is drawn this many screen pixels big.
const STRIPE_SCALE: float = 2.0
const OUTLINE_COLOR := Color(0.05, 0.04, 0.08)
const DASH_COLOR := Color(0.09, 0.08, 0.14)
const SCREEN_COLOR := Color(0.02, 0.07, 0.04)
const SCREEN_GREEN := Color(0.45, 1.0, 0.55)
## The struts reach this far past the screen edges, so swaying never shows a gap.
const OVERHANG: float = 90.0

## The ship whose speed and turning the cockpit shows. Set by FlightSandbox.
var ship: Ship
var _sway := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED  # Lets the stripes tile.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Keeps them crisp.


func _process(delta: float) -> void:
	if ship == null or not is_visible_in_tree():
		return
	var tuning := GameState.tuning
	# Your head lags behind the cab a little: turning right slides the frame
	# right, pitching up slides it up.
	var turn := ship.flight.turn_amount(ship.ship_data)
	var pitching := ship.flight.pitch_speed / deg_to_rad(ship.ship_data.pitch_rate)
	var wanted := Vector2(turn, -pitching) * tuning.cockpit_sway
	_sway = _sway.lerp(wanted, 1.0 - exp(-tuning.cockpit_sway_response * delta))
	queue_redraw()


func _draw() -> void:
	if ship == null:
		return
	var w := size.x
	var h := size.y
	var roof := h * 0.085
	var dash_top := h * 0.78
	draw_set_transform(_sway)

	# Left and right pillars: thicker near the dashboard, like a truck cab.
	_strut([Vector2(-OVERHANG, -OVERHANG), Vector2(w * 0.06, -OVERHANG), Vector2(w * 0.11, dash_top), Vector2(-OVERHANG, dash_top)])
	_strut([Vector2(w + OVERHANG, -OVERHANG), Vector2(w * 0.94, -OVERHANG), Vector2(w * 0.89, dash_top), Vector2(w + OVERHANG, dash_top)])
	# The roof bar, with chunky corner braces.
	_strut([Vector2(-OVERHANG, -OVERHANG), Vector2(w + OVERHANG, -OVERHANG), Vector2(w + OVERHANG, roof), Vector2(-OVERHANG, roof)])
	_strut([Vector2(w * 0.06, roof), Vector2(w * 0.06 + 70.0, roof), Vector2(w * 0.062, roof + 70.0)])
	_strut([Vector2(w * 0.94, roof), Vector2(w * 0.94 - 70.0, roof), Vector2(w * 0.938, roof + 70.0)])

	# The dashboard, with a hazard-striped trim along its top edge.
	draw_colored_polygon(PackedVector2Array([
			Vector2(-OVERHANG, dash_top), Vector2(w + OVERHANG, dash_top),
			Vector2(w + OVERHANG, h + OVERHANG), Vector2(-OVERHANG, h + OVERHANG)]), DASH_COLOR)
	_strut([Vector2(-OVERHANG, dash_top - 10.0), Vector2(w + OVERHANG, dash_top - 10.0), Vector2(w + OVERHANG, dash_top + 8.0), Vector2(-OVERHANG, dash_top + 8.0)])

	_draw_screen(Rect2(w * 0.5 - 170.0, dash_top + 22.0, 340.0, h - dash_top - 40.0))


## One strut: hazard stripes inside a thick dark outline.
func _strut(corners: Array[Vector2]) -> void:
	var points := PackedVector2Array(corners)
	var uvs := PackedVector2Array()
	for point in points:
		uvs.append(point / (HAZARD_TEXTURE.get_width() * STRIPE_SCALE))
	draw_colored_polygon(points, Color.WHITE, uvs, HAZARD_TEXTURE)
	points.append(points[0])
	draw_polyline(points, OUTLINE_COLOR, 4.0)


## The little monochrome green screen on the dash.
func _draw_screen(area: Rect2) -> void:
	draw_rect(area, SCREEN_COLOR)
	draw_rect(area, SCREEN_GREEN * Color(1, 1, 1, 0.6), false, 2.0)
	var left := area.position.x + 16.0
	var top := area.position.y
	var speed_kmh := roundi(ship.flight.speed() * 3.6)
	PixelFont.draw(self, Vector2(left, top + 12.0), "SPEED %d KM/H" % speed_kmh, 3.0, SCREEN_GREEN, 0.0, Color(0, 0, 0, 0))
	_thrust_bar(Vector2(left, top + 44.0), ship.flight.thrust)
	_bar(Vector2(left, top + 70.0), "BOOST FUEL", ship.flight.boost_fuel)
	# Faint scanlines, for that old-monitor glow.
	var y := area.position.y + 2.0
	while y < area.end.y:
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(0, 0, 0, 0.25))
		y += 3.0


## Thrust shown from the middle of the bar: right = forward, left = reverse.
func _thrust_bar(where: Vector2, thrust: float) -> void:
	PixelFont.draw(self, where + Vector2(0.0, 4.0), "THRUST", 2.0, SCREEN_GREEN, 0.0, Color(0, 0, 0, 0))
	var bar := Rect2(where + Vector2(110.0, 4.0), Vector2(190.0, 14.0))
	draw_rect(bar, SCREEN_GREEN * Color(1, 1, 1, 0.5), false, 1.0)
	var middle := bar.position.x + bar.size.x * 0.5
	draw_line(Vector2(middle, bar.position.y), Vector2(middle, bar.end.y), SCREEN_GREEN, 1.0)
	var width := bar.size.x * 0.5 * clampf(absf(thrust), 0.0, 1.0)
	var left := middle if thrust >= 0.0 else middle - width
	draw_rect(Rect2(Vector2(left, bar.position.y), Vector2(width, bar.size.y)), SCREEN_GREEN)


func _bar(where: Vector2, label: String, amount: float) -> void:
	PixelFont.draw(self, where + Vector2(0.0, 4.0), label, 2.0, SCREEN_GREEN, 0.0, Color(0, 0, 0, 0))
	var bar := Rect2(where + Vector2(110.0, 4.0), Vector2(190.0, 14.0))
	draw_rect(bar, SCREEN_GREEN * Color(1, 1, 1, 0.5), false, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(amount, 0.0, 1.0), bar.size.y)), SCREEN_GREEN)
