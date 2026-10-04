class_name Banner
extends HudWidget
## A short message that pops in under the nav tape, like "AUTOPILOT
## DOCKING" or "RADIO OFF", in big slanted letters, then slides away.


var _pop := HudWidget.Pop.new()
var _text: String = ""
var _left: float = 0.0
var _forever: bool = false


func _init() -> void:
	always_shown = true


## Shows `words` for `seconds` (0 = until replaced).
func show_text(words: String, seconds: float) -> void:
	_text = words
	_left = seconds
	_forever = seconds <= 0.0
	_pop.want = true


func hud_step(delta: float, _numbers_due: bool) -> void:
	if not _forever:
		_left -= delta
		if _left <= 0.0:
			_pop.want = false
	_pop.update(delta)


func _draw() -> void:
	if not _pop.shown():
		return
	var center_x := floorf(size.x * 0.5)
	var top := MARGIN + 46.0 - roundf(_pop.hidden_share() * 10.0)
	var width := text_width(_text, BIG)
	box(Rect2(center_x - width * 0.5 - 6.0, top - 3.0, width + 13.0, 13.0), BACKING)
	outline(Rect2(center_x - width * 0.5 - 6.0, top - 3.0, width + 13.0, 13.0), tint(0.6))
	text_centered(Vector2(center_x, top), _text, YELLOW if blink(0.6) else GREEN, BIG, 1.0, 0.15)
