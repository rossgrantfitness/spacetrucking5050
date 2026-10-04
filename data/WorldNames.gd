class_name WorldNames
extends Resource
## The big names in the game, kept in ONE place so they're easy to change.
## Open res://data/world_names.tres and type in the Inspector.
##
## Dialogue lines can use these as {bunny}, {husband}, {base} and {currency},
## and they're filled in automatically (see WorldNames.fill_in).


## The protagonist's name.
@export var bunny_name: String = "[BUNNY_NAME]"
## Her late husband's name.
@export var husband_name: String = "[HUSBAND_NAME]"
## The starship base she lives on.
@export var base_name: String = "[BASE_NAME]"
## What money is called.
@export var currency: String = "credits"
## Its short form, for tight spots like the HUD ("650 CR").
@export var currency_short: String = "CR"


## Replaces {bunny}, {husband}, {base} and {currency} in `text`.
func fill_in(text: String) -> String:
	return text.format({"bunny": bunny_name, "husband": husband_name, "base": base_name, "currency": currency})
