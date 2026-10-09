class_name TVConsole
extends CanvasLayer
## Jacki's old games console, hooked up to the TV in her apartment: the
## TATER-16. It fills the screen like you're sat on the floor in front of
## the TV. Pick a game cartridge:
## - CARROT CATCH (CarrotCatch.gd): catch carrots, dodge space junk.
## - COMET TAIL (CometTail.gd): a comet that grows as it eats stars.
## - PADDLE PODS (PaddlePods.gd): pong against Chang Ma.
## Each one's best score is saved (GameState.console_scores).
##
## Keys: arrows / D-pad / stick to move, E / Enter / A to start, Esc / B to
## go back (from the game list, it switches the console off).
##
## Use it with:
##     await TVConsole.open(get_tree())


signal closed

enum Screen { BOOT, MENU, GAME, OFF }

## The TV picture's size in its own pixels (the games are 160 x 120).
const PICTURE := Vector2(160.0, 120.0)
const GAMES: Array = [
	["CARROT CATCH", "carrot_catch", "SLIDE TO CATCH. DODGE THE JUNK."],
	["COMET TAIL", "comet_tail", "EAT STARS. DON'T BITE YOUR TAIL."],
	["PADDLE PODS", "paddle_pods", "BEAT CHANG MA. FIRST TO 5."],
]
const SMALL := PixelFont.Face.SMALL
const NO_SHADOW := Color(0, 0, 0, 0)

var _screen: Screen = Screen.BOOT
var _pick: int = 0
var _game: RefCounted
var _game_id: String = ""
var _canvas: Control
var _clock: float = 0.0
var _beep: AudioStreamPlayer


## Switches the console on and waits until she switches it off.
static func open(tree: SceneTree) -> void:
	var console := TVConsole.new()
	tree.root.add_child(console)
	await console.closed
	console.queue_free()


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_tv)
	add_child(_canvas)
	_beep = AudioStreamPlayer.new()
	_beep.stream = preload("res://audio/generated/post_beep.wav")
	_beep.bus = Settings.SFX_BUS
	_beep.volume_db = -10.0
	add_child(_beep)


func _process(delta: float) -> void:
	_clock += delta
	match _screen:
		Screen.BOOT:
			if _clock > 1.6:
				_screen = Screen.MENU
		Screen.OFF:
			if _clock > 0.45:
				closed.emit()
		Screen.GAME:
			_step_game(delta)
	_canvas.queue_redraw()


## Plays the game a frame on: held keys for sliding paddles and baskets.
func _step_game(delta: float) -> void:
	var across := Input.get_axis("ui_left", "ui_right") + Input.get_axis("move_left", "move_right")
	var updown := Input.get_axis("ui_up", "ui_down") + Input.get_axis("move_forward", "move_back")
	var happened := ""
	if _game is CarrotCatch:
		happened = (_game as CarrotCatch).step(delta, clampf(across, -1.0, 1.0))
	elif _game is CometTail:
		happened = (_game as CometTail).step(delta)
	elif _game is PaddlePods:
		happened = (_game as PaddlePods).step(delta, clampf(updown, -1.0, 1.0))
	if not happened.is_empty():
		_beep.pitch_scale = {"junk": 0.5, "crash": 0.45, "miss": 0.6, "gold": 1.6, "star": 1.3, "point": 1.4}.get(happened, 1.0)
		_beep.play()
	var score := int(_game.get("score"))
	if score > int(GameState.console_scores.get(_game_id, 0)):
		GameState.console_scores[_game_id] = score


func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or event is InputEventMouse:
		return
	get_viewport().set_input_as_handled()
	var back := event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")
	var go := event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")
	var up := event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward")
	var down := event.is_action_pressed("ui_down") or event.is_action_pressed("move_back")
	var left := event.is_action_pressed("ui_left") or event.is_action_pressed("move_left")
	var right := event.is_action_pressed("ui_right") or event.is_action_pressed("move_right")
	match _screen:
		Screen.MENU:
			if up:
				_pick = posmod(_pick - 1, GAMES.size())
			elif down:
				_pick = posmod(_pick + 1, GAMES.size())
			elif go:
				_load_game(_pick)
			elif back:
				_screen = Screen.OFF
				_clock = 0.0
		Screen.GAME:
			var state := int(_game.get("state"))
			if back:
				_screen = Screen.MENU  # Out to the cartridge list.
			elif state != 1 and go:
				_game.call("start")  # (1 = playing in every game's State.)
			elif _game is CometTail:
				var comet := _game as CometTail
				if up:
					comet.turn(Vector2i.UP)
				elif down:
					comet.turn(Vector2i.DOWN)
				elif left:
					comet.turn(Vector2i.LEFT)
				elif right:
					comet.turn(Vector2i.RIGHT)


func _load_game(index: int) -> void:
	_game_id = GAMES[index][1]
	match _game_id:
		"carrot_catch":
			_game = CarrotCatch.new()
		"comet_tail":
			_game = CometTail.new()
		_:
			_game = PaddlePods.new()
	_screen = Screen.GAME
	Sfx.play("ui_confirm")


# --- Drawing -------------------------------------------------------------------------

func _draw_tv() -> void:
	var size := _canvas.size
	# The room, dim, and a chunky old TV set.
	_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color("15121c"))
	var zoom := maxf(1.0, floorf(minf(size.x / (PICTURE.x + 40.0), size.y / (PICTURE.y + 44.0))))
	var corner := ((size - PICTURE * zoom) * 0.5).floor() - Vector2(0.0, 6.0 * zoom)
	var cabinet := Rect2(corner - Vector2(16.0, 12.0) * zoom, (PICTURE + Vector2(44.0, 34.0)) * zoom)
	_canvas.draw_rect(cabinet, Color("4a3a32"))
	_canvas.draw_rect(Rect2(cabinet.position, Vector2(cabinet.size.x, 2.0 * zoom)), Color("6b5547"))
	# The knobs on the right, and the console's name on the front.
	for knob in 2:
		_canvas.draw_rect(Rect2(corner + Vector2(PICTURE.x + 8.0, 14.0 + knob * 18.0) * zoom, Vector2(10.0, 10.0) * zoom), Color("2a2224"))
	PixelFont.draw(_canvas, corner + Vector2(0.0, PICTURE.y + 6.0) * zoom, "TATER-16", zoom, Color("c9a86b"), 0.0, NO_SHADOW, SMALL)
	_canvas.draw_rect(Rect2(corner - Vector2(3.0, 3.0) * zoom, (PICTURE + Vector2(6.0, 6.0)) * zoom), Color("120f14"))

	# The picture, in the TV's own pixels.
	_canvas.draw_set_transform(corner, 0.0, Vector2(zoom, zoom))
	_canvas.draw_rect(Rect2(Vector2.ZERO, PICTURE), Color("0d1020"))
	match _screen:
		Screen.BOOT:
			_draw_boot()
		Screen.MENU:
			_draw_menu()
		Screen.GAME:
			if _game is CarrotCatch:
				_draw_carrot_catch(_game as CarrotCatch)
			elif _game is CometTail:
				_draw_comet_tail(_game as CometTail)
			elif _game is PaddlePods:
				_draw_paddle_pods(_game as PaddlePods)
			_draw_title_or_over()
		Screen.OFF:
			# Switching off: the picture squashes to a line, then a dot.
			var squash := clampf(_clock / 0.35, 0.0, 1.0)
			_canvas.draw_rect(Rect2(Vector2.ZERO, PICTURE), Color.BLACK)
			_canvas.draw_rect(Rect2(PICTURE.x * 0.5 * squash, PICTURE.y * 0.5 - 1.0, PICTURE.x * (1.0 - squash), 2.0), Color(0.8, 0.9, 1.0))
	# CRT scanlines.
	for y in range(0, int(PICTURE.y), 2):
		_canvas.draw_rect(Rect2(0.0, y, PICTURE.x, 1.0), Color(0, 0, 0, 0.18))
	_canvas.draw_set_transform(Vector2.ZERO)


func _text(where: Vector2, words: String, color: Color) -> void:
	PixelFont.draw(_canvas, where, words, 1.0, color, 0.0, NO_SHADOW, SMALL)


func _centered(y: float, words: String, color: Color, square: float = 1.0) -> void:
	PixelFont.draw_centered(_canvas, Vector2(PICTURE.x * 0.5, y), words, square, color, 0.0, NO_SHADOW, SMALL)


func _draw_boot() -> void:
	var drop := minf(_clock / 0.8, 1.0)
	_centered(20.0 + 30.0 * drop, "TATER-16", Color(1.0, 0.8, 0.35), 2.0)
	if _clock > 0.9:
		_centered(80.0, "LICENSED BY NOBODY", Color(0.6, 0.6, 0.7))


func _draw_menu() -> void:
	_centered(10.0, "PICK A GAME", Color(1.0, 0.8, 0.35))
	for i in GAMES.size():
		var y := 30.0 + i * 22.0
		var picked := i == _pick
		if picked:
			_canvas.draw_rect(Rect2(8.0, y - 3.0, PICTURE.x - 16.0, 18.0), Color(0.2, 0.25, 0.55))
		_text(Vector2(14.0, y), GAMES[i][0], Color.WHITE if picked else Color(0.65, 0.68, 0.8))
		_text(Vector2(14.0, y + 8.0), "BEST %d" % int(GameState.console_scores.get(GAMES[i][1], 0)), Color(0.5, 0.9, 0.6) if picked else Color(0.4, 0.45, 0.55))
	_centered(100.0, GAMES[_pick][2], Color(0.75, 0.75, 0.85))
	_centered(110.0, "E: PLAY   ESC: OFF", Color(0.5, 0.5, 0.6))


## The start prompt and the game-over card, the same for every game.
func _draw_title_or_over() -> void:
	var state := int(_game.get("state"))
	if state == 1:
		if not _game is PaddlePods:  # (Pong shows its own scoreboard.)
			_text(Vector2(3.0, 3.0), "%d" % int(_game.get("score")), Color.WHITE)
		return
	_canvas.draw_rect(Rect2(20.0, 40.0, PICTURE.x - 40.0, 40.0), Color(0.05, 0.05, 0.12, 0.9))
	var title: String = GAMES[_pick][0]
	if state == 2:
		var won: bool = _game is PaddlePods and (_game as PaddlePods).you_won
		title = "YOU BEAT CHANG MA!" if won else "GAME OVER"
		_centered(58.0, "SCORE %d   BEST %d" % [int(_game.get("score")), int(GameState.console_scores.get(_game_id, 0))], Color(0.5, 0.9, 0.6))
	_centered(46.0, title, Color(1.0, 0.8, 0.35))
	if fposmod(_clock, 1.0) < 0.6:
		_centered(70.0, "PRESS E", Color.WHITE)


func _draw_carrot_catch(game: CarrotCatch) -> void:
	_canvas.draw_rect(Rect2(0.0, CarrotCatch.BASKET_Y + 5.0, PICTURE.x, 10.0), Color(0.2, 0.4, 0.25))
	for thing in game.things:
		var spot := Vector2(float(thing["x"]), float(thing["y"])).round()
		if spot.y > PICTURE.y - 4.0:
			continue  # Fallen off the bottom of the screen.
		match thing["kind"]:
			"junk":
				_canvas.draw_rect(Rect2(spot - Vector2(3, 3), Vector2(6, 6)), Color(0.55, 0.55, 0.6))
				_canvas.draw_rect(Rect2(spot - Vector2(1, 3), Vector2(2, 6)), Color(0.3, 0.3, 0.35))
			_:
				var orange := Color(1.0, 0.85, 0.2) if thing["kind"] == "gold" else Color(1.0, 0.5, 0.15)
				_canvas.draw_rect(Rect2(spot + Vector2(-1, -3), Vector2(3, 7)), orange)
				_canvas.draw_rect(Rect2(spot + Vector2(-1, -6), Vector2(3, 3)), Color(0.3, 0.85, 0.35))
	var basket := Rect2(game.basket_x - CarrotCatch.BASKET_HALF, CarrotCatch.BASKET_Y - 3.0, CarrotCatch.BASKET_HALF * 2.0, 7.0)
	_canvas.draw_rect(basket, Color(0.75, 0.55, 0.3))
	_canvas.draw_rect(Rect2(basket.position, Vector2(basket.size.x, 1.0)), Color(0.95, 0.75, 0.45))
	for i in game.lives:
		_canvas.draw_rect(Rect2(PICTURE.x - 8.0 - i * 7.0, 3.0, 5.0, 5.0), Color(1.0, 0.4, 0.5))


func _draw_comet_tail(game: CometTail) -> void:
	var cell := Vector2(PICTURE.x / CometTail.COLUMNS, PICTURE.y / CometTail.ROWS)
	# The star: blinks.
	var star_color := Color(1.0, 0.95, 0.5) if fposmod(_clock, 0.4) < 0.25 else Color(1.0, 0.75, 0.3)
	_canvas.draw_rect(Rect2(Vector2(game.star) * cell + Vector2(2, 2), cell - Vector2(4, 4)), star_color)
	for i in game.body.size():
		# The head is white-hot; the tail cools to blue as it goes.
		var heat := 1.0 - float(i) / maxf(game.body.size(), 1.0)
		var color := Color(0.4, 0.6, 1.0).lerp(Color(1.0, 1.0, 0.95), heat)
		_canvas.draw_rect(Rect2(Vector2(game.body[i]) * cell + Vector2(1, 1), cell - Vector2(2, 2)), color)
	_canvas.draw_rect(Rect2(Vector2.ZERO, PICTURE), Color(0.35, 0.4, 0.7), false, 1.0)


func _draw_paddle_pods(game: PaddlePods) -> void:
	for y in range(0, int(PICTURE.y), 8):
		_canvas.draw_rect(Rect2(PICTURE.x * 0.5 - 0.5, y, 1.0, 4.0), Color(0.3, 0.3, 0.45))
	_canvas.draw_rect(Rect2(3.0, game.you_y - PaddlePods.PADDLE_HALF, 3.0, PaddlePods.PADDLE_HALF * 2.0), Color(1.0, 0.6, 0.3))
	_canvas.draw_rect(Rect2(PICTURE.x - 6.0, game.cpu_y - PaddlePods.PADDLE_HALF, 3.0, PaddlePods.PADDLE_HALF * 2.0), Color(0.6, 0.45, 0.4))
	if game.ball.x > 2.0 and game.ball.x < PICTURE.x - 2.0:  # (Off the edge: gone.)
		_canvas.draw_rect(Rect2(game.ball.round() - Vector2(2, 2), Vector2(4, 4)), Color(0.5, 1.0, 0.9))
	_centered(3.0, "JACKI %d   CHANG MA %d" % [game.you, game.cpu], Color(0.75, 0.75, 0.9))
