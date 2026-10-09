class_name GlovePointer
extends Control
## The white-gloved pointing hand that shows which menu option you're on,
## like a late-90s console RPG menu. It follows whatever has the keyboard /
## gamepad focus inside `scope` (a menu's root), sitting just to the left
## of it, and gives a little tap every so often.
##
## Add one to a menu with RetroUI.add_pointer(menu_root).

## The glove, as a little picture: k = outline, w = white, g = shade.
const PICTURE := [
	".....kkkkk........",
	"....kwwwwwkkkkkkk.",
	"...kwwwwwwwwwwwwwk",
	"..kwwwwwwkkkkkkkk.",
	".kwwwwwwwwwwwk....",
	"kgwwwwwkkkkkk.....",
	"kgwwwwwwwwwwk.....",
	"kggwwwwkkkkk......",
	"kgggwwwwwwwk......",
	".kgggkkkkkk.......",
	"..kkk.............",
]
const COLORS := {"k": Color(0.05, 0.05, 0.1), "w": Color(1, 1, 1), "g": Color(0.68, 0.7, 0.78)}

## The menu whose focused option the glove points at.
var scope: Control
## How big each pixel of the glove is.
var pixel: float = 2.0

var _time := 0.0
var _target: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	z_index = 10
	size = Vector2(PICTURE[0].length(), PICTURE.size()) * pixel
	visible = false


func _process(delta: float) -> void:
	_time += delta
	var focused := get_viewport().gui_get_focus_owner()
	var aimed := focused != null and scope != null and is_instance_valid(scope) and scope.is_ancestor_of(focused) \
			and focused.is_visible_in_tree() and focused is BaseButton
	visible = aimed
	if not aimed:
		_target = null
		return
	# Just left of the option's words (inside its left margin, where the
	# menu look leaves room for it).
	var spot := focused.get_global_rect()
	var margin := 0.0
	var box := focused.get_theme_stylebox("normal")
	if box != null:
		margin = box.content_margin_left
	var goal := Vector2(spot.position.x + margin - size.x - 6.0, spot.position.y + (spot.size.y - size.y) * 0.5)
	# A little tap toward the option, now and then.
	goal.x += -3.0 * maxf(0.0, sin(_time * 5.0)) * (1.0 if fposmod(_time, 2.4) < 1.3 else 0.0)
	if focused != _target:
		_target = focused
		global_position = goal
	else:
		global_position = global_position.lerp(goal, 1.0 - exp(-25.0 * delta))
	queue_redraw()


func _draw() -> void:
	for row in PICTURE.size():
		var line: String = PICTURE[row]
		for column in line.length():
			var color: Variant = COLORS.get(line[column])
			if color != null:
				draw_rect(Rect2(Vector2(column, row) * pixel, Vector2.ONE * pixel), color)
