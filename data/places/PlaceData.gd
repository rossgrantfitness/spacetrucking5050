class_name PlaceData
extends Resource
## A place you can fly to and dock at: the home base, the truck stop, and
## (later) stations in other systems. Each gets its own .tres file in this
## folder, and res://data/places/places.tres lists them all.
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
## The walkable inside of the place, where you arrive after docking.
@export_file("*.tscn") var interior_scene: String = ""
## Which spawn spot (in that interior) you climb out of the ship at.
@export var arrival_spawn: String = "FromShip"
## Free fuel when you dock here (the company's own pumps at home).
@export var free_fuel: bool = false
