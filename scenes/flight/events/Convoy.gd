class_name Convoy
extends RoadsideThing
## A line of oncoming truckers in the other lane, each with its engine
## trails and a funny ID label. Close passing traffic sells your speed.


const VISUALS := [preload("res://scenes/flight/traffic/CapsuleHaulerVisual.tscn"), preload("res://scenes/flight/traffic/BoxHaulerVisual.tscn")]
const NAMES: TrafficNames = preload("res://data/traffic_names.tres")
const TRAIL_COLORS := [Color(1.0, 0.75, 0.35), Color(0.6, 1.0, 0.5), Color(1.0, 0.45, 0.8), Color(0.45, 0.85, 1.0)]

## How fast the convoy drives, in m/s.
@export var convoy_speed: float = 60.0
## Names to pick their ID labels from (empty = the usual funny ones).
var names := PackedStringArray()
## One engine-trail color for all of them (fully transparent = a mix).
var trail_tint := Color(0.0, 0.0, 0.0, 0.0)

var _velocity := Vector3.ZERO
var _travelled: float = 0.0


func _ready() -> void:
	# Oncoming: they drive back the way you came, a little off to the side.
	_velocity = -travel * convoy_speed
	var count := rng.randi_range(3, 5)
	for i in count:
		var rig := ConvoyRig.new()
		rig.trail = trail_tint if trail_tint.a > 0.0 else TRAIL_COLORS[i % TRAIL_COLORS.size()]
		rig.position = Vector3(0.0, 0.0, i * 90.0)  # Strung out in a line behind the leader.
		var label: String = NAMES.names[rng.randi_range(0, NAMES.names.size() - 1)]
		if not names.is_empty():
			label = names[i % names.size()]
		rig.show_on_radar(label, 20.0)
		rig.add_child((VISUALS[rng.randi_range(0, VISUALS.size() - 1)] as PackedScene).instantiate())
		EventKit.solid(rig, Vector3(12.0, 8.0, 30.0))
		add_child(rig)
	look_at(global_position + _velocity, Vector3.UP)


func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_travelled += convoy_speed * delta


func is_done() -> bool:
	return _travelled > 9000.0


## One rig in the convoy (it reports its speed and color to its engine
## trails, like a TrafficShip).
class ConvoyRig:
	extends RoadsideThing
	var trail := Color.WHITE

	func trail_color() -> Color:
		return trail
