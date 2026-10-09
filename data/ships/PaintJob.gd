class_name PaintJob
extends Resource
## A paint job from the paint shop: a tint over the rig's hull, and a
## matching engine trail color. All of them are in res://data/ships/paints.tres.


@export var id: String = "factory"
@export var display_name: String = "FACTORY"
@export_range(0, 100000, 10) var price: int = 400
## The hull's tint (white = no change).
@export var hull_tint: Color = Color.WHITE
## How strongly the tint shows (0 = not at all, 1 = fully).
@export_range(0.0, 1.0, 0.05) var strength: float = 0.6
## The engine trail's color (fully transparent = keep the rig's own).
@export var trail_color: Color = Color(1, 1, 1, 0)
