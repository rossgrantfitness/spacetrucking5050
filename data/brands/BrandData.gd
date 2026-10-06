class_name BrandData
extends Resource
## A brand in the galaxy: the same names turn up in vending machines, on
## the radio's ads and on billboards everywhere you haul. Made up, every one
## of them (no real brands). All of them are in res://data/brands/brands.tres,
## written by tools/brand_data/make_brands.py (edit the lists there).


@export var id: String = ""
## Its name, as printed on the packet.
@export var display_name: String = ""
## Its slogan (the radio ads and billboards use the same one).
@export var slogan: String = ""
## The story of the company, in a few lines.
@export_multiline var story: String = ""
## Its packaging color.
@export var color: Color = Color.WHITE
