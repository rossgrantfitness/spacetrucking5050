class_name DateCard
extends CanvasLayer
## The date, small, in the bottom-left corner: the day and date on one line,
## the time under it. It's shown when you wake up and when a game starts or
## loads, so you always know where you are in the year, without getting in
## the way. Two colors only: warm gold for the date, soft white for the rest.
##
## Show it over whatever's on screen (it fades in, waits a moment, and fades
## out by itself, and never stops you playing):
##     DateCard.pop_up(tree)
## Or draw it onto your own dark screen (sleeping does this):
##     DateCard.draw_date(canvas, screen_size, alpha)


const GOLD := Color(1.0, 0.85, 0.3)
const SOFT := Color(0.82, 0.84, 0.95)

## Seconds to fade in, to stay up, and to fade out.
const FADE_IN: float = 0.35
const HOLD: float = 2.2
const FADE_OUT: float = 0.5

var _time: float = 0.0
var _canvas: Control


## Shows the date in the corner for a few seconds.
static func pop_up(tree: SceneTree) -> DateCard:
	var card := DateCard.new()
	tree.root.add_child(card)
	return card


## How big the lettering is on a screen this size (screen pixels per font
## pixel): small, like the rest of the HUD.
static func square_for(screen: Vector2) -> float:
	return maxf(2.0, floorf(screen.y / 300.0))


## Draws the date in the bottom-left corner of a `screen`-sized canvas,
## faded to `alpha`, on a small dark backing.
static func draw_date(canvas: CanvasItem, screen: Vector2, alpha: float) -> void:
	var square := square_for(screen)
	var date_line := "DAY %d  ·  %s" % [GameState.day, Economy.date_text()]
	var time_line := Economy.clock_text()
	var width := maxf(PixelFont.width(date_line, square), PixelFont.width(time_line, square))
	var line := PixelFont.height(square) + square * 3.0
	var corner := Vector2(square * 8.0, screen.y - square * 8.0 - line * 2.0)
	var pad := square * 3.0
	canvas.draw_rect(Rect2(corner - Vector2(pad, pad), Vector2(width + pad * 2.0, line * 2.0 + pad)), Color(0.01, 0.01, 0.04, 0.6 * alpha))
	PixelFont.draw(canvas, corner, date_line, square, Color(GOLD, alpha), 0.0, Color(0, 0, 0, 0.5 * alpha))
	PixelFont.draw(canvas, corner + Vector2(0.0, line), time_line, square, Color(SOFT, alpha * 0.85), 0.0, Color(0, 0, 0, 0.5 * alpha))


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
	draw_date(_canvas, _canvas.size, alpha)
