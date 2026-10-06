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
## What they're doing (set by CrewNPC from their activity): "dance" sways
## and bobs, "sleep" breathes slow with the head drooped; anything else
## just stands and breathes. (One-piece models can't move their limbs.)
var pose: String = "stand"
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
	var seconds := breath_seconds * (1.8 if pose == "sleep" else 1.0)
	var breathe := sin(_time * TAU / seconds)
	var sway := deg_to_rad(sway_degrees) * sin(_time * TAU / (seconds * 2.3))
	var lean := 0.0
	var hop := 0.0
	if pose == "dance":
		sway = deg_to_rad(9.0) * sin(_time * TAU * 1.1)
		hop = absf(sin(_time * TAU * 1.1)) * 0.06
	elif pose == "sleep":
		lean = deg_to_rad(8.0)  # Nodding off.
	var tilt := Basis(Vector3.FORWARD, sway) * Basis(Vector3.RIGHT, -lean)
	_model.transform = Transform3D(tilt.scaled(Vector3(1.0, 1.0 + breath * breathe, 1.0)), Vector3.UP * hop) * _rest
