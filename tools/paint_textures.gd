extends SceneTree
## Paints the hand-painted, Mega Man Legends / Metal Gear Solid style
## textures in res://textures/generated/ (see reference/mmltextures*.png and
## reference/MGStextures.png for the look we're after).
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/paint_textures.gd
## (Running it again simply repaints the same images.) Then run
## tools/build_hub.gd and the other builders if you want the pre-rendered
## rooms to pick them up (they're painted when a room loads, so usually
## nothing else is needed).
##
## HOW THEY'RE PAINTED: late-PS1 artists painted the lighting right into
## their textures, because the console's own lighting was so basic. So
## every panel here has:
## - a 1-pixel dark seam around it,
## - a bright bevel along its top and left edges and a dark one along the
##   bottom and right (light comes from the top left),
## - flat bands of shading, lighter at the top, darker at the bottom, and
## - little hand-placed details: rivets, screws, vent slots, stencils, chips,
##   rust streaks.
## Shadows lean cool (blue-purple) and highlights lean warm (yellow), which
## is what makes painted pixels look rich instead of gray.
##
## Most are light and nearly neutral, because the models tint them with
## their own paint color. Every texture tiles seamlessly.
##
## (tools/generate_placeholder_textures.gd makes the rest: planets, stars,
## signs and effects.)


const OUTPUT_FOLDER: String = "res://textures/generated"
const Letters := preload("res://scenes/ui/PixelFont.gd")
const HAZARD_YELLOW := Color("ffc21a")
const HAZARD_BLACK := Color("1c1a22")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_FOLDER))
	var images := {
		"paint_grain.png": _paint_grain(),
		"wall_panels.png": _wall_panels(),
		"floor_tiles.png": _floor_tiles(),
		"hull_panels.png": _hull_panels(),
		"container.png": _container(),
		"vents.png": _vents(),
		"door.png": _door(),
		"wood.png": _wood(),
		"carpet.png": _carpet(),
		"machinery.png": _machinery(),
		"crate.png": _crate(),
		"grate.png": _grate(),
		"pipes.png": _pipes(),
	}
	var failed := false
	for file_name: String in images:
		var error := (images[file_name] as Image).save_png(OUTPUT_FOLDER.path_join(file_name))
		print("%s: %s" % [file_name, error_string(error)])
		failed = failed or error != OK
	quit(1 if failed else 0)


# --- The painter's toolkit ----------------------------------------------------------

## A shade of `base`: f < 1 darker (and a little cooler), f > 1 lighter (and
## a little warmer).
func _tone(base: Color, f: float) -> Color:
	var c := Color(base.r * f, base.g * f, base.b * f)
	if f < 1.0:
		var cool := Color(c.r * 0.86, c.g * 0.9, c.b * 1.1)
		c = c.lerp(cool, clampf((1.0 - f) * 1.4, 0.0, 1.0))
	else:
		var warm := Color(c.r * 1.03, c.g * 1.01, c.b * 0.9)
		c = c.lerp(warm, clampf((f - 1.0) * 2.5, 0.0, 1.0))
	return Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0))


func _new_image(width: int, height: int, fill: Color) -> Image:
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	image.fill(fill)
	return image


## Sets a pixel, wrapping around the edges (so details tile seamlessly).
func _dot(image: Image, x: int, y: int, color: Color) -> void:
	image.set_pixel(posmod(x, image.get_width()), posmod(y, image.get_height()), color)


## Fills a rectangle, wrapping around the edges.
func _fill(image: Image, rect: Rect2i, color: Color) -> void:
	for y in rect.size.y:
		for x in rect.size.x:
			_dot(image, rect.position.x + x, rect.position.y + y, color)


## Multiplies the pixels in a rectangle by a shade (painted shadow bands).
func _shade(image: Image, rect: Rect2i, f: float) -> void:
	for y in rect.size.y:
		for x in rect.size.x:
			var px := posmod(rect.position.x + x, image.get_width())
			var py := posmod(rect.position.y + y, image.get_height())
			image.set_pixel(px, py, _tone(image.get_pixel(px, py), f))


## A beveled panel: dark seam all round, lit top and left, shaded bottom
## and right, and the inside painted in flat bands (lighter at the top).
## `raised` = false paints it sunk in instead (light and shade swapped).
func _panel(image: Image, rect: Rect2i, base: Color, raised: bool = true, bevel: int = 1) -> void:
	_fill(image, rect, _tone(base, 0.42))
	var inside := rect.grow(-1)
	_fill(image, inside, base)
	# Painted shading bands: a lighter top fifth, a darker bottom quarter.
	_shade(image, Rect2i(inside.position, Vector2i(inside.size.x, maxi(floori(inside.size.y / 5.0), 1))), 1.05)
	var low := maxi(floori(inside.size.y / 4.0), 1)
	_shade(image, Rect2i(inside.position.x, inside.end.y - low, inside.size.x, low), 0.93)
	var light := _tone(base, 1.28 if raised else 0.68)
	var dark := _tone(base, 0.68 if raised else 1.22)
	for i in bevel:
		_fill(image, Rect2i(inside.position.x, inside.position.y + i, inside.size.x - i, 1), light)
		_fill(image, Rect2i(inside.position.x + i, inside.position.y, 1, inside.size.y - i), light)
		_fill(image, Rect2i(inside.position.x + i + 1, inside.end.y - 1 - i, inside.size.x - i - 1, 1), dark)
		_fill(image, Rect2i(inside.end.x - 1 - i, inside.position.y + i + 1, 1, inside.size.y - i - 1), dark)


## A rivet: a lit pixel with its shadow below-right.
func _rivet(image: Image, x: int, y: int, base: Color) -> void:
	_dot(image, x, y, _tone(base, 1.35))
	_dot(image, x + 1, y, _tone(base, 0.9))
	_dot(image, x, y + 1, _tone(base, 0.9))
	_dot(image, x + 1, y + 1, _tone(base, 0.45))


## A bigger slotted screw head (3 x 3).
func _screw(image: Image, x: int, y: int, base: Color) -> void:
	_fill(image, Rect2i(x, y, 3, 3), _tone(base, 1.1))
	_dot(image, x, y, _tone(base, 1.35))
	_dot(image, x + 2, y + 2, _tone(base, 0.45))
	_dot(image, x + 2, y + 1, _tone(base, 0.6))
	_dot(image, x + 1, y + 2, _tone(base, 0.6))
	_dot(image, x, y + 2, _tone(base, 0.4))
	_dot(image, x + 2, y, _tone(base, 0.4))
	_dot(image, x + 1, y + 1, _tone(base, 0.5))


## Vent slots: dark slits, each with a lit lip underneath.
func _slots(image: Image, rect: Rect2i, count: int, base: Color, gap: int = 3) -> void:
	for i in count:
		var y := rect.position.y + i * gap
		_fill(image, Rect2i(rect.position.x, y, rect.size.x, 1), _tone(base, 0.25))
		_fill(image, Rect2i(rect.position.x, y + 1, rect.size.x, 1), _tone(base, 1.25))
		_dot(image, rect.position.x - 1, y, _tone(base, 0.6))
		_dot(image, rect.end.x, y, _tone(base, 1.15))


## Rust and grime running down from a spot, fading as it goes.
func _streak(image: Image, x: int, y: int, length: int, strength: float) -> void:
	for i in length:
		var px := posmod(x, image.get_width())
		var py := posmod(y + i, image.get_height())
		var fade := 1.0 - float(i) / length
		var c := image.get_pixel(px, py)
		var stained := Color(c.r * 0.82, c.g * 0.74, c.b * 0.66)
		image.set_pixel(px, py, c.lerp(stained, strength * fade))


## Little paint chips and scuffs scattered around: a dark pixel with a lit
## one under it, like a dent catching the light.
func _chips(image: Image, rng: RandomNumberGenerator, count: int, strength: float = 0.75) -> void:
	for i in count:
		var x := rng.randi_range(0, image.get_width() - 1)
		var y := rng.randi_range(0, image.get_height() - 1)
		var c := image.get_pixel(x, y)
		_dot(image, x, y, _tone(c, 1.0 - 0.35 * strength))
		if rng.randf() < 0.6:
			_dot(image, x, y + 1, _tone(c, 1.0 + 0.2 * strength))


## Hazard stripes in a rectangle (diagonal, yellow and black).
func _hazard(image: Image, rect: Rect2i, width: int = 3) -> void:
	for y in rect.size.y:
		for x in rect.size.x:
			var yellow := posmod(x + y, width * 2) < width
			_dot(image, rect.position.x + x, rect.position.y + y, HAZARD_YELLOW if yellow else HAZARD_BLACK)
	_shade(image, Rect2i(rect.position.x, rect.end.y - 1, rect.size.x, 1), 0.7)


## Stencilled lettering (1 pixel squares), slightly worn.
func _stencil(image: Image, x: int, y: int, text: String, color: Color) -> void:
	Letters.stamp(image, Vector2i(x, y), text, 1, color)


func _rng(seed_number: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_number
	return rng


# --- The textures -------------------------------------------------------------------

## "Flat" paint that isn't quite flat: soft patches a shade apart, scratches
## and chips. Very light and neutral, so the paint color shows true. Every
## untextured surface gets it.
func _paint_grain() -> Image:
	var rng := _rng(101)
	var base := Color(0.88, 0.88, 0.87)
	var image := _new_image(64, 64, base)
	# Soft patches: a handful of overlapping blobs, a shade lighter or darker.
	for i in 14:
		var center := Vector2i(rng.randi_range(0, 63), rng.randi_range(0, 63))
		var radius := rng.randi_range(5, 12)
		var f := 1.03 if i % 2 == 0 else 0.965
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if x * x + y * y <= radius * radius:
					var px := posmod(center.x + x, 64)
					var py := posmod(center.y + y, 64)
					image.set_pixel(px, py, _tone(image.get_pixel(px, py), f))
	# Light scratches.
	for i in 6:
		var start := Vector2i(rng.randi_range(0, 63), rng.randi_range(0, 63))
		var dx := rng.randi_range(-1, 1)
		for step in rng.randi_range(3, 7):
			_dot(image, start.x + step, start.y + step * dx, _tone(base, 1.1))
	_chips(image, rng, 10, 0.5)
	return image


## Station wall paneling (tinted by each room's wall color): a 2 x 2 grid of
## tall panels with a riveted rail, a vent, a stencil number, a little
## warning label and rust streaks under the bolts.
func _wall_panels() -> Image:
	var rng := _rng(102)
	var base := Color(0.62, 0.63, 0.66)
	var image := _new_image(128, 128, base)
	for row in 2:
		for column in 2:
			var cell := Rect2i(column * 64, row * 64, 64, 64)
			_panel(image, cell, _tone(base, 1.0 if (row + column) % 2 == 0 else 0.94))
			# A riveted rail across the middle.
			var rail := Rect2i(cell.position.x + 1, cell.position.y + 28, 62, 7)
			_panel(image, rail, _tone(base, 0.82))
			for k in 5:
				_rivet(image, rail.position.x + 4 + k * 13, rail.position.y + 3, _tone(base, 0.82))
			# Screws in the corners.
			for corner: Vector2i in [Vector2i(3, 3), Vector2i(58, 3), Vector2i(3, 58), Vector2i(58, 58)]:
				_screw(image, cell.position.x + corner.x, cell.position.y + corner.y, base)
			# Rust running down from the rail bolts, here and there.
			for k in 3:
				if rng.randf() < 0.7:
					_streak(image, rail.position.x + 4 + k * 26, rail.end.y, rng.randi_range(6, 16), 0.5)
	# Details, one per panel.
	_slots(image, Rect2i(12, 44, 24, 0), 4, base)  # A vent low on the first panel.
	_panel(image, Rect2i(78, 8, 28, 14), _tone(base, 1.12), false)  # A recessed label plate...
	_stencil(image, 82, 12, "B-12", _tone(base, 0.4))  # ...with a deck number.
	_hazard(image, Rect2i(70, 108, 22, 5))  # A warning patch near the floor.
	_panel(image, Rect2i(12, 72, 18, 24), _tone(base, 0.9), false)  # An access hatch.
	_screw(image, 19, 82, _tone(base, 0.9))
	_stencil(image, 100, 76, "07", Color(0.95, 0.85, 0.35))
	_chips(image, rng, 24)
	return image


## Deck plating, dark blue-gray: 32-pixel plates, every other one with a
## raised diamond tread, bolts at the corners and worn shiny centers.
func _floor_tiles() -> Image:
	var rng := _rng(103)
	var base := Color(0.4, 0.43, 0.52)
	var image := _new_image(128, 128, base)
	for row in 4:
		for column in 4:
			var cell := Rect2i(column * 32, row * 32, 32, 32)
			var tread := (row + column) % 2 == 0
			_panel(image, cell, _tone(base, 1.0 if tread else 0.92))
			if tread:
				# Raised diamonds: a lit pixel and a dark one, in staggered rows.
				for y in range(4, 28, 4):
					for x in range(4, 28, 6):
						var offset := 3 if floori(y / 4.0) % 2 == 0 else 0
						_dot(image, cell.position.x + x + offset, cell.position.y + y, _tone(base, 1.35))
						_dot(image, cell.position.x + x + offset + 1, cell.position.y + y + 1, _tone(base, 0.6))
			for corner: Vector2i in [Vector2i(2, 2), Vector2i(28, 2), Vector2i(2, 28), Vector2i(28, 28)]:
				_rivet(image, cell.position.x + corner.x, cell.position.y + corner.y, base)
	# Boots wear the middle of each plate a little shinier.
	for i in 30:
		var x := rng.randi_range(0, 127)
		var y := rng.randi_range(0, 127)
		_dot(image, x, y, _tone(image.get_pixel(x, y), 1.15))
	_chips(image, rng, 18)
	return image


## Ship and station hull plating (tinted by the paint job): big riveted
## plates, an access hatch with four screws, vent slots, a NO STEP stencil, a
## hazard patch and grime streaks.
func _hull_panels() -> Image:
	var rng := _rng(104)
	var base := Color(0.86, 0.86, 0.88)
	var image := _new_image(128, 128, base)
	# Plates laid like brickwork: 64 x 32, every other row shifted.
	for row in 4:
		for column in 2:
			var shift := 32 if row % 2 == 1 else 0
			var cell := Rect2i(column * 64 + shift, row * 32, 64, 32)
			_panel(image, cell, _tone(base, [1.0, 0.95, 0.98, 0.92][(row + column) % 4]))
			# Rivet rows along the top and bottom seams.
			for k in 8:
				_rivet(image, cell.position.x + 4 + k * 8, cell.position.y + 2, base)
	# An access hatch with four screws.
	_panel(image, Rect2i(10, 40, 26, 18), _tone(base, 0.9), false)
	for corner: Vector2i in [Vector2i(12, 42), Vector2i(31, 42), Vector2i(12, 53), Vector2i(31, 53)]:
		_rivet(image, corner.x, corner.y, _tone(base, 0.9))
	_slots(image, Rect2i(78, 74, 30, 0), 5, base)
	_stencil(image, 72, 10, "NO STEP", _tone(base, 0.45))
	_hazard(image, Rect2i(44, 104, 24, 6))
	_stencil(image, 12, 106, "5050", _tone(base, 0.55))
	for i in 9:
		_streak(image, rng.randi_range(0, 127), rng.randi_range(0, 127), rng.randi_range(5, 20), 0.35)
	_chips(image, rng, 30)
	return image


## A corrugated shipping container side: ribs painted with a five-step
## ramp, top and bottom rails, door bars with lock handles, the company
## stencil, scuffs.
func _container() -> Image:
	var rng := _rng(105)
	var base := Color(0.86, 0.86, 0.86)
	var image := _new_image(128, 128, base)
	var rib: Array[float] = [0.7, 0.86, 1.0, 1.12, 1.0, 0.88, 0.76, 0.66]
	for y in range(8, 120):
		for x in 128:
			image.set_pixel(x, y, _tone(base, rib[x % 8]))
	_panel(image, Rect2i(0, 0, 128, 8), _tone(base, 0.92))
	_panel(image, Rect2i(0, 120, 128, 8), _tone(base, 0.85))
	for bar_x: int in [98, 112]:
		_panel(image, Rect2i(bar_x, 8, 4, 112), _tone(base, 0.75))
		_panel(image, Rect2i(bar_x - 3, 60, 10, 6), _tone(base, 0.6))  # Lock handle.
	_fill(image, Rect2i(8, 34, 60, 30), _tone(base, 1.1))
	Letters.stamp(image, Vector2i(12, 38), "LZY", 3, _tone(base, 0.35))
	_stencil(image, 12, 76, "FREIGHT CO.", _tone(base, 1.25))
	_stencil(image, 12, 86, "MAX GR 30480", _tone(base, 1.25))
	for i in 7:
		_streak(image, rng.randi_range(0, 127), 8, rng.randi_range(8, 40), 0.4)
	_chips(image, rng, 26)
	return image


## Vent grille: a beveled frame round dark slats with lit lips.
func _vents() -> Image:
	var base := Color(0.62, 0.62, 0.66)
	var image := _new_image(32, 32, base)
	_panel(image, Rect2i(0, 0, 32, 32), base)
	_fill(image, Rect2i(3, 3, 26, 26), _tone(base, 0.3))
	for y in range(4, 28, 4):
		_fill(image, Rect2i(3, y, 26, 2), _tone(base, 0.75))
		_fill(image, Rect2i(3, y, 26, 1), _tone(base, 1.1))
	return image


## A sliding sci-fi door, MML style: a thick frame, two halves with a split,
## a window with a glint, a hazard band, a status light and bolts.
func _door() -> Image:
	var rng := _rng(106)
	var base := Color(0.72, 0.74, 0.8)
	var image := _new_image(64, 128, base)
	_panel(image, Rect2i(0, 0, 64, 128), _tone(base, 0.8))
	_panel(image, Rect2i(4, 4, 28, 120), base)
	_panel(image, Rect2i(32, 4, 28, 120), _tone(base, 0.96))
	# The window: dark glass with a painted glint.
	_panel(image, Rect2i(10, 20, 44, 12), Color(0.12, 0.16, 0.28), false)
	for i in 6:
		_dot(image, 14 + i, 30 - i, Color(0.55, 0.65, 0.85))
		_dot(image, 15 + i, 30 - i, Color(0.4, 0.5, 0.75))
	_hazard(image, Rect2i(5, 100, 54, 10), 4)
	_panel(image, Rect2i(27, 54, 10, 16), _tone(base, 0.7))  # The handle plate.
	_fill(image, Rect2i(30, 58, 4, 3), Color(0.35, 1.0, 0.45))  # Unlocked light.
	_dot(image, 30, 58, Color(0.8, 1.0, 0.8))
	for y in [8, 44, 88, 118]:
		_rivet(image, 7, y, base)
		_rivet(image, 55, y, base)
	_stencil(image, 8, 80, "AUTH", _tone(base, 0.5))
	_chips(image, rng, 12)
	return image


## Painted wooden planks: four boards with dark gaps, grain lines in three
## tones, a knot or two, and a lit top edge on each board.
func _wood() -> Image:
	var rng := _rng(107)
	var base := Color(0.86, 0.66, 0.46)
	var image := _new_image(64, 64, base)
	for board in 4:
		var y0 := board * 16
		var board_base := _tone(base, [1.0, 0.93, 0.97, 0.9][board])
		_fill(image, Rect2i(0, y0, 64, 16), board_base)
		_fill(image, Rect2i(0, y0, 64, 1), _tone(base, 0.45))  # The gap.
		_fill(image, Rect2i(0, y0 + 1, 64, 1), _tone(board_base, 1.2))  # Lit edge.
		_fill(image, Rect2i(0, y0 + 15, 64, 1), _tone(board_base, 0.78))
		# Grain: long wavy lines, darker and lighter.
		for line in 4:
			var y := y0 + 3 + line * 3
			var wave := rng.randf_range(0.0, TAU)
			for x in 64:
				if rng.randf() < 0.85:
					var dy := roundi(sin(x * TAU / 64.0 * 2.0 + wave) * 1.0)
					_dot(image, x, y + dy, _tone(board_base, 0.84 if line % 2 == 0 else 1.08))
		# A knot.
		if rng.randf() < 0.6:
			var knot := Vector2i(rng.randi_range(4, 58), y0 + rng.randi_range(5, 10))
			_fill(image, Rect2i(knot, Vector2i(3, 2)), _tone(board_base, 0.6))
			_dot(image, knot.x + 1, knot.y, _tone(board_base, 0.45))
		# Nails at the ends.
		_rivet(image, 2, y0 + 7, board_base)
		_rivet(image, 34, y0 + 7, board_base)
	return image


## Low-pile carpet: a small woven diamond pattern, worn a little lighter in
## patches. Light, so the paint color tints it.
func _carpet() -> Image:
	var rng := _rng(108)
	var base := Color(0.8, 0.8, 0.8)
	var image := _new_image(64, 64, base)
	for y in 64:
		for x in 64:
			var d := absi(posmod(x, 8) - 4) + absi(posmod(y, 8) - 4)
			var f := 1.0
			if d == 4:
				f = 0.82
			elif d == 0:
				f = 1.1
			elif (x + y) % 2 == 0:
				f = 0.95
			image.set_pixel(x, y, _tone(base, f))
	for i in 40:
		var x := rng.randi_range(0, 63)
		var y := rng.randi_range(0, 63)
		_dot(image, x, y, _tone(image.get_pixel(x, y), rng.randf_range(0.85, 1.12)))
	return image


## A wall of machinery (colorful on its own; use it with a white paint):
## consoles with buttons, a little green screen, a round gauge, dials,
## labels and vents, like the panels in Mega Man Legends' ruins.
func _machinery() -> Image:
	var rng := _rng(109)
	var base := Color(0.55, 0.56, 0.6)
	var image := _new_image(128, 128, base)
	_panel(image, Rect2i(0, 0, 128, 128), base)
	# Left: a console with a screen and rows of buttons.
	_panel(image, Rect2i(4, 6, 56, 54), _tone(base, 1.08))
	_panel(image, Rect2i(9, 11, 30, 20), Color(0.06, 0.16, 0.08), false)
	for line in 4:
		var length := rng.randi_range(8, 24)
		_fill(image, Rect2i(12, 14 + line * 4, length, 1), Color(0.35, 0.95, 0.45))
	var lights: Array[Color] = [Color(1.0, 0.3, 0.25), Color(0.35, 1.0, 0.45), Color(1.0, 0.8, 0.25), Color(0.4, 0.8, 1.0)]
	for row in 3:
		for column in 4:
			var spot := Vector2i(10 + column * 7, 37 + row * 7)
			_fill(image, Rect2i(spot, Vector2i(5, 4)), _tone(base, 0.5))
			_fill(image, Rect2i(spot + Vector2i(1, 0), Vector2i(3, 3)), lights[(row + column * 2 + row * column) % 4])
			_dot(image, spot.x + 1, spot.y, Color(1, 1, 1))
	# A round pressure gauge.
	var gauge_center := Vector2i(50, 22)
	for y in range(-8, 9):
		for x in range(-8, 9):
			var r := x * x + y * y
			if r <= 64:
				var color := Color(0.92, 0.9, 0.82) if r <= 40 else _tone(base, 0.45 if (x + y) > 0 else 1.25)
				_dot(image, gauge_center.x + x, gauge_center.y + y, color)
	for i in 5:
		_dot(image, gauge_center.x - 3 + i, gauge_center.y - floori(i / 2.0) + 1, Color(0.85, 0.15, 0.1))
	_dot(image, gauge_center.x, gauge_center.y, Color(0.1, 0.1, 0.1))
	# Right: dials, a hazard-striped breaker and a vent.
	_panel(image, Rect2i(66, 6, 58, 30), _tone(base, 0.95))
	for i in 4:
		var dial := Vector2i(72 + i * 13, 14)
		_fill(image, Rect2i(dial, Vector2i(7, 7)), _tone(base, 0.35))
		_fill(image, Rect2i(dial + Vector2i(1, 1), Vector2i(5, 5)), _tone(base, 1.2))
		_dot(image, dial.x + 3, dial.y + 1 + i % 3, _tone(base, 0.3))
		_stencil(image, dial.x, dial.y + 9, str(i + 1), _tone(base, 0.4))
	_panel(image, Rect2i(66, 40, 26, 40), _tone(base, 0.9))
	_hazard(image, Rect2i(70, 44, 18, 6))
	_panel(image, Rect2i(73, 54, 12, 20), _tone(base, 0.55))  # The breaker lever.
	_fill(image, Rect2i(76, 56, 6, 5), Color(0.9, 0.2, 0.18))
	_panel(image, Rect2i(96, 40, 28, 40), _tone(base, 0.92))
	_slots(image, Rect2i(100, 45, 20, 0), 9, base, 4)
	# Bottom: a long label strip and pipes running across.
	_panel(image, Rect2i(4, 64, 56, 16), _tone(base, 1.15), false)
	_stencil(image, 8, 69, "AUX PWR 3", _tone(base, 0.45))
	for p in 3:
		var y := 88 + p * 12
		var pipe_base := _tone(base, [1.05, 0.9, 1.0][p])
		for x in 128:
			for t in 8:
				_dot(image, x, y + t, _tone(pipe_base, [0.7, 1.05, 1.3, 1.15, 1.0, 0.88, 0.72, 0.55][t]))
		for clamp_x: int in [20, 76]:
			_panel(image, Rect2i(clamp_x + p * 9, y - 1, 6, 10), _tone(base, 0.8))
	_chips(image, rng, 16)
	return image


## A painted cargo crate face: a thick frame, an X brace, a stencilled arrow
## and FRAGILE, corner brackets.
func _crate() -> Image:
	var rng := _rng(110)
	var base := Color(0.84, 0.8, 0.7)
	var image := _new_image(64, 64, base)
	_panel(image, Rect2i(0, 0, 64, 64), _tone(base, 0.85))
	_panel(image, Rect2i(6, 6, 52, 52), base, false)
	# The X brace: two lit-and-shaded diagonal boards.
	for i in range(6, 58):
		for t in 4:
			var shade := [1.25, 1.05, 0.95, 0.7][t] as float
			_dot(image, i + t - 2, i, _tone(base, shade * 0.9))
			_dot(image, 63 - i + t - 2, i, _tone(base, shade * 0.86))
	for corner: Vector2i in [Vector2i(1, 1), Vector2i(55, 1), Vector2i(1, 55), Vector2i(55, 55)]:
		_panel(image, Rect2i(corner, Vector2i(8, 8)), Color(0.5, 0.5, 0.55))
		_rivet(image, corner.x + 3, corner.y + 3, Color(0.5, 0.5, 0.55))
	_stencil(image, 14, 9, "FRAGILE", Color(0.75, 0.2, 0.15))
	# An up arrow.
	for y in 6:
		_fill(image, Rect2i(46 - y, 40 + y, 1 + y * 2, 1), Color(0.25, 0.22, 0.2))
	_fill(image, Rect2i(45, 46, 3, 6), Color(0.25, 0.22, 0.2))
	_chips(image, rng, 14)
	return image


## Steel grating for catwalks and landings: a grid of lit bars over darkness.
func _grate() -> Image:
	var base := Color(0.62, 0.64, 0.7)
	var image := _new_image(32, 32, _tone(base, 0.2))
	for i in range(0, 32, 8):
		_fill(image, Rect2i(0, i, 32, 2), _tone(base, 1.0))
		_fill(image, Rect2i(0, i, 32, 1), _tone(base, 1.3))
		_fill(image, Rect2i(i, 0, 2, 32), _tone(base, 0.9))
		_fill(image, Rect2i(i, 0, 1, 32), _tone(base, 1.2))
	for x in range(0, 32, 8):
		for y in range(0, 32, 8):
			_dot(image, x, y, _tone(base, 1.45))
	return image


## A bundle of three vertical pipes with painted round shading and clamps.
func _pipes() -> Image:
	var base := Color(0.7, 0.72, 0.76)
	var image := _new_image(32, 64, _tone(base, 0.3))
	var round_shade: Array[float] = [0.55, 0.8, 1.05, 1.3, 1.2, 1.05, 0.9, 0.75, 0.6]
	for p in 3:
		var x0 := 1 + p * 10
		var pipe := _tone(base, [1.0, 0.85, 1.1][p])
		for y in 64:
			for t in 9:
				_dot(image, x0 + t, y, _tone(pipe, round_shade[t]))
		_panel(image, Rect2i(x0 - 1, 20 + p * 9, 11, 5), _tone(base, 0.75))
	return image
