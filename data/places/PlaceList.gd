class_name PlaceList
extends Resource
## Every place in the game. Add a place by making a PlaceData .tres file and
## adding it to the list in res://data/places/places.tres.


@export var places: Array[PlaceData] = []


## The place with this id, or null.
func find(id: String) -> PlaceData:
	for place in places:
		if place != null and place.id == id:
			return place
	return null
