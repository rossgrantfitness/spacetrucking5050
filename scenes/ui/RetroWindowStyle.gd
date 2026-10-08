@tool
class_name RetroWindowStyle
extends StyleBox
## The menu window look, after late-90s console RPG menus: a rounded, beveled
## frame (bright along the top and left edges, shaded along the bottom and
## right, like a little raised slab) around a blue gradient with a fine
## woven texture. Used by every menu and dialogue box (see RetroUI.gd).

## The fill: lighter at the top, deeper at the bottom.
@export var top_color := Color(0.33, 0.42, 0.82)
@export var bottom_color := Color(0.13, 0.17, 0.46)
## How round the corners are, and how thick the bevel is (pixels).
@export var corner_radius: float = 9.0
@export var bevel: float = 3.0
## The light and dark sides of the bevel, and the thin outline around it.
@export var light_edge := Color(0.93, 0.95, 1.0)
@export var dark_edge := Color(0.36, 0.4, 0.58)
@export var outline := Color(0.03, 0.04, 0.12)
## How strong the woven texture is (0 = plain).
@export_range(0.0, 1.0, 0.01) var weave: float = 0.6

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
	# The woven texture over it (kept inside the rounded corners).
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


## A tiny tile of diagonal weave: light and dark threads crossing.
static func _weave() -> ImageTexture:
	if _weave_texture != null:
		return _weave_texture
	var tile := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in 4:
			var thread := (x + y) % 4
			var other := (x - y + 8) % 4
			var shade := Color(1, 1, 1, 0.22) if thread == 0 else (Color(0, 0, 0.1, 0.3) if other == 2 else Color(0, 0, 0, 0))
			tile.set_pixel(x, y, shade)
	_weave_texture = ImageTexture.create_from_image(tile)
	return _weave_texture
