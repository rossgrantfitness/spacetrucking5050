class_name ShipList
extends Resource
## Every rig in the game, in the dealer's order (the starter rig first).
## Add one by making a ShipData .tres file and adding it to
## res://data/ships/ships.tres.


@export var ships: Array[ShipData] = []


func find(id: String) -> ShipData:
	for ship in ships:
		if ship != null and ship.id == id:
			return ship
	return null
