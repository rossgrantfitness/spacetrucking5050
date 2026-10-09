class_name RadioLineup
extends Resource
## The stations on the dial, in order. Add a station by making a new
## RadioStation .tres file and adding it to this list in the Inspector.


@export var stations: Array[RadioStation] = []
