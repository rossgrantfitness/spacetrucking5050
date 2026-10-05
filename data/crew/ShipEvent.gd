class_name ShipEvent
extends Resource
## Something that happens aboard now and then: card night in the galley,
## the coffee machine breaking, a lost wrench. While it's on, the crew in
## `roles` are where it puts them (saying its lines) instead of their usual
## activities. Some events hide a thing to find somewhere aboard; bring it
## back to its owner for a little thank-you.


@export var id: String = "event"
## Shown when you first walk into the rig while it's on.
@export var title: String = "SOMETHING'S UP"
@export var situation: CrewActivity.Situation = CrewActivity.Situation.ANY
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
## Only once this story flag is set (empty = always).
@export var needs_flag: String = ""
## Where the crew are for it (each with `crew` set).
@export var roles: Array[CrewActivity] = []

@export_group("Something to find")
## What's lost ("Digby's lucky wrench"). Empty = nothing to find.
@export var find_item: String = ""
@export_file("*.tscn") var find_room: String = ""
## A Marker3D under the room's "CrewSpots" node.
@export var find_spot: String = ""
## Who it belongs to (a crew id), and what they give you for it.
@export var find_owner: String = ""
@export var find_reward: int = 0
## What they say when you hand it back.
@export var find_thanks: PackedStringArray = PackedStringArray()
