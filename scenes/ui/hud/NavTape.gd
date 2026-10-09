class_name NavTape
extends HudWidget
## Top middle: a sliding compass strip, like a jet's heading tape. The tick
## marks slide as you turn; a yellow diamond shows which way your
## destination is (pinned to an edge as an arrow when it's off the strip),
## with the distance on the right. Under it, the ETA counts down: how long
## until you get there at the speed you're closing in.


const WIDTH: float = 120.0
const HEIGHT: float = 11.0
## How many degrees the strip shows from edge to edge.
const SPAN: float = 90.0

var _distance_text: String = ""
var _eta_text: String = ""


func hud_step(_delta: float, numbers_due: bool) -> void:
	var rig := ship()
	if not numbers_due or rig == null or hud.destination == null:
		return
	var to_target := hud.destination.global_position - rig.global_position
	var meters := to_target.length()
	_distance_text = distance_text(meters)
	if not rig.autopilot_route.is_empty():
		_eta_text = "DOCKING"
	else:
		var closing := rig.flight.velocity.dot(to_target.normalized())
		_eta_text = "ETA " + (clock(meters / closing) if closing > 1.0 else "--:--")


## Compass heading of a direction in degrees, 0 to 360, clockwise seen from
## above, where 0 ("N") is the way the rig faced at the start (-Z).
static func compass(direction: Vector3) -> float:
	return fposmod(rad_to_deg(atan2(direction.x, -direction.z)), 360.0)


## The shortest turn from heading `from` to heading `to`, -180 to 180.
static func turn_between(from: float, to: float) -> float:
	return wrapf(to - from, -180.0, 180.0)


func _draw() -> void:
	var rig := ship()
	if rig == null:
		return
	var center_x := floorf(size.x * 0.5)
	var area := Rect2(center_x - WIDTH * 0.5, MARGIN, WIDTH, HEIGHT)
	panel(area)
	var heading := compass(rig.flight.nose())
	var per_degree := WIDTH / SPAN
	# Tick marks every 5 degrees; labels every 30.
	var first := int(floorf((heading - SPAN * 0.5) / 5.0)) * 5
	for degree in range(first, int(heading + SPAN * 0.5) + 5, 5):
		var x := center_x + roundf(turn_between(heading, degree) * per_degree)
		if x <= area.position.x + 1.0 or x >= area.end.x - 1.0:
			continue
		var whole := posmod(degree, 360)
		var tall := 3.0 if whole % 30 == 0 else (2.0 if whole % 15 == 0 else 1.0)
		box(Rect2(x, area.position.y + 1.0, 1.0, tall), tint(0.8))
		if whole % 30 == 0:
			var label: String = {0: "N", 90: "E", 180: "S", 270: "W"}.get(whole, str(whole))
			var label_x := x - floorf(text_width(label) * 0.5)
			if label_x > area.position.x + 1.0 and label_x + text_width(label) < area.end.x - 1.0:
				text(Vector2(label_x, area.position.y + 5.0), label, GREEN if label.length() == 1 else Color(GREEN, 0.7))
	# Our heading: a notch under the middle.
	pixels(Vector2(center_x - 2.0, area.end.y + 1.0), ["..#..", ".###."], tint())
	if hud.destination == null:
		return
	# The destination's diamond.
	var bearing := compass(hud.destination.global_position - rig.global_position)
	var off := turn_between(heading, bearing) * per_degree
	var diamond := [".#.", "###", ".#."]
	if absf(off) > WIDTH * 0.5 - 4.0:
		var side := signf(off)
		diamond = ["#..", "##.", "#.."] if side > 0.0 else ["..#", ".##", "..#"]
		off = side * (WIDTH * 0.5 - 4.0)
	pixels(Vector2(center_x + roundf(off) - 1.0, area.position.y - 2.0), diamond, YELLOW)
	text(Vector2(area.end.x + 4.0, area.position.y + 3.0), _distance_text, GREEN)
	text_right(Vector2(area.position.x - 4.0, area.position.y + 3.0), hud.destination_name, tint(0.85))
	text_centered(Vector2(center_x, area.end.y + 5.0), _eta_text, tint(0.9))
