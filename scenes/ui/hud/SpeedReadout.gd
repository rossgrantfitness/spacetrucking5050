class_name SpeedReadout
extends HudWidget
## Bottom left: speed and boost.
## - The speed in big slanted digits, with a segmented bar under it. The
##   red segments at the end are the redline (the engines' top speed).
##   Boosting past it lights a row of yellow overflow segments.
## - A yellow tick across the bar shows where the throttle lever is set
##   (in reverse it turns to your system's color and says REV).
## - SPOOL blinks while boost spools up; FULL THROTTLE! if you try to boost
##   with the lever below full.
## - BOOST: a tiny bar of segments that drain while you boost.


const BAR_SEGMENTS: int = 24
const REDLINE_SEGMENTS: int = 4
const OVERFLOW_SEGMENTS: int = 6
const BOOST_SEGMENTS: int = 10

var _shown_speed: int = 0


func _init() -> void:
	bottom_row = true


func hud_step(_delta: float, numbers_due: bool) -> void:
	if numbers_due and ship() != null:
		_shown_speed = roundi(ship().flight.speed() * 3.6)


func _draw() -> void:
	var rig := ship()
	if rig == null:
		return
	var flight := rig.flight
	var left := MARGIN
	var boost_top := size.y - MARGIN - 5.0
	var bar_top := boost_top - 9.0
	var number_top := bar_top - 17.0

	# The big number, yellow while boosting past top speed.
	var overspeed := rig.overspeed_ratio()
	var number_color := YELLOW if overspeed > 0.02 else GREEN
	var digits := str(_shown_speed)
	text(Vector2(left, number_top), digits, number_color, BIG, 2.0, 0.2)
	text(Vector2(left + text_width(digits, BIG, 2.0) + 5.0, number_top + 9.0), "KM/H", tint(0.85))

	# The speed bar.
	var step := 4.0
	var share := clampf(flight.speed() / rig.ship_data.max_speed, 0.0, 1.0)
	var lit := ceili(share * BAR_SEGMENTS - 0.01)
	box(Rect2(left - 2.0, bar_top - 2.0, BAR_SEGMENTS * step + 5.0, 9.0), BACKING)
	for i in BAR_SEGMENTS:
		var redline := i >= BAR_SEGMENTS - REDLINE_SEGMENTS
		var color := tint(0.18)
		if redline:
			color = RED if i < lit else Color(RED, 0.3)
		elif i < lit:
			color = GREEN
		slanted(Rect2(left + i * step, bar_top, 3.0, 5.0), 1.0, color)
	# Boost overflow, after a little gap.
	var overflow_left := left + BAR_SEGMENTS * step + 4.0
	for i in OVERFLOW_SEGMENTS:
		var on := overspeed > (i + 0.5) / OVERFLOW_SEGMENTS
		slanted(Rect2(overflow_left + i * 3.0, bar_top + 1.0, 2.0, 3.0), 1.0, YELLOW if on else tint(0.12))
	# The throttle lever's tick: where you've set your speed.
	var lever := rig.controls.lever
	if absf(lever) > 0.01:
		var tick_x := left + absf(lever) * BAR_SEGMENTS * step - 1.0
		box(Rect2(tick_x, bar_top - 2.0, 1.0, 9.0), YELLOW if lever > 0.0 else tint())
		if lever < 0.0:
			text(Vector2(tick_x + 3.0, bar_top - 8.0), "REV", tint())
	# Boost spooling up (or waiting for full throttle).
	if flight.spool > 0.0:
		text(Vector2(overflow_left, bar_top - 8.0), "SPOOL", YELLOW if blink(0.15) else tint())
	elif rig.controls.boost_blocked:
		text(Vector2(overflow_left - 30.0, bar_top - 8.0), "FULL THROTTLE!", RED if blink(0.3) else tint())

	# The boost tank.
	var empty := flight.boost_fuel <= 0.0
	text(Vector2(left, boost_top), "BST", RED if empty and blink(0.6) else tint(0.85))
	var boost_lit := ceili(flight.boost_fuel * BOOST_SEGMENTS - 0.01)
	for i in BOOST_SEGMENTS:
		var color := tint(0.18)
		if i < boost_lit:
			color = YELLOW if flight.boosting else GREEN
		slanted(Rect2(left + 14.0 + i * 5.0, boost_top + 1.0, 4.0, 3.0), 1.0, color)
