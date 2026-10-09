class_name PaintList
extends Resource
## Every paint job at the paint shop, in order.


@export var paints: Array[PaintJob] = []


func find(id: String) -> PaintJob:
	for paint in paints:
		if paint != null and paint.id == id:
			return paint
	return null
