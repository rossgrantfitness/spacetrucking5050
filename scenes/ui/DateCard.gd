class_name DateCard
extends CanvasLayer
## The date, big in the middle of the screen: the day of the month, the
## month's name, the year, the time on the galaxy's clock, and a line about
## the month. It's shown when you wake up and when a game starts or loads,
## so you always know where you are in the year.
##
## Show it over whatever's on screen (it fades in, waits, and fades out by
## itself, and never stops you playing):
##     DateCard.pop_up(tree)
## Or draw it onto your own dark screen (sleeping does this):
##     DateCard.draw_date(canvas, middle_of_screen, square, alpha)


const GOLD := Color(1.0, 0.85, 0.3)
const PINK := Color(1.0, 0.5, 0.85)
const CYAN := Color(0.45, 0.95, 1.0)
const SOFT := Color(0.82, 0.84, 0.95)

## Seconds to fade in, to stay up, and to fade out.
const FADE_IN: float = 0.5
const HOLD: float = 3.0
const FADE_OUT: float = 0.8

var _time: float = 0.0
var _canvas: Control


## Shows the date over the screen for a few seconds.
static func pop_up(tree: SceneTree) -> DateCard:
	var card := DateCard.new()
	tree.root.add_child(card)
	return card


## Draws the date centered on `middle`, `square` screen pixels per font
## pixel, faded to `alpha`.
static func draw_date(canvas: CanvasItem, middle: Vector2, square: float, alpha: float, show_note: bool = true) -> void:
	var calendar := Economy.calendar
	var date := calendar.date_of(GameState.day)
	var top := middle.y - square * 41.0
	PixelFont.draw_centered(canvas, Vector2(middle.x, top), "~ DAY %d ~" % GameState.day, square, Color(SOFT, alpha * 0.8))
	PixelFont.draw_centered(canvas, Vector2(middle.x, top + square * 16.0), "%d %s" % [date["day"], calendar.month_name(date["month"])], square * 3.0, Color(GOLD, alpha))
	PixelFont.draw_centered(canvas, Vector2(middle.x, top + square * 36.0), "YEAR %d" % date["year"], square * 2.0, Color(PINK, alpha))
	PixelFont.draw_centered(canvas, Vector2(middle.x, top + square * 50.0), Economy.clock_text(), square, Color(CYAN, alpha))
	if not show_note:
		return
	var y := top + square * 63.0
	for line in PixelFont.wrap(calendar.month_note(date["month"]), square * 150.0, square):
		PixelFont.draw_centered(canvas, Vector2(middle.x, y), line, square, Color(SOFT, alpha * 0.9))
		y += square * 10.0


func _ready() -> void:
	layer = 44
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_card)
	add_child(_canvas)


func _process(delta: float) -> void:
	_time += delta
	if _time >= FADE_IN + HOLD + FADE_OUT:
		queue_free()
		return
	_canvas.queue_redraw()


func _draw_card() -> void:
	var alpha := clampf(_time / FADE_IN, 0.0, 1.0)
	if _time > FADE_IN + HOLD:
		alpha = clampf(1.0 - (_time - FADE_IN - HOLD) / FADE_OUT, 0.0, 1.0)
	var screen := _canvas.size
	var square := maxf(2.0, floorf(screen.y / 200.0))
	var middle := screen * 0.5
	# A dark band across the middle, so it reads over anything.
	var band := Rect2(0.0, middle.y - square * 50.0, screen.x, square * 102.0)
	_canvas.draw_rect(band, Color(0.01, 0.01, 0.04, 0.72 * alpha))
	_canvas.draw_rect(Rect2(band.position, Vector2(screen.x, square)), Color(GOLD, 0.6 * alpha))
	_canvas.draw_rect(Rect2(band.position + Vector2(0.0, band.size.y - square), Vector2(screen.x, square)), Color(GOLD, 0.6 * alpha))
	draw_date(_canvas, middle, square, alpha)
