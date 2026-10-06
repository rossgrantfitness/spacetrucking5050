class_name PortraitPainter
## Paints a tiny placeholder comm portrait (28x28 HUD pixels) for whoever's
## calling, from their NPC data: species, fur color and accent color.
## Knows: raccoon, owl, walrus, hamster, pig, cat, crocodile, bunny, otter,
## sloth and dog (anything else gets plain round ears).
## Flat color blocks and one feature that's theirs alone (Raccoony's mask,
## Marge's ear tufts, Wendell's tusks, Pip's cheeks...), per
## CHARACTER_BIBLE.md. M5 replaces these with real 3D heads.


const SIZE: float = 28.0
const DARK := Color(0.08, 0.06, 0.1)
const CREAM := Color(0.98, 0.95, 0.88)
const PINK := Color(0.89, 0.65, 0.63)


## Draws the portrait with its top-left corner at `corner`. `talking` opens
## the mouth (the HUD flaps it in time with the voice blips).
static func paint(canvas: CanvasItem, corner: Vector2, who: NPCData, talking: bool, blinking: bool) -> void:
	var o := corner.floor()
	var fur := who.fur_color
	var accent := who.accent_color
	var light := fur.lerp(CREAM, 0.55)
	var head := o + Vector2(14, 14)
	# Shoulders in their accent color (a jacket, a collar, a uniform).
	_rect(canvas, o + Vector2(4, 22), Vector2(20, 6), accent)
	_rect(canvas, o + Vector2(11, 22), Vector2(6, 2), accent.darkened(0.35))
	# Ears and other things behind the head.
	match who.species:
		"raccoon", "cat":
			var tall := 7.0 if who.species == "cat" else 5.0
			_triangle(canvas, o + Vector2(6, 9), o + Vector2(12, 7), o + Vector2(7, 9 - tall), fur)
			_triangle(canvas, o + Vector2(22, 9), o + Vector2(16, 7), o + Vector2(21, 9 - tall), fur)
			_triangle(canvas, o + Vector2(8, 8), o + Vector2(11, 7), o + Vector2(8, 6), DARK)
			_triangle(canvas, o + Vector2(20, 8), o + Vector2(17, 7), o + Vector2(20, 6), DARK)
		"owl":
			_triangle(canvas, o + Vector2(6, 9), o + Vector2(11, 7), o + Vector2(5, 3), fur.darkened(0.3))
			_triangle(canvas, o + Vector2(22, 9), o + Vector2(17, 7), o + Vector2(23, 3), fur.darkened(0.3))
		"hamster", "pig":
			canvas.draw_circle(o + Vector2(8, 7), 3.0, fur.darkened(0.15))
			canvas.draw_circle(o + Vector2(20, 7), 3.0, fur.darkened(0.15))
		"bunny":
			_rect(canvas, o + Vector2(4, 8), Vector2(3, 14), fur.darkened(0.1))
			_rect(canvas, o + Vector2(21, 8), Vector2(3, 14), fur.darkened(0.1))
		"walrus", "crocodile", "sloth":
			pass
		"lion":
			canvas.draw_circle(head, 11.5, fur.darkened(0.45))  # The mane.
		"ostrich":
			pass  # No ears; the beak comes below.
		"otter":
			canvas.draw_circle(o + Vector2(8, 8), 2.0, fur.darkened(0.2))
			canvas.draw_circle(o + Vector2(20, 8), 2.0, fur.darkened(0.2))
		"dog":
			_rect(canvas, o + Vector2(3, 7), Vector2(4, 11), fur.darkened(0.35))  # Floppy ears.
			_rect(canvas, o + Vector2(21, 7), Vector2(4, 11), fur.darkened(0.35))
		_:
			canvas.draw_circle(o + Vector2(8, 7), 2.5, fur)
			canvas.draw_circle(o + Vector2(20, 7), 2.5, fur)
	# The head.
	canvas.draw_circle(head, 8.0, fur)
	# Their one signature feature.
	match who.species:
		"ostrich":
			_rect(canvas, o + Vector2(10, 16), Vector2(8, 3), Color(1.0, 0.6, 0.35))  # A big flat beak.
		"raccoon":
			_rect(canvas, o + Vector2(7, 11), Vector2(14, 3), DARK)  # The mask.
			_rect(canvas, o + Vector2(10, 15), Vector2(8, 4), light)
		"owl":
			canvas.draw_circle(o + Vector2(11, 12), 3.0, CREAM)  # Big round eyes.
			canvas.draw_circle(o + Vector2(17, 12), 3.0, CREAM)
			_triangle(canvas, o + Vector2(13, 15), o + Vector2(15, 15), o + Vector2(14, 18), Color(1.0, 0.75, 0.2))
		"walrus":
			_rect(canvas, o + Vector2(8, 16), Vector2(12, 3), light)  # Mustache...
			_rect(canvas, o + Vector2(10, 19), Vector2(1, 4), CREAM)  # ...and tusks.
			_rect(canvas, o + Vector2(17, 19), Vector2(1, 4), CREAM)
		"hamster":
			canvas.draw_circle(o + Vector2(8, 16), 3.0, light)  # Stuffed cheeks.
			canvas.draw_circle(o + Vector2(20, 16), 3.0, light)
		"pig":
			_rect(canvas, o + Vector2(11, 15), Vector2(6, 3), PINK)  # The snout.
			_rect(canvas, o + Vector2(12, 16), Vector2(1, 1), DARK)
			_rect(canvas, o + Vector2(15, 16), Vector2(1, 1), DARK)
		"crocodile":
			_rect(canvas, o + Vector2(9, 15), Vector2(13, 5), fur.darkened(0.15))  # The long jaw.
			for x in range(10, 21, 2):
				_rect(canvas, o + Vector2(x, 19), Vector2(1, 1), CREAM)
		"otter":
			_rect(canvas, o + Vector2(9, 15), Vector2(10, 4), light)  # Muzzle...
			for whisker_y: float in [16.0, 18.0]:  # ...and whiskers.
				_rect(canvas, o + Vector2(4, whisker_y), Vector2(4, 1), CREAM)
				_rect(canvas, o + Vector2(20, whisker_y), Vector2(4, 1), CREAM)
			_rect(canvas, o + Vector2(6, 4), Vector2(16, 3), accent)  # Fishing hat.
			_rect(canvas, o + Vector2(4, 7), Vector2(20, 1), accent)
		"sloth":
			_rect(canvas, o + Vector2(8, 10), Vector2(5, 5), DARK.lerp(fur, 0.4))  # Sleepy eye patches.
			_rect(canvas, o + Vector2(16, 10), Vector2(5, 5), DARK.lerp(fur, 0.4))
			_rect(canvas, o + Vector2(10, 16), Vector2(8, 3), light)
		"dog":
			_rect(canvas, o + Vector2(11, 15), Vector2(6, 4), light)
			_rect(canvas, o + Vector2(13, 15), Vector2(2, 1), DARK)  # Nose.
			_rect(canvas, o + Vector2(7, 4), Vector2(14, 3), accent)  # Patrol cap.
			_rect(canvas, o + Vector2(13, 5), Vector2(2, 1), Color(1.0, 0.85, 0.3))  # Badge.
		"bunny":
			_rect(canvas, o + Vector2(6, 4), Vector2(16, 4), accent)  # Trucker cap.
			_rect(canvas, o + Vector2(13, 18), Vector2(1, 2), CREAM)  # Buck teeth.
			_rect(canvas, o + Vector2(15, 18), Vector2(1, 2), CREAM)
	# Eyes (owls already have theirs drawn big).
	var eye_y := 12.0
	for eye_x: float in [10.0, 17.0]:
		if blinking:
			_rect(canvas, o + Vector2(eye_x, eye_y + 1.0), Vector2(2, 1), DARK if who.species != "raccoon" else CREAM)
		else:
			_rect(canvas, o + Vector2(eye_x, eye_y), Vector2(2, 2), DARK if who.species != "raccoon" else CREAM)
			_rect(canvas, o + Vector2(eye_x, eye_y), Vector2(1, 1), CREAM if who.species != "raccoon" else DARK)
	# The mouth flaps while they talk.
	var mouth := o + Vector2(13, 19 if who.species != "walrus" else 20)
	if talking:
		_rect(canvas, mouth, Vector2(3, 2), DARK)
		_rect(canvas, mouth + Vector2(1, 1), Vector2(1, 1), PINK)
	else:
		_rect(canvas, mouth, Vector2(3, 1), DARK)


static func _rect(canvas: CanvasItem, where: Vector2, size: Vector2, color: Color) -> void:
	canvas.draw_rect(Rect2(where.floor(), size), color)


static func _triangle(canvas: CanvasItem, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([a, b, c]), color)
