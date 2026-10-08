class_name TrafficShip
extends Node3D
## Another trucker going about their day: flies a lazy loop forever, leaning
## into its turns, with engine trails. Pure scenery (plus a hull you can bonk).
##
## HOW TO SET ONE UP: add a TrafficShip node to the world, pick a model for
## `visual_scene`, and list the spots it flies through in `waypoints` (in the
## world's coordinates, in order; after the last one it heads back to the
## first). The path between spots is smoothed into gentle curves.


## The ship's model (any scene, like the ones in res://scenes/flight/traffic/).
@export var visual_scene: PackedScene
## The spots the ship flies through, in order, looping forever.
@export var waypoints := PackedVector3Array()
## Cruising speed, in meters per second (the starter rig tops out at 55).
@export_range(5.0, 200.0, 1.0, "suffix:m/s") var speed: float = 45.0
## Where along its loop the ship starts (0 = at the first waypoint,
## 0.5 = halfway around), so ships sharing a loop don't bunch up.
@export_range(0.0, 1.0, 0.01) var start_fraction: float = 0.0
## How far it leans into its tightest turns.
@export_range(0.0, 60.0, 1.0, "suffix:°") var max_bank_degrees: float = 30.0
## The color of its engine trails.
@export var engine_trail_color := Color(0.5, 0.9, 1.0)
## A rough size of its hull, for bonking into it: width, height, length.
@export var hull_size := Vector3(12.0, 7.0, 32.0)
## The name on its HUD ID label. Leave empty to pick a funny one from
## res://data/traffic_names.tres.
@export var id_label: String = ""

const NAMES: TrafficNames = preload("res://data/traffic_names.tres")

var _route := Curve3D.new()
var _distance := 0.0
var _visual: Node3D
var _bank := 0.0
var _last_heading := Vector3.FORWARD


func _ready() -> void:
	add_to_group("traffic")  # So the radars and ID labels can find us.
	if id_label.is_empty():
		id_label = NAMES.pick_for(name)
	_route = build_route(waypoints)
	_distance = _route.get_baked_length() * start_fraction
	if visual_scene != null:
		_visual = visual_scene.instantiate() as Node3D
		add_child(_visual)
		hull_size = hull_for(_visual, hull_size)
	_add_hull()
	_place(0.0)
	reset_physics_interpolation()  # Don't smooth from the scene's origin.


func _physics_process(delta: float) -> void:
	_place(delta)


## Cruising at its normal speed (for engine trails).
func speed_ratio() -> float:
	return 1.0


## The color of its engine trails (used by EngineTrail).
func trail_color() -> Color:
	return engine_trail_color


## The bump-box size for a ship model: the size it was built with (the
## developer's models remember theirs; see tools/build_traffic_models.gd),
## or `fallback` for the hand-built ones.
static func hull_for(visual: Node, fallback: Vector3) -> Vector3:
	return visual.get_meta("hull_size", fallback) if visual != null else fallback


## Turns a list of spots into a smooth closed loop: each spot gets curve
## handles pointing along the line from the spot before it to the spot after.
static func build_route(spots: PackedVector3Array) -> Curve3D:
	var route := Curve3D.new()
	route.bake_interval = 4.0
	var count := spots.size()
	if count < 2:
		return route
	for i in count + 1:  # The first spot again at the end closes the loop.
		var here := spots[i % count]
		var along := (spots[(i + 1) % count] - spots[posmod(i - 1, count)]) * 0.2
		route.add_point(here, -along, along)
	return route


## Moves along the loop by this frame's distance, faces the way it's going,
## and leans into the turn.
func _place(delta: float) -> void:
	var length := _route.get_baked_length()
	if length <= 0.0:
		return
	_distance = fposmod(_distance + speed * delta, length)
	var here := _route.sample_baked(_distance, true)
	var ahead := _route.sample_baked(fposmod(_distance + 8.0, length), true)
	var heading := (ahead - here).normalized()
	if heading.is_zero_approx():
		return
	# How hard we're turning left or right, from how the heading changed.
	if delta > 0.0:
		var turn := _last_heading.cross(heading).y / delta
		var goal := clampf(turn * 10.0, -1.0, 1.0) * deg_to_rad(max_bank_degrees)
		_bank = lerpf(_bank, goal, 1.0 - exp(-2.0 * delta))
	_last_heading = heading
	global_transform = Transform3D(Basis.looking_at(heading, Vector3.UP), here)
	if _visual != null:
		_visual.rotation.z = _bank


## An invisible box that moves with the ship, so you can't fly through it.
func _add_hull() -> void:
	var body := AnimatableBody3D.new()
	body.name = "Hull"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = hull_size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
