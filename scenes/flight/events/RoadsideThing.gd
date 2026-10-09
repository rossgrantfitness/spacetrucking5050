class_name RoadsideThing
extends Node3D
## The base for everything you pass on the road: signs, landmarks, whales,
## big ships, convoys... Set pieces build themselves in code (with EventKit)
## when they're added to the world.
##
## Things that should show on the radar and get an ID label on the HUD set
## `id_label` (and join the "traffic" group, see show_on_radar()).


## Which logbook entry it is ("" = not in the logbook). See
## res://data/logbook/sights.tres.
@export var log_id: String = ""
## The name on its HUD ID label ("" = no label).
var id_label: String = ""
## Roughly how big it is (a radius, in meters), for the radar and labels.
var contact_radius: float = 50.0
## The player's rig, and which way it was going when this appeared (for
## things spawned on the road by RouteEvents). Null/zero for fixed landmarks.
var ship: Ship
var travel: Vector3 = Vector3.FORWARD
var rng := RandomNumberGenerator.new()


## Called by RouteEvents before adding it to the world.
func setup(new_ship: Ship, new_travel: Vector3, seed_number: int) -> void:
	ship = new_ship
	travel = new_travel
	rng.seed = seed_number


## Whether it's finished and can be removed (like a flyby that's passed).
func is_done() -> bool:
	return false


## Shows it on the radar and gives it an ID label.
func show_on_radar(label: String, radius: float) -> void:
	id_label = label
	contact_radius = radius
	add_to_group("traffic")


## For engine trails on things that move (see EngineTrail.gd).
func speed_ratio() -> float:
	return 1.0


func trail_color() -> Color:
	return Color(0.5, 0.9, 1.0)
