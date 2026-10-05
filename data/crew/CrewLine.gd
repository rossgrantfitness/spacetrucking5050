class_name CrewLine
extends Resource
## A bit of small talk a crew member might say (after what they're up to).
## They don't repeat themselves until they've run through the others.


## What they say, one box per line. Can use {bunny}, {husband}, {company},
## {cargo} and {place}.
@export var lines: PackedStringArray = PackedStringArray()
@export var situation: CrewActivity.Situation = CrewActivity.Situation.ANY
## Only once this story flag is set (empty = always).
@export var needs_flag: String = ""
## Only once you've chatted with them on this many different days (they open
## up as you get to know them).
@export_range(0, 100) var min_friendship: int = 0
## A story flag set once they've said it.
@export var sets_flag: String = ""
