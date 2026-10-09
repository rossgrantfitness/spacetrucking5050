class_name CalendarClock
extends HudWidget
## Top right (under the cargo readout when you're hauling): the galaxy's
## clock, ticking along fast while you fly, and today's date. A long haul
## rolls over a day or two before you get there, which is the point: you're
## crossing the galaxy.


var _clock_text: String = ""
var _date_text: String = ""
var _day: int = 0
## Flashes the date when a new day rolls over.
var _new_day_flash: float = 0.0


func hud_step(delta: float, _numbers_due: bool) -> void:
	_clock_text = Economy.clock_text()
	_date_text = Economy.date_text()
	if _day != 0 and GameState.day != _day:
		_new_day_flash = 2.0
	_day = GameState.day
	_new_day_flash = maxf(_new_day_flash - delta, 0.0)


func _draw() -> void:
	if _clock_text.is_empty():
		return
	var right := size.x - MARGIN
	# Under the cargo readout when that's up.
	var top := MARGIN + (46.0 if GameState.active_job() != null else 0.0)
	var width := maxf(text_width(_clock_text, BIG), text_width(_date_text)) + 6.0
	box(Rect2(right - width, top - 2.0, width + 2.0, 20.0), BACKING)
	text_right(Vector2(right, top), _clock_text, GREEN, BIG, 1.0, 0.15)
	var date_color := YELLOW if _new_day_flash > 0.0 and blink(0.3) else tint(0.85)
	text_right(Vector2(right, top + 11.0), _date_text, date_color)
