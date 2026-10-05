class_name CrewActivity
extends Resource
## One thing a crew member can be up to aboard the rig: where they are (a
## room and a spot in it), how they look doing it (a pose and maybe a prop)
## and what they say about it when you talk to them. Every new trip and
## every new day, each crew member picks one of their activities (see
## scenes/hub/ShipLife.gd), so the rig always feels a little different.
##
## Ship events (ShipEvent.gd) use these too, to put people somewhere special.


## When this can happen.
enum Situation {
	ANY,  ## Any time.
	IN_FLIGHT,  ## While the autopilot's driving.
	PARKED,  ## While the rig's docked somewhere.
	NIGHT,  ## The night shift (9 p.m. to 6 a.m. on your clock, for now).
	DAY,  ## Not the night shift.
	HAS_JOB,  ## There's a load in the back.
	NO_JOB,  ## The back's empty.
	JUST_PAID,  ## A delivery got paid today.
}

## A short code name (unique for this crew member).
@export var id: String = "idle"
## Which crew member (only used by ship events; a crew member's own
## activities are theirs).
@export var crew: String = ""
## The room it happens in.
@export_file("*.tscn") var room: String = "res://scenes/hub/Dispatch.tscn"
## The spot in that room: a Marker3D under the room's "CrewSpots" node.
@export var spot: String = ""
## How they stand (or sit, or sleep...). See BunnyAnimator.gd's poses.
@export_enum("stand", "sit", "sleep", "work", "eat", "read", "dance", "wave", "lean") var pose: String = "stand"
## Something in their hand: "mug", "wrench", "book", "cards", "broom",
## "clipboard", "plate", "guitar" or nothing.
@export var prop: String = ""
## What they say about it, first thing when you talk to them. Lines can use
## {bunny}, {husband}, {company}, {cargo} and {place}.
@export var lines: PackedStringArray = PackedStringArray()
@export var situation: Situation = Situation.ANY
## How likely it is compared with their other activities (2 = twice as likely).
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
## Only once this story flag is set (empty = always).
@export var needs_flag: String = ""
