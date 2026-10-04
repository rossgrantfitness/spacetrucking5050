class_name CourseChart
extends Control
## The course chart: "maps for space". Press M (Back on a gamepad) in
## flight and pick where to go. Each choice shows how far it is, how long
## it takes cruising vs. on full boost, and how much fuel it'll drink, with
## the route drawn on a little map. Pick one and the cruise autopilot
## (CruisePilot.gd) drives you there and through the approach ring; grab
## the controls any time to take over.
##
## Routes "via" a drive-through (like the Gas-N-Go) are offered when it's
## roughly on the way.
##
## Use it with:
##     var pick := await CourseChart.open(tree, ship, places, approach, job_to, engaged)
## It returns {"action": "go", "stops": [place ids]}, {"action": "off"} or
## {"action": "cancel"}.


const MAP_SIZE := Vector2(440.0, 440.0)
const SYSTEMS: Array[SystemData] = [preload("res://data/systems/home_system.tres"), preload("res://data/systems/tidewater.tres")]

## Every route's points, in the world (starting at the rig), one per option.
var routes: Array[PackedVector3Array] = []
## Place id -> where it is.
var spots: Dictionary = {}
var ship_spot := Vector3.ZERO
var ship_facing := Vector3.FORWARD
var job_to: String = ""

var _shown: int = 0
var _font: Font


## Opens the chart and waits for the player's choice. `places` is place id
## -> its node in the flight scene; `approach(id, from)` returns the points
## the autopilot flies through to dock there coming from `from`.
static func open(tree: SceneTree, ship: Ship, places: Dictionary, approach: Callable, job_to_place: String, engaged: bool) -> Dictionary:
	var chart := CourseChart.new()
	chart.ship_spot = ship.global_position
	chart.ship_facing = ship.flight.nose()
	chart.job_to = job_to_place
	for id: String in places:
		chart.spots[id] = (places[id] as Node3D).global_position
	var options: Array = []
	var choices: Array[PackedStringArray] = []
	for stops in possible_courses(ship.global_position, chart.spots, job_to_place):
		var route := PackedVector3Array([ship.global_position])
		for id in stops:
			for point: Vector3 in approach.call(id, route[route.size() - 1]):
				route.append(point)
		var numbers := estimate(route, ship.ship_data, GameState.tuning, ship.flight.boost_fuel)
		var place: PlaceData = GameState.places.find(stops[stops.size() - 1])
		var text: String = place.display_name
		if stops.size() > 1:
			text += " VIA " + GameState.places.find(stops[0]).display_name
		if stops[stops.size() - 1] == job_to_place:
			text = "* " + text
		options.append({"text": text, "detail": "%d KM" % roundi(numbers["meters"] / 1000.0),
				"description": describe(numbers, ship.flight, stops[stops.size() - 1] == job_to_place)})
		choices.append(stops)
		chart.routes.append(route)
	if engaged:
		options.append({"text": "AUTOPILOT OFF", "description": "Take the wheel back. (Touching the stick, throttle or boost does that too.)"})
	options.append({"text": "NEVER MIND", "description": "Close the chart."})
	var paused_before := tree.paused
	tree.paused = true
	var choice := await MenuPanel.ask(tree, "CHART A COURSE", "Pick a destination. The autopilot cruises on the limiter (cheap on fuel) and steers around stuff.", options, chart)
	tree.paused = paused_before
	if choice >= 0 and choice < choices.size():
		return {"action": "go", "stops": choices[choice]}
	if engaged and choice == choices.size():
		return {"action": "off"}
	return {"action": "cancel"}


## Every course worth offering from `from`: straight to each place, and to
## each place via a drive-through that's roughly on the way. The job's
## destination comes first. `place_spots` is place id -> where it is.
static func possible_courses(from: Vector3, place_spots: Dictionary, job_to_place: String) -> Array[PackedStringArray]:
	var courses: Array[PackedStringArray] = []
	var ids: Array = place_spots.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		if (a == job_to_place) != (b == job_to_place):
			return a == job_to_place
		return from.distance_to(place_spots[a]) < from.distance_to(place_spots[b]))
	for id: String in ids:
		var there: Vector3 = place_spots[id]
		if from.distance_to(there) < 1500.0:
			continue  # You're right here.
		courses.append(PackedStringArray([id]))
		for stop: String in ids:
			var data := GameState.places.find(stop)
			if stop == id or data == null or data.kind != PlaceData.Kind.DRIVE_THROUGH:
				continue
			var middle: Vector3 = place_spots[stop]
			var detour := from.distance_to(middle) + middle.distance_to(there)
			if detour < from.distance_to(there) * 1.25 and from.distance_to(middle) > 1500.0:
				courses.append(PackedStringArray([stop, id]))
	return courses


## How far a route is, how long it takes (cruising, and boosting with the
## boost fuel you have) and how much of a full fuel tank cruising it uses.
static func estimate(route: PackedVector3Array, ship: ShipData, tuning: Tuning, boost_left: float) -> Dictionary:
	var meters := 0.0
	for i in range(1, route.size()):
		meters += route[i - 1].distance_to(route[i])
	var cruise_seconds := meters / ship.max_speed
	var boost_speed := FlightModel.boosted_top_speed(ship)
	var boost_seconds := meters / boost_speed
	var boost_needed := boost_seconds / ship.boost_fuel_seconds
	var boost_time := boost_left * ship.boost_fuel_seconds
	if boost_seconds > boost_time:
		# The boost runs dry partway; cruise the rest.
		boost_seconds = boost_time + (meters - boost_time * boost_speed) / ship.max_speed
	return {"meters": meters, "cruise_seconds": cruise_seconds, "boost_seconds": boost_seconds,
			"fuel": cruise_seconds * tuning.cruise_burn / ship.fuel_tank_seconds, "boost_needed": boost_needed}


## The words under a course: times, fuel, and a heads-up if you're short.
static func describe(numbers: Dictionary, flight: FlightModel, is_job: bool) -> String:
	var words := "Cruising: %s     Full boost: %s\n" % [HudWidget.clock(numbers["cruise_seconds"]), HudWidget.clock(numbers["boost_seconds"])]
	words += "Fuel: about %d%% of a tank (you have %d%%).  Boost all the way: %d%% (you have %d%%)." % [
			roundi(numbers["fuel"] * 100.0), roundi(flight.fuel * 100.0),
			roundi(numbers["boost_needed"] * 100.0), roundi(flight.boost_fuel * 100.0)]
	if numbers["fuel"] > flight.fuel:
		words += "\nNOT ENOUGH FUEL to cruise there. Fill up on the way."
	if is_job:
		words += "\nYour load goes here."
	return words


func _ready() -> void:
	custom_minimum_size = MAP_SIZE
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Highlights option number `index`'s route (MenuPanel calls this).
func show_option(index: int) -> void:
	_shown = index
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.02, 0.03, 0.1, 0.96))
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.85, 0.88, 1.0), false, 3.0)
	var bounds := _bounds()
	# A faint grid, every 10 km.
	var grid := Color(0.3, 0.35, 0.6, 0.25)
	var step := 10000.0
	var x := floorf(bounds.position.x / step) * step
	while x < bounds.end.x:
		draw_line(_to_map(Vector3(x, 0.0, bounds.position.y), bounds), _to_map(Vector3(x, 0.0, bounds.end.y), bounds), grid)
		x += step
	var z := floorf(bounds.position.y / step) * step
	while z < bounds.end.y:
		draw_line(_to_map(Vector3(bounds.position.x, 0.0, z), bounds), _to_map(Vector3(bounds.end.x, 0.0, z), bounds), grid)
		z += step
	# Each solar system: a soft glow in its color.
	for system in SYSTEMS:
		var middle := _to_map(system.center, bounds)
		for ring in 4:
			draw_circle(middle, 70.0 - ring * 15.0, Color(system.signature_color, 0.06))
		draw_string(_font, middle + Vector2(-60.0, -62.0), system.display_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, Color(system.signature_color, 0.8))
	# The routes: the highlighted one bright, the rest faint.
	for i in routes.size():
		if i != _shown:
			_draw_route(routes[i], bounds, Color(0.6, 0.7, 1.0, 0.25), 1.5)
	if _shown >= 0 and _shown < routes.size():
		_draw_route(routes[_shown], bounds, Color(1.0, 0.85, 0.25), 3.0)
	# The places.
	for id: String in spots:
		var place := GameState.places.find(id)
		var dot := _to_map(spots[id], bounds)
		var color := Color(1.0, 0.85, 0.25) if id == job_to else Color(0.6, 0.95, 1.0)
		draw_rect(Rect2(dot - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), color)
		var words: String = place.display_name if place != null else id
		var width := _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
		# Labels near the right edge go on the left of the dot, to stay on the map.
		var at := dot + Vector2(8.0, 4.0) if dot.x + 8.0 + width < MAP_SIZE.x - 6.0 else dot + Vector2(-8.0 - width, 4.0)
		draw_string(_font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, color)
	# The rig: a little arrow pointing the way the nose points.
	var here := _to_map(ship_spot, bounds)
	var facing := Vector2(ship_facing.x, ship_facing.z).normalized()
	if facing.is_zero_approx():
		facing = Vector2.UP
	var side := facing.orthogonal()
	draw_colored_polygon(PackedVector2Array([here + facing * 10.0, here - facing * 6.0 + side * 6.0, here - facing * 6.0 - side * 6.0]), Color(1.0, 0.55, 0.3))
	draw_string(_font, Vector2(12.0, MAP_SIZE.y - 14.0), "10 KM GRID", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.6, 0.65, 0.9))


func _draw_route(route: PackedVector3Array, bounds: Rect2, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for point in route:
		points.append(_to_map(point, bounds))
	if points.size() >= 2:
		draw_polyline(points, color, width)


## The part of the world the map shows (seen from above: x across, z down),
## square, with some room around the edges.
func _bounds() -> Rect2:
	var area := Rect2(Vector2(ship_spot.x, ship_spot.z), Vector2.ZERO)
	for id: String in spots:
		area = area.expand(Vector2(spots[id].x, spots[id].z))
	var side := maxf(area.size.x, area.size.y) * 1.25 + 4000.0
	return Rect2(area.get_center() - Vector2(side, side) * 0.5, Vector2(side, side))


func _to_map(world: Vector3, bounds: Rect2) -> Vector2:
	return (Vector2(world.x, world.z) - bounds.position) / bounds.size * MAP_SIZE
