class_name WorldMarkers
extends HudWidget
## Markers stuck to things out in space:
## - WAYPOINT: a small yellow diamond on your destination while it's far
##   away (a chevron at the screen edge when it's off screen).
## - DOCKING BRACKETS: near the destination, four brackets pop in around the
##   docking bay and close in as you approach. Green when you're lined up
##   and heading in, yellow when you're not.
## - SHIP ID LABEL: the nearest passing ship gets little brackets and its
##   funny name ("NAVY LEISURE BARGE"), from res://data/traffic_names.tres.


## How big the docking bay's opening is, in meters (its radius).
const BAY_RADIUS: float = 56.0
## Keep off-screen chevrons this far in from the edges.
const EDGE: float = 14.0

var _dock_pop := HudWidget.Pop.new()
var _label_pop := HudWidget.Pop.new()
var _target: Dictionary = {}
var _target_name: String = ""
var _dock_meters_text: String = ""
var _target_meters_text: String = ""


func hud_step(delta: float, numbers_due: bool) -> void:
	var rig := ship()
	if rig == null:
		return
	var tuning := GameState.tuning
	var to_dock := INF
	if hud.destination != null:
		to_dock = rig.global_position.distance_to(hud.destination.global_position)
	_dock_pop.want = to_dock < tuning.docking_bracket_range
	_dock_pop.update(delta)
	# The nearest ship gets an ID label. A new ship pops a fresh label in.
	var nearest := {}
	var nearest_meters := tuning.target_label_range
	for contact in hud.contacts:
		if contact["kind"] == FlightHUD.Kind.SHIP:
			var meters := rig.global_position.distance_to(contact["position"])
			if meters < nearest_meters and not hud.is_behind(contact["position"]):
				nearest = contact
				nearest_meters = meters
	var name_now: String = nearest.get("label", "")
	if name_now != _target_name:
		_target_name = name_now
		_label_pop.step = 0
	_target = nearest
	_label_pop.want = not nearest.is_empty()
	_label_pop.update(delta)
	if numbers_due:
		_dock_meters_text = distance_text(to_dock)
		_target_meters_text = distance_text(nearest_meters)


func _draw() -> void:
	var rig := ship()
	if rig == null:
		return
	if hud.destination != null:
		if _dock_pop.shown():
			_draw_docking(rig)
		else:
			_draw_waypoint()
	if _label_pop.shown() and not _target.is_empty():
		_draw_label(_target)


func _draw_waypoint() -> void:
	var spot := hud.destination.global_position
	var screen := hud.to_hud(spot)
	var area := Rect2(Vector2.ONE * EDGE, size - Vector2.ONE * EDGE * 2.0)
	if not hud.is_behind(spot) and area.has_point(screen):
		pixels(screen.round() - Vector2(2, 2), ["..#..", ".#.#.", "#...#", ".#.#.", "..#.."], YELLOW)
		return
	# Off screen: a chevron on the edge, pointing the way.
	var direction := screen - area.get_center()
	if hud.is_behind(spot):
		direction = -direction
	if direction.length() < 0.001:
		direction = Vector2.DOWN
	direction = direction.normalized()
	var half := area.size * 0.5
	var to_edge := minf(
			half.x / absf(direction.x) if absf(direction.x) > 0.0001 else INF,
			half.y / absf(direction.y) if absf(direction.y) > 0.0001 else INF)
	var edge := (area.get_center() + direction * to_edge).round()
	var side := direction.orthogonal()
	if blink(1.0):
		draw_colored_polygon(PackedVector2Array([
			(edge + direction * 4.0).round(), (edge - direction * 2.0 + side * 3.0).round(),
			(edge - direction * 2.0 - side * 3.0).round()]), YELLOW)


func _draw_docking(rig: Ship) -> void:
	var bay := hud.destination.global_position
	if hud.is_behind(bay):
		return
	var center := hud.to_hud(bay).round()
	# How big the bay looks: project a point on its rim.
	var rim := hud.to_hud(bay + _camera_right() * BAY_RADIUS)
	var half := maxf(center.distance_to(rim), 6.0)
	# While popping in, the brackets start wide and close in, step by step.
	half += _dock_pop.hidden_share() * 24.0
	half = roundf(minf(half, size.y * 0.4))
	var heading_in := rig.flight.speed() > 2.0 and rig.flight.velocity.normalized().dot((bay - rig.global_position).normalized()) > cos(deg_to_rad(12.0))
	var color := GREEN if heading_in else YELLOW
	var arm := 5.0
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var tip := center + corner * half
		box(Rect2(tip.x - (arm if corner.x > 0.0 else 0.0), tip.y, arm, 1.0), color)
		box(Rect2(tip.x, tip.y - (arm if corner.y > 0.0 else 0.0), 1.0, arm), color)
	box(Rect2(center, Vector2.ONE), color)
	text_centered(center + Vector2(0, -half - 8.0), "DOCK " + _dock_meters_text, color)


func _draw_label(contact: Dictionary) -> void:
	var where: Vector3 = contact["position"]
	var center := hud.to_hud(where).round()
	var rim := hud.to_hud(where + _camera_right() * float(contact["radius"]))
	var half := roundf(clampf(center.distance_to(rim), 4.0, 40.0)) + roundf(_label_pop.hidden_share() * 10.0)
	var color := tint(0.9)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var tip := center + corner * half
		box(Rect2(tip.x - (2.0 if corner.x > 0.0 else 0.0), tip.y, 3.0, 1.0), color)
		box(Rect2(tip.x, tip.y - (2.0 if corner.y > 0.0 else 0.0), 1.0, 3.0), color)
	if _label_pop.hidden_share() > 0.0:
		return  # The name appears once the brackets have closed in.
	var label_spot := center + Vector2(half + 4.0, -half)
	var label_width := maxf(text_width(contact["label"]), text_width(_target_meters_text))
	if label_spot.x + label_width > size.x - MARGIN:
		label_spot.x = center.x - half - 4.0 - label_width  # Flip to the left.
	text(label_spot, contact["label"], GREEN)
	text(label_spot + Vector2(0, 7), _target_meters_text, tint(0.7))


## The camera's "right" direction, for measuring how big things look.
func _camera_right() -> Vector3:
	var camera := hud.get_viewport().get_camera_3d()
	return camera.global_basis.x if camera != null else Vector3.RIGHT
