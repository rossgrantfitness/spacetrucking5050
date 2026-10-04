class_name Logbook
extends Resource
## Every sight that can go in the logbook (see LogbookEntry.gd). Which ones
## you've seen (and how many times) is saved in GameState.logbook.


@export var entries: Array[LogbookEntry] = []


## The entry with this id, or null.
func find(id: String) -> LogbookEntry:
	for entry in entries:
		if entry != null and entry.id == id:
			return entry
	return null
