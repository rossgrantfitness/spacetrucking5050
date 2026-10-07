class_name RouteData
extends Resource
## A ROUTE CHOICE out on the road: something the course chart (M) offers
## as a different way to get somewhere. Three kinds:
##   toll      A toll turnpike: a lane of glowing gates with a current that
##             carries you along it, far faster than cruising, for a fee at
##             the gate. (Fast, but you pay, and you'll need to brake
##             afterwards.)
##   shortcut  A belt of rocks lying across the straight line between
##             places. The safe route goes round it; the shortcut goes
##             straight through. (Shorter, but bonks are likely.)
##   scenic    A lane past something beautiful. A bit longer; the view
##             calms Jacki down (steadier hands, like a snack) and it goes
##             in the logbook.
## Each gets its own entry in res://data/routes/routes.tres. The flight
## scene builds them (FlightSandbox.gd); the chart offers them when they're
## roughly on the way (CourseChart.gd).


## A short code name.
@export var id: String = "route"
## Its name on the chart and the signs.
@export var display_name: String = "Some Route"
@export_enum("toll", "shortcut", "scenic") var kind: String = "toll"
## A line about it for the chart.
@export_multiline var description: String = ""
## Where it runs, in the world (from one end to the other; either way works).
@export var start: Vector3 = Vector3.ZERO
@export var finish: Vector3 = Vector3(0, 0, -10000)
## How wide it is (m from the middle line).
@export var radius: float = 300.0

@export_group("Toll lanes")
## The toll at the gate (any direction).
@export_range(0, 10000, 5) var toll: int = 40
## The current carries you up to this speed along the lane (m/s)...
@export_range(0.0, 3000.0, 10.0) var current_speed: float = 400.0
## ...pushing this hard (m/s every second).
@export_range(0.0, 500.0, 1.0) var current_push: float = 30.0

@export_group("Shortcuts")
## The belt of rocks: how many, and how wide across it is (m).
@export var rock_count: int = 1400
@export var belt_width: float = 5000.0
@export var rock_colors := PackedColorArray()

@export_group("Scenic lanes")
## The logbook sight for driving it (an id in res://data/logbook/).
@export var sight_id: String = ""


## The lane's points from the end nearest `from` to the other.
func points_from(from: Vector3) -> PackedVector3Array:
	if from.distance_to(start) <= from.distance_to(finish):
		return PackedVector3Array([start, finish])
	return PackedVector3Array([finish, start])


func length() -> float:
	return start.distance_to(finish)


## How far `spot` is from the lane's middle line.
func distance_to(spot: Vector3) -> float:
	return spot.distance_to(Geometry3D.get_closest_point_to_segment(spot, start, finish))


## The belt's middle (shortcuts: the rocks sit around here).
func middle() -> Vector3:
	return (start + finish) * 0.5
