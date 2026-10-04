class_name EventData
extends Resource
## One kind of thing you might pass on the road, for the random sights
## along a long haul (see scenes/flight/RouteEvents.gd). Every kind lives in
## res://data/events/route_events.tres; change how often each shows up, in
## which solar systems, how far off the lane, and what people say about it.
## (How each one looks is built in code, in res://scenes/flight/events/.)


enum Kind { BIG_SHIP, CONVOY, WHALES, JELLYFISH, BILLBOARD, COMET, JUNK, DERELICT, DUCK, ION_STORM }

## What it is.
@export var kind: Kind = Kind.BILLBOARD
## Which logbook entry it is (see res://data/logbook/sights.tres).
@export var log_id: String = ""
## Rare: never picked like the others. Instead, every time a sight comes
## up there's a small chance (tuning.tres, "Route events") it's a rare one.
@export var rare: bool = false
## How big it is compared to normal (6 = a whale pod six times the size).
@export_range(0.1, 20.0, 0.1) var size: float = 1.0
## How many of it appear at once, spread out (a comet storm).
@export_range(1, 20, 1) var copies: int = 1
## A ghost: see-through and flickering.
@export var ghost: bool = false
## How likely it is compared to the others (2 = twice as likely as 1).
@export_range(0.0, 20.0, 0.1) var weight: float = 1.0
## Only in these solar systems (system ids like "home", "tidewater").
## Empty = anywhere.
@export var systems: PackedStringArray = PackedStringArray()
## How far ahead of you it appears, in meters.
@export_range(500.0, 15000.0, 100.0) var ahead: float = 4500.0
## How far off to the side of your lane (a random distance between these).
@export var side_offset := Vector2(400.0, 1200.0)
## How far up or down (a random distance between these).
@export var height_offset := Vector2(-250.0, 250.0)
## Words it uses: billboard ads as "HEADLINE|TAGLINE", or derelict names.
@export var texts: PackedStringArray = PackedStringArray()
## Who might comment on it over the comms when it shows up, and what they
## might say (one is picked at random). Optional.
@export var speaker: NPCData
@export var lines: PackedStringArray = PackedStringArray()


## Whether it can show up in the solar system `system_id`.
func allowed_in(system_id: String) -> bool:
	return systems.is_empty() or system_id in systems
