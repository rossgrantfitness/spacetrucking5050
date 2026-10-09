class_name BaseStation
extends Node3D
## The delivery company's HQ seen from space: a huge old starship where
## about 250 animals work. (It used to be her home base; now home is the
## inside of her rig, and the HQ is scenery until the day she can buy the
## company.) Its look is built by tools/build_world.gd; this script turns
## the habitat ring slowly. Its name isn't painted on it: the HUD's green ID
## label shows it (base_name in res://data/world_names.tres) as you pass.


## How fast the habitat ring turns, in radians per second.
@export var ring_spin: float = 0.02

@onready var _ring: Node3D = get_node_or_null("HabitatRing")


func _ready() -> void:
	add_to_group("named_places")  # The HUD labels these (FlightHUD._gather_contacts).
	set_meta("label", GameState.names.base_name.to_upper())


func _process(delta: float) -> void:
	if _ring != null:
		_ring.rotate_object_local(Vector3.FORWARD, ring_spin * delta)
