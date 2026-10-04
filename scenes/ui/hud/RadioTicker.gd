class_name RadioTicker
extends HudWidget
## Top left: the radio. Signal bars and the station's dial number and name
## on top; the song (or ad) scrolls underneath like an old LED sign, one
## letter at a time. Flipping stations (Q / E, D-pad left / right) fills it
## with static for a moment. Storms knock the signal bars down. With the
## radio off (R / D-pad up) it goes dark.
## (A comm call slides in over the top of it.)


## Letters that fit in the scrolling window.
const WINDOW_LETTERS: int = 26
## Seconds per one-letter step of the scroll.
const SCROLL_SECONDS: float = 0.22
## Seconds of static after flipping stations.
const TUNING_SECONDS: float = 0.6
const STATIC_LETTERS := "#*%:.-+=/"

var _scroll: int = 0
var _scroll_clock: float = 0.0
var _tuning: float = 0.0
var _last_song: String = ""
var _bars: int = 4


func _ready() -> void:
	super()
	Radio.station_changed.connect(func() -> void:
		_tuning = TUNING_SECONDS
		_scroll = 0)


func hud_step(delta: float, numbers_due: bool) -> void:
	_tuning = maxf(_tuning - delta, 0.0)
	_scroll_clock += delta
	while _scroll_clock >= SCROLL_SECONDS:
		_scroll_clock -= SCROLL_SECONDS
		_scroll += 1
	var song := Radio.now_playing()
	if song != _last_song:
		_last_song = song
		_scroll = 0
	if numbers_due:
		_bars = signal_bars()


## How many of the four signal bars are lit.
func signal_bars() -> int:
	if not Radio.powered:
		return 0
	var strength := Radio.signal_strength
	var rig := ship()
	if rig != null:
		strength *= 1.0 - rig.storm * 0.8
	if hud.demo:
		strength = 0.5 + 0.5 * sin(hud.time * 1.3)
	var bars := ceili(strength * 4.0 - 0.01)
	# A storm makes the bars stutter.
	if (rig != null and rig.storm > 0.05 or hud.demo) and randf() < 0.3:
		bars -= 1
	return clampi(bars, 0, 4)


func _draw() -> void:
	if hud.comm != null and hud.comm.is_showing():
		return  # The comm call covers us.
	var station := Radio.station()
	var corner := Vector2(MARGIN, MARGIN)
	box(Rect2(corner - Vector2(2, 2), Vector2(WINDOW_LETTERS * 4 + 4, 18)), BACKING)
	# Signal bars.
	for i in 4:
		var bar_height := 2.0 + i
		box(Rect2(corner.x + i * 3.0, corner.y + 5.0 - bar_height, 2.0, bar_height), GREEN if i < _bars else tint(0.2))
	var tuning := _tuning > 0.0
	text(corner + Vector2(15, 0), ("%s %s" % [station.frequency, station.display_name]), YELLOW if tuning else tint(0.9 if Radio.powered else 0.35))
	var line_spot := corner + Vector2(0, 8)
	if not Radio.powered:
		text(line_spot, "RADIO OFF · R TO TURN ON", tint(0.5))
		return
	if tuning:
		var noise := ""
		for i in WINDOW_LETTERS:
			noise += STATIC_LETTERS[randi() % STATIC_LETTERS.length()] if randf() < 0.6 else " "
		text(line_spot, noise, tint(0.5))
		return
	var song := _last_song
	var is_ad := song.begins_with("AD:")
	var looped := ("" if is_ad else "♪ ") + song + "   ·   "
	var shown := ""
	for i in WINDOW_LETTERS:
		shown += looped[(_scroll + i) % looped.length()]
	text(line_spot, shown, YELLOW if is_ad else GREEN)
