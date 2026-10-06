class_name ModelVisual
extends Node3D
## The look of someone (or something) made from a single imported model
## (a .glb from res://art/models/, like the boss): no moving parts, so it
## just breathes and sways a little to look alive. The model itself is the
## "Model" child: move, turn or scale that one in the editor to line it up
## (feet on the floor at this node's origin, facing -Z).


## How much it rises and falls with each breath (0.01 = 1%).
@export var breath: float = 0.012
## Seconds per breath.
@export var breath_seconds: float = 3.4
## How far it sways side to side, in degrees.
@export var sway_degrees: float = 1.5

var _time := randf() * 10.0

@onready var _model: Node3D = get_node_or_null("Model")
@onready var _rest: Transform3D = _model.transform if _model != null else Transform3D.IDENTITY


## Called every frame by NPC.gd (and anything else that wants it alive).
func animate(delta: float, _walking: float) -> void:
	if _model == null:
		return
	_time += delta
	var breathe := sin(_time * TAU / breath_seconds)
	var sway := deg_to_rad(sway_degrees) * sin(_time * TAU / (breath_seconds * 2.3))
	_model.transform = Transform3D(Basis(Vector3.FORWARD, sway).scaled(Vector3(1.0, 1.0 + breath * breathe, 1.0)), Vector3.ZERO) * _rest
