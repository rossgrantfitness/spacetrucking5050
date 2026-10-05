class_name SystemList
extends Resource
## Every solar system in the game. Add one by making a SystemData .tres file
## and adding it to the list in res://data/systems/systems.tres. (Its
## planets, stations and road go in the flight scene.)


@export var systems: Array[SystemData] = []


## The system with this id, or null.
func find(id: String) -> SystemData:
	for system in systems:
		if system != null and system.id == id:
			return system
	return null
