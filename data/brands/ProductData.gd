class_name ProductData
extends Resource
## One thing to eat or drink from a vending machine (see BrandData.gd).


@export var id: String = ""
@export var display_name: String = ""
## Which brand makes it (a BrandData id).
@export var brand_id: String = ""
@export_enum("food", "drink") var kind: String = "food"
@export_range(0, 1000, 1) var price: int = 5
## A line about it on the machine's button.
@export var blurb: String = ""
## What she says when she tries it (one is picked).
@export var taste_lines: PackedStringArray = PackedStringArray()
## What it does: nothing but taste ("none"), steady hands for the next trip
## ("steady"), or tops up the boost tank by a quarter ("zoom").
@export_enum("none", "steady", "zoom") var effect: String = "none"
## The shape of the packet she holds: can, bottle, cup, bar, bag, box or stick.
@export_enum("can", "bottle", "cup", "bar", "bag", "box", "stick") var package: String = "can"
## Where it's sold (place ids). Empty = in every machine in the galaxy.
@export var sold_at: PackedStringArray = PackedStringArray()
