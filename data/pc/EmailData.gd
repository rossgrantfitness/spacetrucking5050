class_name EmailData
extends Resource
## One email in her inbox, on the desktop PC in the apartment (see
## scenes/ui/pc/DesktopPC.gd). They live in res://data/pc/emails.tres.
## {bunny}, {husband}, {base} and {currency} are filled in with the names
## from res://data/world_names.tres.


## A short code name, used to remember it's been read. Keep it unique.
@export var id: String = "email"
## Who it's from, as shown in the inbox.
@export var from_name: String = "Somebody"
@export var subject: String = "Hello"
@export_multiline var body: String = ""
## Only arrives once this story flag is set (empty = it's there from the start).
@export var requires_flag: String = ""
