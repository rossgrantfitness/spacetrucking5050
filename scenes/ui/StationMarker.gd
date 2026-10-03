class_name StationMarker
extends Control
## A little diamond over a destination (the truck stop, for now) with its name
## and distance, so you can always find it. When it's off-screen or behind
## you, an arrow at the edge of the screen points the way.


const MARKER_COLOR := Color(0.45, 0.95, 1.0)
## Keep the off-screen arrow this far in from the screen edges.
const EDGE_MARGIN: float = 56.0

## The thing to point at, and what to call it, and the 3D view it's seen
## through. Set by FlightHUD.
var target: Node3D
var view: PSXView
var label := "TRUCK STOP"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if target == null or view == null or view.camera() == null:
		return
	var camera := view.camera()
	var spot := target.global_position
	var text := "%s  %.1f km" % [label, camera.global_position.distance_to(spot) / 1000.0]
	var on_screen := view.unproject(spot)
	var area := Rect2(Vector2.ONE * EDGE_MARGIN, size - Vector2.ONE * EDGE_MARGIN * 2.0)

	if not camera.is_position_behind(spot) and area.has_point(on_screen):
		_diamond(on_screen)
		_text(on_screen + Vector2(16.0, 5.0), text)
		return

	# Off-screen: find the direction to it from the middle of the screen
	# (flipped if it's behind us), and put an arrow on the edge that way.
	var direction := on_screen - area.get_center()
	if camera.is_position_behind(spot):
		direction = -direction
	if direction.length() < 0.001:
		direction = Vector2.DOWN
	direction = direction.normalized()
	var half := area.size * 0.5
	var to_edge := minf(
			half.x / absf(direction.x) if absf(direction.x) > 0.0001 else INF,
			half.y / absf(direction.y) if absf(direction.y) > 0.0001 else INF)
	var edge := area.get_center() + direction * to_edge
	_arrow(edge, direction)
	_text(edge - direction * 30.0 + Vector2(-60.0, 5.0), text)


func _diamond(where: Vector2) -> void:
	var points := PackedVector2Array([
		where + Vector2(0, -10), where + Vector2(10, 0), where + Vector2(0, 10), where + Vector2(-10, 0), where + Vector2(0, -10)])
	draw_polyline(points, MARKER_COLOR, 2.0, true)


func _arrow(tip: Vector2, direction: Vector2) -> void:
	var side := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		tip + direction * 12.0, tip - direction * 8.0 + side * 9.0, tip - direction * 8.0 - side * 9.0]), MARKER_COLOR)


func _text(where: Vector2, text: String) -> void:
	var font := get_theme_default_font()
	draw_string_outline(font, where, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0, 0, 0, 0.6))
	draw_string(font, where, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, MARKER_COLOR)
