class_name JumpCharge
extends HudWidget
## Pops up above the radar when you're approaching a system jump point:
## a bar charging up, then READY blinking green. Jump points arrive with
## routes between systems (M5/M8); until then it only shows in the HUD
## demo (F9).


const SEGMENTS: int = 16

var _pop := HudWidget.Pop.new()
var _charge: float = 0.0


func hud_step(delta: float, _numbers_due: bool) -> void:
	var rig := ship()
	_charge = rig.jump_charge if rig != null else -1.0
	if hud.demo:
		_charge = minf(fposmod(hud.time * 0.12, 1.25), 1.0)
	_pop.want = _charge >= 0.0
	_pop.update(delta)


func _draw() -> void:
	if not _pop.shown():
		return
	var center_x := floorf(size.x * 0.5)
	var top := size.y - MARGIN - 70.0 + roundf(_pop.hidden_share() * 14.0)
	var width := SEGMENTS * 4.0
	var left := center_x - width * 0.5
	box(Rect2(left - 18.0, top - 2.0, width + 40.0, 9.0), BACKING)
	var is_ready := _charge >= 1.0
	text(Vector2(left - 16.0, top), "JUMP", GREEN if is_ready and blink(0.4) else tint(0.85))
	var lit := ceili(_charge * SEGMENTS - 0.01)
	for i in SEGMENTS:
		slanted(Rect2(left + i * 4.0, top + 1.0, 3.0, 3.0), 1.0, (GREEN if is_ready else YELLOW) if i < lit else tint(0.18))
	text(Vector2(left + width + 3.0, top), "READY" if is_ready else "%d%%" % roundi(_charge * 100.0), GREEN if is_ready else YELLOW)
