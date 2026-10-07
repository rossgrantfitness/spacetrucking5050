class_name TripLog
extends Resource
## One entry from the Thumper's old trip computer: a note {husband} typed
## in on the road, years ago. The computer is ancient and recovers them one
## at a time (one more each delivery); they're read on her PC, under OLD
## LOGS (see scenes/ui/pc/DesktopPC.gd). The list is
## res://data/pc/trip_logs.tres, oldest first.


## A short code name, used to remember it's been read. Keep it unique.
@export var id: String = "log"
## When he wrote it, as the trip computer counts ("DAY 12").
@export var day: String = "DAY 1"
## What he wrote. Can use {bunny}, {husband}, {company}...
@export_multiline var body: String = ""
## Recovered once she's made this many deliveries.
@export_range(0, 1000) var min_deliveries: int = 0
## ...and only once this story flag is set (empty = no flag needed).
@export var requires_flag: String = ""


func recovered() -> bool:
	return GameState.deliveries >= min_deliveries and (requires_flag.is_empty() or GameState.has_flag(requires_flag))
