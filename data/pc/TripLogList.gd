class_name TripLogList
extends Resource
## Every entry on the Thumper's old trip computer (see TripLog.gd), oldest
## first.


@export var logs: Array[TripLog] = []


## The entries recovered so far, oldest first.
func recovered() -> Array[TripLog]:
	var found: Array[TripLog] = []
	for log_entry in logs:
		if log_entry != null and log_entry.recovered():
			found.append(log_entry)
	return found
