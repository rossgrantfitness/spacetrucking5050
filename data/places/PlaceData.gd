class_name PlaceData
extends Resource
## A place you can fly to and dock at: the truck stop, stations in other
## systems, drive-throughs. Each gets its own .tres file in this folder, and
## res://data/places/places.tres lists them all.
##
## One special place isn't out in space: "base" is YOUR RIG. Home is the
## inside of the rig (the apartment, the hallway and the dispatch office
## behind the cab), so it has no station in the flight scene. Jobs "from
## base" are the ones dispatch hands you aboard: you pick them up wherever
## the rig happens to be.
##
## In the flight scene, each place is a station with a node named after its
## `id` under "Places" (with a DockPoint, an approach ring or two, and a
## LaunchPoint). What docking does depends on its `kind`.


enum Kind {
	INTERIOR,  ## Dock and climb out: walk around inside (`interior_scene`).
	DROP_OFF,  ## Dock, drop the cargo, get paid, maybe take a load back, and launch again. You stay in the cockpit.
	DRIVE_THROUGH,  ## Fly through, pull up under the canopy, use the counter (fuel...), and roll on out the far side.
}


## A short code name, used by jobs ("from_place", "to_place") and saves.
@export var id: String = "somewhere"
## The name shown on the HUD and the job board.
@export var display_name: String = "SOMEWHERE"
## What docking here does (see Kind above).
@export var kind: Kind = Kind.INTERIOR
## Drive-throughs: the counters you get (like "fuel").
@export var services: PackedStringArray = PackedStringArray()
## Who greets you on the comms when you dock (drop-offs and drive-throughs).
@export var host: NPCData
## What they might say.
@export var host_lines: PackedStringArray = PackedStringArray()
## On: the host's lines are said in order, one per visit, and then start
## over (so they can remember you, or finish a sentence they started last
## time). Off: a random one each visit.
@export var host_lines_in_order: bool = false
## The walkable inside of the place, where you arrive after docking.
@export_file("*.tscn") var interior_scene: String = ""
## Which spawn spot (in that interior) you climb out of the ship at.
@export var arrival_spawn: String = "FromShip"
## Free fuel when you dock here (the company's own pumps at home).
@export var free_fuel: bool = false
## Fuel here costs this much compared with the usual price (0.7 = 30% off).
@export_range(0.1, 3.0, 0.05) var fuel_price_factor: float = 1.0

@export_group("Rocks all around")
## What surrounds the station on every side (see AsteroidField.gd's
## "shell"): nothing, rocks, ice, junk (scrap) or chips (casino chips). A
## clear traffic lane runs through it to each approach ring.
@export_enum("none", "rocks", "ice", "junk", "chips") var surrounding_field: String = "none"
## How far out the rocks start and end (meters from the station).
@export var field_radii := Vector2(1500.0, 2600.0)
## How many rocks (a few thousand is a proper wall of rocks).
@export var field_rock_count: int = 3000
## How wide the traffic lanes through it are (meters from the middle).
@export var field_lane_radius: float = 170.0


## What the host says on visit number `visit` (1 = the first time).
func host_line(visit: int, rng: RandomNumberGenerator) -> String:
	if host_lines.is_empty():
		return ""
	if host_lines_in_order:
		return host_lines[(maxi(visit, 1) - 1) % host_lines.size()]
	return host_lines[rng.randi_range(0, host_lines.size() - 1)]
