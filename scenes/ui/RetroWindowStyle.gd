@tool
class_name RetroWindowStyle
extends StyleBox
## The menu window look, after late-90s console RPG menus with a cyberpunk
## PS1 grit: a rounded, beveled frame (lit along the top and left edges,
## shaded along the bottom and right, like a little raised slab) around a
## dark, slightly see-through indigo glass, textured with dither noise,
## scanlines and faint circuit traces, and a thin neon line along the top.
## Used by every menu and dialogue box (see RetroUI.gd).

## The fill: a little lighter at the top, deeper at the bottom (the alpha
## is how see-through it is).
@export var top_color := Color(0.12, 0.14, 0.28, 0.84)
@export var bottom_color := Color(0.04, 0.05, 0.13, 0.88)
## How round the corners are, and how thick the bevel is (pixels).
@export var corner_radius: float = 9.0
@export var bevel: float = 3.0
## The light and dark sides of the bevel, and the thin outline around it.
@export var light_edge := Color(0.58, 0.66, 0.78)
@export var dark_edge := Color(0.13, 0.15, 0.26)
@export var outline := Color(0.0, 0.0, 0.03)
## The thin neon line along the top edge (fully clear = none).
@export var neon := Color(0.3, 0.9, 1.0, 0.55)
## How strong the gritty texture is (0 = plain glass).
@export_range(0.0, 1.0, 0.01) var weave: float = 1.0

static var _weave_texture: ImageTexture


func _init() -> void:
	content_margin_left = 20.0
	content_margin_right = 20.0
	content_margin_top = 14.0
	content_margin_bottom = 14.0


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var outer := _rounded(rect, corner_radius)
	var inner_rect := rect.grow(-bevel - 1.0)
	var inner := _rounded(inner_rect, maxf(corner_radius - bevel, 2.0))
	# The fill: a top-to-bottom gradient (each corner point takes the color
	# for its height).
	var colors := PackedColorArray()
	for point in inner:
		colors.append(top_color.lerp(bottom_color, clampf((point.y - inner_rect.position.y) / maxf(inner_rect.size.y, 1.0), 0.0, 1.0)))
	RenderingServer.canvas_item_add_polygon(to_canvas_item, inner, colors)
	# The gritty texture over it (kept inside the rounded corners).
	if weave > 0.0:
		var cloth := inner_rect.grow(-maxf(corner_radius - bevel, 2.0) * 0.3)
		RenderingServer.canvas_item_add_texture_rect(to_canvas_item, cloth, _weave().get_rid(), true, Color(1, 1, 1, weave))
	# The bevel: a thick band whose color follows which way the edge faces
	# (light up and to the left, shaded down and to the right).
	var middle := _rounded(rect.grow(-bevel * 0.5 - 0.5), corner_radius - bevel * 0.5)
	var shades := PackedColorArray()
	var center := rect.get_center()
	for point in middle:
		var facing := (point - center).normalized()
		var light := clampf(0.5 - 0.5 * facing.dot(Vector2(0.6, 0.8).normalized()), 0.0, 1.0)
		shades.append(dark_edge.lerp(light_edge, light))
	middle.append(middle[0])
	shades.append(shades[0])
	RenderingServer.canvas_item_add_polyline(to_canvas_item, middle, shades, bevel)
	# A thin dark line around the outside and inside of the bevel.
	outer.append(outer[0])
	RenderingServer.canvas_item_add_polyline(to_canvas_item, outer, PackedColorArray([outline]), 1.0)
	var inside := _rounded(inner_rect.grow(0.5), maxf(corner_radius - bevel, 2.0))
	inside.append(inside[0])
	RenderingServer.canvas_item_add_polyline(to_canvas_item, inside, PackedColorArray([Color(outline, 0.7)]), 1.0)
	# A thin neon line just inside the top edge, fading out at the ends.
	if neon.a > 0.0:
		var y := inner_rect.position.y + 1.0
		var left := inner_rect.position.x + corner_radius
		var right := inner_rect.end.x - corner_radius
		var glow := PackedColorArray([Color(neon, 0.0), neon, neon, Color(neon, 0.0)])
		RenderingServer.canvas_item_add_polyline(to_canvas_item, PackedVector2Array([Vector2(left, y), Vector2(lerpf(left, right, 0.15), y),
				Vector2(lerpf(left, right, 0.85), y), Vector2(right, y)]), glow, 1.0)


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


## A tile of PS1 grit: dither speckle, dark scanlines every other row, and
## faint cyan circuit traces on a grid (the same every time).
static func _weave() -> ImageTexture:
	if _weave_texture != null:
		return _weave_texture
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
				color = Color(0, 0, 0.02, 0.22)  # Scanline.
			# Ordered-dither speckle, a touch random so it isn't a pattern.
			if bayer[(y % 4) * 4 + x % 4] < 2 and rng.randf() < 0.55:
				color = Color(0.75, 0.85, 1.0, 0.07)
			tile.set_pixel(x, y, color)
	# Circuit traces: a few right-angled runs ending in a solder dot.
	var trace := Color(0.3, 0.85, 1.0, 0.09)
	for run in 6:
		var at := Vector2i(rng.randi_range(0, 7) * 4, rng.randi_range(0, 7) * 4)
		var across := rng.randi_range(4, 14)
		var down := rng.randi_range(3, 10)
		for step in across:
			tile.set_pixelv(Vector2i((at.x + step) % SIZE, at.y), trace)
		for step in down:
			tile.set_pixelv(Vector2i((at.x + across) % SIZE, (at.y + step) % SIZE), trace)
		tile.set_pixelv(Vector2i((at.x + across) % SIZE, (at.y + down) % SIZE), Color(0.4, 0.95, 1.0, 0.18))
	_weave_texture = ImageTexture.create_from_image(tile)
	return _weave_texture
