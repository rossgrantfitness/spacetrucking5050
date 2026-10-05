class_name PassingShip
extends RoadsideThing
## One ship on the road with a story in its ID label: a tortoise doing a
## crawl in the fast lane, a tow ship, a student driver weaving all over,
## an ambulance. It either comes the other way or drives your way slowly so
## you overtake it.


const VISUALS := [preload("res://scenes/flight/traffic/CapsuleHaulerVisual.tscn"),
	preload("res://scenes/flight/traffic/BoxHaulerVisual.tscn"), preload("res://scenes/flight/traffic/CourierVisual.tscn")]
const NAMES: TrafficNames = preload("res://data/traffic_names.tres")

## How fast it drives, in m/s.
@export var drive_speed: float = 50.0
## Names to pick its ID label from (empty = the usual funny ones).
var names := PackedStringArray()
## Its engine-trail color.
var trail := Color(1.0, 0.75, 0.35)
## Drives your way (you overtake it) instead of coming the other way.
var same_direction: bool = false
## Weaves all over the lane.
var weaving: bool = false

var _velocity := Vector3.ZERO
var _travelled: float = 0.0
var _time: float = 0.0
var _body: Node3D


func _ready() -> void:
	_velocity = (travel if same_direction else -travel) * drive_speed
	_body = Node3D.new()
	add_child(_body)
	_body.add_child((VISUALS[rng.randi_range(0, VISUALS.size() - 1)] as PackedScene).instantiate())
	EventKit.solid(_body, Vector3(12.0, 8.0, 30.0))
	var label: String = NAMES.names[rng.randi_range(0, NAMES.names.size() - 1)]
	if not names.is_empty():
		label = names[rng.randi_range(0, names.size() - 1)]
	show_on_radar(label, 20.0)
	look_at(global_position + _velocity, Vector3.UP)


func _physics_process(delta: float) -> void:
	_time += delta
	global_position += _velocity * delta
	_travelled += drive_speed * delta
	if weaving:
		# Side to side, leaning into each swerve.
		_body.position.x = sin(_time * 0.9) * 60.0
		_body.rotation.z = -cos(_time * 0.9) * 0.4


func is_done() -> bool:
	return _travelled > 12000.0


func speed_ratio() -> float:
	return clampf(drive_speed / 60.0, 0.2, 1.0)


func trail_color() -> Color:
	return trail
