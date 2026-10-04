class_name RushTimer
extends HudWidget
## Pops in under the nav tape on a rush job: the time left to earn the rush
## bonus, counting down. In the last 15 seconds it blinks. If you're late it
## just says so calmly: you still get the base pay. Rush jobs never fail.


var _pop := HudWidget.Pop.new()
var _shown_text: String = ""
var _late: bool = false
var _left: float = 0.0


func hud_step(delta: float, numbers_due: bool) -> void:
	var haul := hud.haul
	_pop.want = haul != null and haul.job.is_rush() and not haul.delivered
	_pop.update(delta)
	if haul == null or not numbers_due:
		return
	_left = haul.rush_seconds_left()
	_late = _left < 0.0
	_shown_text = ("LATE +" + clock(-_left)) if _late else clock(_left)


func _draw() -> void:
	if not _pop.shown():
		return
	var center_x := floorf(size.x * 0.5)
	# Slides down from under the nav tape, in steps.
	var top := MARGIN + 25.0 - roundf(_pop.hidden_share() * 12.0)
	var label := "RUSH"
	var width := text_width(label) + 4.0 + text_width(_shown_text, BIG)
	var left := center_x - floorf(width * 0.5)
	box(Rect2(left - 3.0, top - 2.0, width + 7.0, 11.0), BACKING)
	var color := tint(0.8) if _late else YELLOW
	if not _late and _left < 15.0 and not blink(0.5):
		color = Color(YELLOW, 0.35)
	text(Vector2(left, top + 2.0), label, tint(0.85) if _late else YELLOW)
	text(Vector2(left + text_width(label) + 4.0, top), _shown_text, color, BIG, 1.0, 0.15)
