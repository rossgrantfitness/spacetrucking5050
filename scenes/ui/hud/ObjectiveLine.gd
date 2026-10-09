class_name ObjectiveLine
extends HudWidget
## Top middle, under the compass and ETA: what you're meant to be doing
## right now (Objective.gd), like "PULL INTO THE TRUCK STOP". If there's no
## course set and somewhere to be, it reminds you that M charts one.


var _text: String = ""


func hud_step(_delta: float, numbers_due: bool) -> void:
	if not numbers_due and not _text.is_empty():
		return
	_text = "> " + str(Objective.current(true)["text"])
	var rig := ship()
	if rig != null and rig.cruise == null and (GameState.active_job() != null or not GameState.has_flag("met_marge")):
		_text += "  · M: AUTOPILOT"


func _draw() -> void:
	if _text.is_empty():
		return
	var top := MARGIN + 27.0  # Under the nav tape and its ETA.
	var width := text_width(_text) + 10.0
	var left := floorf((size.x - width) * 0.5)
	if hud.comm != null:
		left = maxf(left, hud.comm.right_edge() + 4.0)  # Beside a comm call, not under it.
	box(Rect2(left, top - 2.0, width, 11.0), BACKING)
	box(Rect2(left, top - 2.0, 2.0, 11.0), YELLOW)
	text(Vector2(left + 6.0, top), _text, YELLOW, SMALL, 1.0, 0.15)
