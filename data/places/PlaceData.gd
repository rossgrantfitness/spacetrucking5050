class_name PlaceData
extends Resource
## A place you can fly to and dock at: the home base, the truck stop, and
## (later) stations in other systems. Each gets its own .tres file in this
## folder, and res://data/places/places.tres lists them all.
##
## In the flight scene, each place is a station with a node named after its
## `id` under "Places" (with a DockPoint and an approach ring). Docking there
## takes you inside, to `interior_scene`.


## A short code name, used by jobs ("from_place", "to_place") and saves.
@export var id: String = "somewhere"
## The name shown on the HUD and the job board.
@export var display_name: String = "SOMEWHERE"
## The walkable inside of the place, where you arrive after docking.
@export_file("*.tscn") var interior_scene: String = ""
## Which spawn spot (in that interior) you climb out of the ship at.
@export var arrival_spawn: String = "FromShip"
## Free fuel when you dock here (the company's own pumps at home).
@export var free_fuel: bool = false
