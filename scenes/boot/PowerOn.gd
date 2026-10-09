extends Control
## The power-on intro: the first thing you see when the game starts, under
## 10 seconds, skippable with any key or button.
##
## Like turning on an old computer or a 90s console: the screen warms up
## with a line, a BIOS-style self test types itself out in the top-left
## corner ("CHECKING SPACESHIP... OK!"), and then the logo arrives with our
## own power-on chime. Then it's on to the title screen (Boot.tscn).
##
## The words are in LINES below; each line types out its dots, then shows
## its result (OK!, or something less reassuring). Sounds are made from math
## (SfxSynth: power_on.wav and post_beep.wav in res://audio/generated/).


const NEXT_SCENE: String = "res://scenes/boot/Boot.tscn"
const CHIME := preload("res://audio/generated/power_on.wav")
const BEEP := preload("res://audio/generated/post_beep.wav")
const BLIP := preload("res://audio/generated/blip.wav")

## The self test: [what's checked, its result]. Results starting with "!"
## show in yellow.
const LINES: Array[Array] = [
	["CHECKING ROM", "OK!"],
	["CHECKING CPU", "OK!"],
	["CHECKING SPACESHIP", "OK!"],
	["CHECKING CARGO STRAPS", "OK!"],
	["CHECKING RADIO", "OK!"],
	["CHECKING SNACKS", "!LOW"],
	["CHECKING COFFEE", "OK!"],
	["CHECKING WILL TO LIVE", "!OK, I GUESS"],
]

# When things happen, in seconds.
const WARM_UP: float = 0.45  # The screen's line opens up.
const HEADER_AT: float = 0.5
const MEMORY_AT: float = 0.9
const MEMORY_SECONDS: float = 0.6
const FIRST_LINE_AT: float = 1.7
const LINE_SECONDS: float = 0.34
const LOGO_AT: float = 5.0
const FADE_AT: float = 8.4
const DONE_AT: float = 9.0

const GRAY := Color(0.78, 0.8, 0.86)
const GREEN := Color(0.4, 1.0, 0.45)
const YELLOW := Color(1.0, 0.85, 0.25)
const ORANGE := Color(1.0, 0.55, 0.3)
const TEAL := Color(0.4, 1.0, 0.85)

var _time: float = 0.0
var _player: AudioStreamPlayer
var _blips: AudioStreamPlayer
var _beeped: bool = false
var _chimed: bool = false
var _lines_shown: int = 0
var _leaving: bool = false
var _stars: Array[Vector3] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_blips = AudioStreamPlayer.new()
	_blips.stream = BLIP
	_blips.volume_db = -12.0
	add_child(_blips)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050
	for i in 140:
		# Each star: a direction (x, y) and a depth (z) for the warp effect.
		_stars.append(Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(0.05, 1.0)))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	_time += delta
	if not _beeped and _time >= HEADER_AT:
		_beeped = true
		_play(BEEP)
	var shown := clampi(floori((_time - FIRST_LINE_AT) / LINE_SECONDS) + 1, 0, LINES.size()) if _time < LOGO_AT else LINES.size()
	if shown > _lines_shown:
		_lines_shown = shown
		_blips.pitch_scale = 1.6
		_blips.play()
	if not _chimed and _time >= LOGO_AT:
		_chimed = true
		_play(CHIME)
	if _time >= DONE_AT and not _leaving:
		_leave()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Any key, click or button skips ahead to the end.
	var pressed := (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed()
	if pressed and _time < FADE_AT:
		_time = FADE_AT
		_chimed = true
		get_viewport().set_input_as_handled()


func _leave() -> void:
	_leaving = true
	get_tree().change_scene_to_file(NEXT_SCENE)


func _play(stream: AudioStream) -> void:
	_player.stream = stream
	_player.play()


func _draw() -> void:
	var screen := size
	draw_rect(Rect2(Vector2.ZERO, screen), Color.BLACK)
	# One "square" of the pixel font: about 1/240th of the screen height, so
	# it looks like an old 240-line display at any window size.
	var square := maxf(1.0, floorf(screen.y / 240.0))
	if _time < WARM_UP:
		_draw_warm_up(screen)
	elif _time < LOGO_AT:
		_draw_self_test(square)
	else:
		_draw_logo(screen, square)
	# Fade to black at the end.
	if _time > FADE_AT:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(0, 0, 0, clampf((_time - FADE_AT) / (DONE_AT - FADE_AT - 0.1), 0.0, 1.0)))
	# Faint scanlines over everything, like an old TV.
	for y in range(0, int(screen.y), int(square * 2.0)):
		draw_rect(Rect2(0.0, y, screen.x, maxf(1.0, square * 0.5)), Color(0, 0, 0, 0.25))


## The old-TV warm-up: a bright line in the middle that opens up.
func _draw_warm_up(screen: Vector2) -> void:
	var t := _time / WARM_UP
	var tall := screen.y * pow(t, 3.0)
	var wide := screen.x * minf(t * 3.0, 1.0)
	draw_rect(Rect2((screen.x - wide) * 0.5, (screen.y - tall) * 0.5 - 1.0, wide, tall + 2.0), Color(0.85, 0.9, 1.0, 1.0 - t * 0.7))


func _draw_self_test(square: float) -> void:
	var left := square * 8.0
	var row := square * 10.0
	var y := square * 8.0
	if _time >= HEADER_AT:
		PixelFont.draw(self, Vector2(left, y), "HAREWARE BIOS V50.50", square, ORANGE, 0.0, Color(0, 0, 0, 0))
		PixelFont.draw(self, Vector2(left, y + row), "(C) DISCOUNT ROCKETRY CO.", square, GRAY, 0.0, Color(0, 0, 0, 0))
		_draw_mascot(Vector2(size.x - square * 40.0, y), square)
	y += row * 3.0
	if _time >= MEMORY_AT:
		var counted := clampf((_time - MEMORY_AT) / MEMORY_SECONDS, 0.0, 1.0)
		var words := "MEMORY TEST: %dK" % (roundi(counted * 65536.0 / 64.0) * 64)
		if counted >= 1.0:
			words += " OK!"
		PixelFont.draw(self, Vector2(left, y), words, square, GRAY if counted < 1.0 else GREEN, 0.0, Color(0, 0, 0, 0))
	y += row * 2.0
	for i in LINES.size():
		var start := FIRST_LINE_AT + i * LINE_SECONDS
		if _time < start:
			break
		var line: Array = LINES[i]
		var label: String = line[0]
		var result: String = line[1]
		# The dots type out, then the result pops in.
		var dots := clampi(floori((_time - start) / LINE_SECONDS * 14.0), 0, 10)
		PixelFont.draw(self, Vector2(left, y), label + ".".repeat(dots), square, GRAY, 0.0, Color(0, 0, 0, 0))
		if dots >= 10:
			var warn := result.begins_with("!")
			var at := left + PixelFont.width(label + "..........", square) + square * 3.0
			PixelFont.draw(self, Vector2(at, y), result.trim_prefix("!"), square, YELLOW if warn else GREEN, 0.0, Color(0, 0, 0, 0))
		y += row
	var all_done := FIRST_LINE_AT + LINES.size() * LINE_SECONDS + 0.2
	if _time >= all_done:
		PixelFont.draw(self, Vector2(left, y + row), "ALL SYSTEMS GO. HAVE A NICE HAUL.", square, TEAL, 0.0, Color(0, 0, 0, 0))
		# A blinking cursor.
		if fposmod(_time, 0.5) < 0.25:
			draw_rect(Rect2(left, y + row * 2.0, square * 5.0, square * 7.0), GRAY)


## A tiny pixel bunny head in the corner, like a BIOS maker's logo.
func _draw_mascot(corner: Vector2, square: float) -> void:
	var fur := Color(0.95, 0.9, 0.85)
	var rects: Array[Rect2] = [
		Rect2(2, 0, 2, 7), Rect2(8, 0, 2, 7),  # Ears.
		Rect2(1, 6, 10, 8),  # Head.
	]
	for part in rects:
		draw_rect(Rect2(corner + part.position * square, part.size * square), fur)
	draw_rect(Rect2(corner + Vector2(3, 9) * square, Vector2(2, 1) * square), Color.BLACK)  # Sleepy eyes.
	draw_rect(Rect2(corner + Vector2(7, 9) * square, Vector2(2, 1) * square), Color.BLACK)
	draw_rect(Rect2(corner + Vector2(5, 12) * square, Vector2(2, 2) * square), Color.WHITE)  # Buck teeth.


## The logo: stars warping past, the title punching in, a flash.
func _draw_logo(screen: Vector2, square: float) -> void:
	var t := _time - LOGO_AT
	var center := screen * 0.5
	# Warp stars: rushing outward, slowing down as the logo settles.
	var speed := 2.5 * exp(-t * 1.2) + 0.08
	for star in _stars:
		var depth := fposmod(star.z - t * speed, 1.0) + 0.02
		var spot := center + Vector2(star.x, star.y) * screen * 0.5 / depth * 0.25
		var trail := Vector2(star.x, star.y).normalized() * minf(speed * 40.0 / depth, 80.0)
		var brightness := clampf(1.2 - depth, 0.2, 1.0)
		draw_line(spot, spot - trail, Color(1, 1, 1, brightness), maxf(1.0, square * 0.5))
	# The title slams in a little big, then settles.
	var settle := 1.0 + 0.6 * exp(-t * 7.0)
	var big := square * 5.0 * settle
	PixelFont.draw_centered(self, center - Vector2(0.0, square * 40.0), "SPACE TRUCKIN'", big, ORANGE, 0.22)
	if t > 0.35:
		PixelFont.draw_centered(self, center + Vector2(0.0, square * 14.0), "5050", square * 8.0, YELLOW, 0.22)
	if t > 1.2:
		PixelFont.draw_centered(self, center + Vector2(0.0, square * 60.0), "A COZY SPACE TRUCKING SIM", square * 1.5, TEAL)
	# A white flash as the chime hits.
	if t < 0.3:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(1, 1, 1, 0.8 * (1.0 - t / 0.3)))
