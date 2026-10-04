class_name FlightChatter
extends Resource
## All the comm chatter you can hear while flying. Add lines by editing the
## sets in res://data/dialogue/flight_chatter.tres, or add a whole new set
## (a new person, or a new situation for someone).


@export var sets: Array[ChatterSet] = []


## Every [speaker, line] pair for a situation.
func lines_for(situation: ChatterSet.Situation) -> Array:
	var found := []
	for chatter_set in sets:
		if chatter_set != null and chatter_set.situation == situation and chatter_set.speaker != null:
			for line in chatter_set.lines:
				found.append([chatter_set.speaker, line])
	return found
