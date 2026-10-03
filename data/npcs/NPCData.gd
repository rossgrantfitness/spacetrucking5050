class_name NPCData
extends Resource
## One person on the base: who they are and what they say. Each person gets
## their own .tres file in this folder; their look is a model scene chosen in
## the room where they stand.


## Their name, shown on the dialogue box.
@export var display_name: String = "Somebody"
## What kind of animal they are (just a note for now).
@export var species: String = "raccoon"
## Their gibberish voice: 1 = normal pitch, higher = squeakier, lower = deeper.
@export_range(0.4, 2.5, 0.05) var voice_pitch: float = 1.0
## What they say when you talk to them, one box per line. Lines can use
## {bunny}, {husband}, {base} and {currency} (see res://data/world_names.tres).
## (Proper conversations with choices and conditions come later.)
@export var lines: PackedStringArray = PackedStringArray(["..."])
