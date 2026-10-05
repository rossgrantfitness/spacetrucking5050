class_name BaseStation
extends Node3D
## The delivery company's HQ seen from space: a huge old starship where
## about 250 animals work. (It used to be her home base; now home is the
## inside of her rig, and the HQ is scenery until the day she can buy the
## company.) Its look is built by tools/build_world.gd; this script just
## writes its name (base_name in res://data/world_names.tres) on its side
## and turns the habitat ring slowly.


## How fast the habitat ring turns, in radians per second.
@export var ring_spin: float = 0.02

@onready var _ring: Node3D = get_node_or_null("HabitatRing")


func _ready() -> void:
	for sign_name: String in ["NameSign", "NameSignSide"]:
		var label := get_node_or_null(sign_name) as Label3D
		if label != null:
			label.text = GameState.names.base_name


func _process(delta: float) -> void:
	if _ring != null:
		_ring.rotate_object_local(Vector3.FORWARD, ring_spin * delta)
