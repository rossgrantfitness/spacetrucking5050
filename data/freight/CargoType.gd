class_name CargoType
extends Resource
## One kind of everyday freight for the FREIGHT MARKET (see FreightMarket.gd):
## the loads that fill the job boards around the hand-written story jobs.
## Each posting picks a name, a client and a weight from here, and a
## from / to pair of places, and works out the pay.
##
## Add a new kind of freight by adding one to the list in
## res://data/freight/freight_market.tres (no code needed).


## A short code name.
@export var id: String = "general"
## What the load might be called (one is picked per posting).
@export var names: PackedStringArray = PackedStringArray(["Assorted crates"])
## Who might be shipping it (one is picked per posting).
@export var clients: PackedStringArray = PackedStringArray(["Some Company"])
## A line for the job board (one is picked; may be empty).
@export var blurbs: PackedStringArray = PackedStringArray()

## What it looks like slung under the rig (see CargoPod.gd):
##   container  steel shipping containers, more of them the heavier it is
##   reefer     white refrigerated containers with a chiller unit
##   tank       round tanks (liquids, gas, goo)
##   crates     a stack of wooden crates under a cargo net
##   livestock  a vented pod with little windows (somebody's in there)
##   machinery  odd lumpy shapes under a tarp, strapped to a flatbed
@export_enum("container", "reefer", "tank", "crates", "livestock", "machinery") var look: String = "container"
## The paint on the load (containers, tanks, the tarp).
@export var color: Color = Color(0.85, 0.35, 0.2)

## How heavy a load can be, in tons (from, to).
@export var weight_range: Vector2 = Vector2(3e8, 1.5e9)
## Pays this much compared with ordinary freight (1.2 = 20% more).
@export_range(0.3, 3.0, 0.05) var pay_factor: float = 1.0
## Careful cargo: none, fragile, perishable or live (a care bonus, like
## hand-written jobs).
@export_enum("none", "fragile", "perishable", "live") var care_kind: String = "none"
## How likely a posting is to be a rush job (0 to 1).
@export_range(0.0, 1.0, 0.05) var rush_chance: float = 0.2

@export_group("Where")
## Only shipped FROM these places (place ids; empty = anywhere).
@export var sources: PackedStringArray = PackedStringArray()
## Only shipped TO these places (place ids; empty = anywhere).
@export var destinations: PackedStringArray = PackedStringArray()
## Only on the market once this story flag is set (empty = always).
@export var requires_flag: String = ""


func ships_from(place_id: String) -> bool:
	return sources.is_empty() or place_id in sources


func ships_to(place_id: String) -> bool:
	return destinations.is_empty() or place_id in destinations
