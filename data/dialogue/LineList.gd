class_name LineList
extends Resource
## A simple list of lines to pick from at random (like Jack's one-liners
## on the WRECKED card). Add as many as you like.


@export var lines: PackedStringArray = PackedStringArray()


## One line at random ("" if the list is empty).
func pick(rng: RandomNumberGenerator) -> String:
	return lines[rng.randi_range(0, lines.size() - 1)] if not lines.is_empty() else ""
