class_name CrewRoster
extends Resource
## Everyone aboard the rig, and the things that can happen aboard
## (res://data/crew/crew.tres).


@export var crew: Array[CrewMember] = []
@export var events: Array[ShipEvent] = []


func find(id: String) -> CrewMember:
	for member in crew:
		if member != null and member.id == id:
			return member
	return null
