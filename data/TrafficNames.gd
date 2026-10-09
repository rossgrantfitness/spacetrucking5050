class_name TrafficNames
extends Resource
## The mundane, funny names on passing ships' ID labels ("NAVY LEISURE
## BARGE"). Open res://data/traffic_names.tres and add as many as you like:
## every traffic ship without a name of its own picks one from this list.


@export var names: PackedStringArray = PackedStringArray()


## A name for the ship called `node_name`. The same ship always gets the
## same name.
func pick_for(node_name: String) -> String:
	if names.is_empty():
		return "UNKNOWN VESSEL"
	return names[absi(node_name.hash()) % names.size()]
