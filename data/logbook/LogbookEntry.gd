class_name LogbookEntry
extends Resource
## One sight for the logbook: something you can pass on the road (a whale
## pod, the world's biggest donut, a ghost ship...). The first time you get
## a good look at it, it goes in your logbook. Some are rare: brag about
## those. All of them are listed in res://data/logbook/sights.tres.


## A short code name. Things on the road say which entry they are with it
## (`log_id` on a sight in the flight scene, or on an event in
## res://data/events/route_events.tres).
@export var id: String = ""
## Its name in the logbook.
@export var display_name: String = ""
## What Jack wrote about it.
@export_multiline var description: String = ""
## Rare sights get a fanfare when you first see one.
@export var rare: bool = false
