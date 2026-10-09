@tool
class_name RetroWindowStyle
extends StyleBox
## The menu window look: an in-world trucker's terminal. A chunky gunmetal
## bezel (brushed metal, beveled edges, a screw in each corner, a strip of
## hazard-striped tape like the cockpit's struts, a little green power LED
## and an optional stamped maker's plate) around a recessed CRT screen (dark
## glass with scanlines, dither speckle, faint circuit traces, darker edges
## and a soft glare), so every menu feels like a screen bolted into the rig
## or the station. Used by every menu and dialogue box (see RetroUI.gd).

## The metal bezel: how thick it is, and its colors (lit top, shaded bottom).
@export var bezel: float = 18.0
@export var metal_top := Color(0.37, 0.39, 0.44)
@export var metal_bottom := Color(0.17, 0.18, 0.21)
## The bevel along the bezel's outer edge, and the thin outline around it.
@export var light_edge := Color(0.66, 0.69, 0.75)
@export var dark_edge := Color(0.08, 0.08, 0.1)
@export var outline := Color(0.0, 0.0, 0.02)
## How round the corners are.
@export var corner_radius: float = 12.0
## The screen: a little lighter at the top, deeper at the bottom (the alpha
## is how see-through it is).
@export var top_color := Color(0.08, 0.11, 0.17, 0.9)
@export var bottom_color := Color(0.02, 0.03, 0.06, 0.94)
## How strong the screen's grit (scanlines, speckle, traces) is.
@export_range(0.0, 1.0, 0.01) var weave: float = 1.0
## The bits and bobs on the bezel.
@export var screws: bool = true
@export var hazard_tape: bool = true
@export var power_led: bool = true
## Words stamped on a little plate at the bottom of the bezel ("" = none).
@export var plate_text: String = ""

static var _grit_texture: ImageTexture
static var _brushed_texture: ImageTexture
static var _hazard_texture: ImageTexture


func _init() -> void:
	content_margin_left = 34.0
	content_margin_right = 34.0
	content_margin_top = 30.0
	content_margin_bottom = 30.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var item := to_canvas_item
	# --- The metal bezel ---
	var outer := _rounded(rect, corner_radius)
	var colors := PackedColorArray()
	for point in outer:
		colors.append(metal_top.lerp(metal_bottom, clampf((point.y - rect.position.y) / maxf(rect.size.y, 1.0), 0.0, 1.0)))
	RenderingServer.canvas_item_add_polygon(item, outer, colors)
	RenderingServer.canvas_item_add_texture_rect(item, rect.grow(-corner_radius * 0.3), _brushed().get_rid(), true, Color(1, 1, 1, 0.5))
	_bevel(item, rect.grow(-1.5), corner_radius, 2.0, light_edge, dark_edge)
	var edge := outer.duplicate()
	edge.append(edge[0])
	RenderingServer.canvas_item_add_polyline(item, edge, PackedColorArray([outline]), 1.0)
	if hazard_tape and rect.size.x > 220.0:
		var tape := Rect2(rect.position.x + corner_radius + 10.0, rect.end.y - bezel + 3.0, minf(90.0, rect.size.x * 0.2), bezel - 6.0)
		RenderingServer.canvas_item_add_texture_rect(item, tape, _hazard().get_rid(), true)
		RenderingServer.canvas_item_add_rect(item, Rect2(tape.position.x, tape.end.y, tape.size.x, 1.0), Color(0, 0, 0, 0.5))
	if screws:
		var inset := bezel * 0.5
		for corner: Vector2 in [Vector2(inset, inset), Vector2(rect.size.x - inset, inset), Vector2(inset, rect.size.y - inset), Vector2(rect.size.x - inset, rect.size.y - inset)]:
			_screw(item, rect.position + corner, maxf(bezel * 0.22, 2.5))
	if power_led and rect.size.x > 160.0:
		var led := Vector2(rect.end.x - corner_radius - 22.0, rect.position.y + bezel * 0.5)
		RenderingServer.canvas_item_add_circle(item, led, 4.5, Color(0.3, 1.0, 0.45, 0.18))
		RenderingServer.canvas_item_add_circle(item, led, 2.5, Color(0.3, 1.0, 0.45))
		RenderingServer.canvas_item_add_circle(item, led + Vector2(-0.8, -0.8), 0.9, Color(0.85, 1.0, 0.9))
	if not plate_text.is_empty():
		_plate(item, rect)
	# --- The recessed CRT screen ---
	var screen_rect := rect.grow(-bezel)
	var screen_radius := maxf(corner_radius - bezel * 0.4, 4.0)
	var screen := _rounded(screen_rect, screen_radius)
	var glass := PackedColorArray()
	for point in screen:
		glass.append(top_color.lerp(bottom_color, clampf((point.y - screen_rect.position.y) / maxf(screen_rect.size.y, 1.0), 0.0, 1.0)))
	RenderingServer.canvas_item_add_polygon(item, screen, glass)
	if weave > 0.0:
		RenderingServer.canvas_item_add_texture_rect(item, screen_rect.grow(-screen_radius * 0.3), _grit().get_rid(), true, Color(1, 1, 1, weave))
	# Darker toward the edges, like an old tube.
	for ring in 4:
		var band := _rounded(screen_rect.grow(-2.0 - ring * 3.0), maxf(screen_radius - ring * 2.0, 2.0))
		band.append(band[0])
		RenderingServer.canvas_item_add_polyline(item, band, PackedColorArray([Color(0, 0, 0, 0.16 - ring * 0.035)]), 3.0)
	# A soft glare across the top-left of the glass.
	var glare_width := minf(screen_rect.size.x * 0.35, 260.0)
	var glare_depth := minf(screen_rect.size.y * 0.5, 70.0)
	var top := screen_rect.position + Vector2(screen_radius, 3.0)
	var glare := PackedVector2Array([top, top + Vector2(glare_width, 0.0), top + Vector2(glare_width * 0.55, glare_depth), top + Vector2(0.0, glare_depth)])
	RenderingServer.canvas_item_add_polygon(item, glare, PackedColorArray([Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.02), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)]))
	# Sunk into the metal: shaded along the top and left, a lit lip below.
	_bevel(item, screen_rect.grow(1.0), screen_radius + 1.0, 2.0, Color(0.55, 0.58, 0.64), Color(0.0, 0.0, 0.0, 0.85), true)


## A band around a rounded rectangle whose color follows which way the edge
## faces: `lit` up and to the left and `shaded` down and to the right, or
## the other way round for something sunk in (`sunk`).
func _bevel(item: RID, rect: Rect2, radius: float, width: float, lit: Color, shaded: Color, sunk: bool = false) -> void:
	var band := _rounded(rect, radius)
	var shades := PackedColorArray()
	var center := rect.get_center()
	for point in band:
		var facing := (point - center).normalized()
		var light := clampf(0.5 - 0.5 * facing.dot(Vector2(0.6, 0.8).normalized()), 0.0, 1.0)
		shades.append(shaded.lerp(lit, 1.0 - light if sunk else light))
	band.append(band[0])
	shades.append(shades[0])
	RenderingServer.canvas_item_add_polyline(item, band, shades, width)


## A little Phillips-head screw.
func _screw(item: RID, at: Vector2, radius: float) -> void:
	RenderingServer.canvas_item_add_circle(item, at + Vector2(0.6, 0.8), radius + 0.8, Color(0, 0, 0, 0.6))
	RenderingServer.canvas_item_add_circle(item, at, radius, Color(0.6, 0.62, 0.66))
	RenderingServer.canvas_item_add_circle(item, at - Vector2(0.5, 0.5), radius * 0.55, Color(0.78, 0.8, 0.84))
	var arm := radius * 0.5
	RenderingServer.canvas_item_add_line(item, at - Vector2(arm, arm), at + Vector2(arm, arm), Color(0.18, 0.18, 0.2), 1.0)
	RenderingServer.canvas_item_add_line(item, at + Vector2(-arm, arm), at + Vector2(arm, -arm), Color(0.18, 0.18, 0.2), 1.0)


## The stamped maker's plate at the bottom of the bezel.
func _plate(item: RID, rect: Rect2) -> void:
	var font: Font = load("res://fonts/menu_font.tres")
	var words := plate_text.to_upper()
	var text_width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10).x
	var plate := Rect2(rect.get_center().x - text_width * 0.5 - 6.0, rect.end.y - bezel + 1.0, text_width + 12.0, bezel - 2.0)
	RenderingServer.canvas_item_add_rect(item, plate.grow(1.0), Color(0, 0, 0, 0.7))
	RenderingServer.canvas_item_add_rect(item, plate, Color(0.62, 0.58, 0.46))
	RenderingServer.canvas_item_add_rect(item, Rect2(plate.position, Vector2(plate.size.x, 1.0)), Color(0.85, 0.8, 0.66))
	font.draw_string(item, Vector2(plate.position.x + 6.0, plate.position.y + plate.size.y * 0.5 + 4.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.16, 0.14, 0.1))


## The corners of a rounded rectangle, going round clockwise.
static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var corners := [
		[rect.position + Vector2(r, r), PI],
		[Vector2(rect.end.x - r, rect.position.y + r), PI * 1.5],
		[rect.end - Vector2(r, r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5],
	]
	for corner: Array in corners:
		for step in 5:
			var angle: float = corner[1] + step * (PI * 0.5) / 4.0
			points.append((corner[0] as Vector2) + Vector2(cos(angle), sin(angle)) * r)
	return points


## A tile of screen grit: dither speckle, dark scanlines every other row, and
## faint cyan circuit traces (the same every time).
static func _grit() -> ImageTexture:
	if _grit_texture != null:
		return _grit_texture
	const SIZE := 32
	var tile := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	tile.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050
	var bayer := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	for y in SIZE:
		for x in SIZE:
			var color := Color(0, 0, 0, 0)
			if y % 2 == 1:
				color = Color(0, 0, 0.02, 0.26)  # Scanline.
			# Ordered-dither speckle, a touch random so it isn't a pattern.
			if bayer[(y % 4) * 4 + x % 4] < 2 and rng.randf() < 0.55:
				color = Color(0.7, 0.9, 1.0, 0.06)
			tile.set_pixel(x, y, color)
	var trace := Color(0.3, 0.85, 1.0, 0.07)
	for run in 6:
		var at := Vector2i(rng.randi_range(0, 7) * 4, rng.randi_range(0, 7) * 4)
		var across := rng.randi_range(4, 14)
		var down := rng.randi_range(3, 10)
		for step in across:
			tile.set_pixelv(Vector2i((at.x + step) % SIZE, at.y), trace)
		for step in down:
			tile.set_pixelv(Vector2i((at.x + across) % SIZE, (at.y + step) % SIZE), trace)
		tile.set_pixelv(Vector2i((at.x + across) % SIZE, (at.y + down) % SIZE), Color(0.4, 0.95, 1.0, 0.14))
	_grit_texture = ImageTexture.create_from_image(tile)
	return _grit_texture


## Brushed metal: faint light and dark streaks running sideways.
static func _brushed() -> ImageTexture:
	if _brushed_texture != null:
		return _brushed_texture
	var tile := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for y in 16:
		var streak := rng.randf_range(-1.0, 1.0)
		for x in 64:
			var wobble := streak + rng.randf_range(-0.3, 0.3)
			tile.set_pixel(x, y, Color(1, 1, 1, 0.08 * wobble) if wobble > 0.0 else Color(0, 0, 0, -0.12 * wobble))
	_brushed_texture = ImageTexture.create_from_image(tile)
	return _brushed_texture


## Hazard tape: yellow and black diagonal stripes.
static func _hazard() -> ImageTexture:
	if _hazard_texture != null:
		return _hazard_texture
	var tile := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in 8:
		for x in 8:
			var yellow := (x + y) % 8 < 4
			tile.set_pixel(x, y, Color(0.92, 0.72, 0.12) if yellow else Color(0.08, 0.07, 0.06))
	_hazard_texture = ImageTexture.create_from_image(tile)
	return _hazard_texture
