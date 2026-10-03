class_name StationMarker
extends Control
## Sci-fi corner brackets around a destination (the truck stop, for now) with
## its name and distance in chunky pixel letters, so you can always find it.
## When it's off-screen or behind you, an arrow at the screen edge points the
## way.


const MARKER_COLOR := Color(0.45, 0.95, 1.0)
## Keep the off-screen arrow this far in from the screen edges.
const EDGE_MARGIN: float = 56.0

## The thing to point at, and what to call it. Set by FlightHUD.
var target: Node3D
var label := "TRUCK STOP"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if target == null or camera == null:
		return
	var spot := target.global_position
	var text := "%s  %.1f KM" % [label, camera.global_position.distance_to(spot) / 1000.0]
	var on_screen := camera.unproject_position(spot)
	var area := Rect2(Vector2.ONE * EDGE_MARGIN, size - Vector2.ONE * EDGE_MARGIN * 2.0)

	if not camera.is_position_behind(spot) and area.has_point(on_screen):
		_brackets(on_screen)
		_text(on_screen + Vector2(22.0, -7.0), text)
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
	_text(edge - direction * 34.0 + Vector2(-PixelFont.width(text, 2.0) * 0.5, -7.0), text)


## Four corner brackets around the spot, with a dot in the middle.
func _brackets(where: Vector2) -> void:
	var reach := 12.0
	var arm := 6.0
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var tip := where + corner * reach
		draw_polyline(PackedVector2Array([tip - Vector2(corner.x * arm, 0.0), tip, tip - Vector2(0.0, corner.y * arm)]), MARKER_COLOR, 2.0)
	draw_rect(Rect2(where - Vector2.ONE * 1.5, Vector2.ONE * 3.0), MARKER_COLOR)


func _arrow(tip: Vector2, direction: Vector2) -> void:
	var side := direction.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		tip + direction * 12.0, tip - direction * 8.0 + side * 9.0, tip - direction * 8.0 - side * 9.0]), MARKER_COLOR)


func _text(where: Vector2, text: String) -> void:
	PixelFont.draw(self, where, text, 2.0, MARKER_COLOR, 0.15)
