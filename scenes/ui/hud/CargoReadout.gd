class_name CargoReadout
extends HudWidget
## Top right, while you're hauling a job:
## - CARGO: how intact the load is. Bonks knock it down, and it ticks down
##   a percent at a time so you see it happen.
## - PAY: what the job is on track to pay right now (base pay plus any
##   bonuses still in reach). It ticks up and down as bonuses are earned or
##   slip away.
## - LOAD: how much it weighs, galactic style ("450M T"). Green is light
##   for this rig, yellow heavy, red overloaded (more than the rig's rated
##   load: slow to start, slow to stop, wide in the turns).
## - RIDE: how rough the ride is for the cargo. Green is fine; yellow means
##   it's starting to take damage (hard turns, slides, braking, boosting);
##   red means it's rattling. Each time the load gets knocked around, a word
##   flashes under it saying why: HARD TURN, BRAKING, BOOST SHAKE, PINGS or
##   BUMPY.
## (You get paid when you dock and climb out at the destination.)


var _pop := HudWidget.Pop.new()
var _shown_cargo: float = -1.0
var _shown_pay: int = -1
var _pay_flash: float = 0.0
var _cargo_flash: float = 0.0
var _jostles_seen: int = 0
var _why: String = ""
var _why_time: float = 0.0


func hud_step(delta: float, numbers_due: bool) -> void:
	var job := GameState.active_job()
	var rig := ship()
	_pop.want = job != null and rig != null
	_pop.update(delta)
	_pay_flash = maxf(_pay_flash - delta, 0.0)
	_cargo_flash = maxf(_cargo_flash - delta, 0.0)
	_why_time = maxf(_why_time - delta, 0.0)
	if rig != null and rig.jostles != _jostles_seen:
		_jostles_seen = rig.jostles
		_why = {"turn": "HARD TURN!", "brake": "BRAKING!", "boost": "BOOST SHAKE!", "pings": "PINGS!", "bumpy": "BUMPY!"}.get(rig.last_jostle_reason, "")
		_why_time = 1.6
	if job == null or rig == null or not numbers_due:
		return
	# Cargo ticks down one percent per number update until it catches up.
	var cargo := roundf(rig.cargo_condition * 100.0)
	if _shown_cargo < 0.0 or cargo > _shown_cargo:
		_shown_cargo = cargo
	elif cargo < _shown_cargo:
		_shown_cargo -= 1.0
		_cargo_flash = 0.4
	# Pay counts toward its new value in a few jumps.
	var pay := job.pay_for(rig.cargo_condition, GameState.job_seconds)
	if _shown_pay < 0:
		_shown_pay = pay
	elif pay != _shown_pay:
		var jump := maxi(floori(absi(pay - _shown_pay) / 3.0), 1)
		if pay > _shown_pay:
			_pay_flash = 0.6
		_shown_pay += jump if pay > _shown_pay else -jump


func _draw() -> void:
	if not _pop.shown():
		return
	var right := size.x - MARGIN + roundf(_pop.hidden_share() * 90.0)
	var top := MARGIN
	var currency := GameState.names.currency_short
	box(Rect2(right - 72.0, top - 2.0, 74.0, 34.0 + (8.0 if _why_time > 0.0 else 0.0)), BACKING)
	var cargo_color := GREEN
	if _shown_cargo < 40.0:
		cargo_color = RED
	elif _shown_cargo < 70.0:
		cargo_color = YELLOW
	if _cargo_flash > 0.0 and blink(0.2):
		cargo_color = RED
	var cargo_text := "%d%%" % roundi(maxf(_shown_cargo, 0.0))
	text_right(Vector2(right, top), cargo_text, cargo_color, BIG, 1.0, 0.15)
	text_right(Vector2(right - text_width(cargo_text, BIG) - 4.0, top + 2.0), "CARGO", tint(0.85))
	var pay_text := "%d %s" % [maxi(_shown_pay, 0), currency]
	text_right(Vector2(right, top + 10.0), pay_text, YELLOW if _pay_flash > 0.0 else GREEN)
	text_right(Vector2(right - text_width(pay_text) - 4.0, top + 10.0), "+" if _pay_flash > 0.0 else "PAY", YELLOW if _pay_flash > 0.0 else tint(0.85))
	_draw_load(Vector2(right, top + 17.0))
	_draw_ride(Vector2(right, top + 25.0))
	if _why_time > 0.0:
		text_right(Vector2(right, top + 33.0), _why, RED if blink(0.2) else YELLOW)


## How much the load weighs, colored by how hard it is on this rig.
func _draw_load(right_top: Vector2) -> void:
	var job := GameState.active_job()
	if job == null:
		return
	var share := ship().load_share()
	var color := GREEN if share < 0.6 else (YELLOW if share <= 1.0 else RED)
	var weight := tons_text(job.weight)
	text_right(right_top, weight, color)
	text_right(Vector2(right_top.x - text_width(weight) - 4.0, right_top.y), "LOAD", tint(0.85))


## The ride-roughness bar, right-aligned at `right_top`.
func _draw_ride(right_top: Vector2) -> void:
	var stress := ship().cargo_stress
	var segments := 10
	var lit := ceili(stress * segments - 0.01)
	var left := right_top.x - segments * 4.0
	for i in segments:
		var share := (i + 0.5) / segments
		var color := tint(0.18)
		if i < lit:
			color = GREEN if share < 0.5 else (YELLOW if share < 0.72 else RED)
		slanted(Rect2(left + i * 4.0, right_top.y + 1.0, 3.0, 3.0), 1.0, color)
	var label_color := RED if stress > 0.72 and blink(0.3) else tint(0.85)
	text_right(Vector2(left - 3.0, right_top.y), "RIDE", label_color)
