class_name CommPortrait
extends HudWidget
## Star Fox 64-style comm calls. Somebody calls: a burst of radio static,
## the box slides in over the radio ticker in a few chunky steps, their
## portrait flaps its mouth while the words type out with gibberish voice
## blips, then another burst of static and it slides away.
##
## Long lines flip over to a second card. CommChatter.gd decides who calls
## and when; this just shows the call. Calls stay up even when the player
## hides the rest of the HUD.


## Emitted when a call has finished and slid away.
signal finished

enum State { IDLE, STATIC_IN, TYPING, HOLDING, STATIC_OUT, LEAVING }

const STATIC_SOUND := preload("res://audio/generated/static.wav")
const BLIP_SOUND := preload("res://audio/generated/blip.wav")
const MAX_WIDTH: float = 180.0
const HEIGHT: float = 38.0
const STATIC_SECONDS: float = 0.3
## Text lines that fit on one card.
const LINES_PER_CARD: int = 3

var _state: State = State.IDLE
var _pop := HudWidget.Pop.new()
var _clock: float = 0.0
var _speaker: NPCData
var _cards: Array[PackedStringArray] = []
var _card: int = 0
var _letters: float = 0.0
var _letters_since_blip: int = 0
var _mouth_open: bool = false
var _blinking: bool = false
var _static_player: AudioStreamPlayer
var _blip_player: AudioStreamPlayer


func _init() -> void:
	always_shown = true


func _ready() -> void:
	super()
	_static_player = AudioStreamPlayer.new()
	_static_player.stream = STATIC_SOUND
	_static_player.volume_db = -10.0
	add_child(_static_player)
	_blip_player = AudioStreamPlayer.new()
	_blip_player.stream = BLIP_SOUND
	_blip_player.max_polyphony = 3
	add_child(_blip_player)


## Starts a call from `speaker` saying `words` (names like {bunny} are filled
## in). Ignored if a call is already up; check is_busy() first.
func call_in(speaker: NPCData, words: String) -> void:
	if is_busy():
		return
	_speaker = speaker
	var text_width_available := _box_width() - 36.0
	var lines := PixelFont.wrap(GameState.names.fill_in(words).to_upper(), text_width_available, 1.0)
	_cards.clear()
	for start in range(0, lines.size(), LINES_PER_CARD):
		_cards.append(lines.slice(start, start + LINES_PER_CARD))
	_card = 0
	_letters = 0.0
	_set_state(State.STATIC_IN)
	_static_player.play()


func is_busy() -> bool:
	return _state != State.IDLE


## Whether the box is on screen (the radio ticker hides under it).
func is_showing() -> bool:
	return _pop.shown()


func hud_step(delta: float, _numbers_due: bool) -> void:
	var tuning := GameState.tuning
	_clock += delta
	_pop.want = _state in [State.STATIC_IN, State.TYPING, State.HOLDING, State.STATIC_OUT]
	_pop.update(delta)
	_blinking = fposmod(hud.time, 3.7) < 0.15
	match _state:
		State.STATIC_IN:
			if _clock >= STATIC_SECONDS:
				_set_state(State.TYPING)
		State.TYPING:
			var before := int(_letters)
			_letters += delta * tuning.comm_letters_per_second
			var total := _card_letters()
			for i in range(before, mini(int(_letters), total)):
				_maybe_blip(i)
			if int(_letters) >= total:
				_mouth_open = false
				_set_state(State.HOLDING)
		State.HOLDING:
			var hold := tuning.comm_hold_seconds if _card == _cards.size() - 1 else tuning.comm_hold_seconds * 0.6
			if _clock >= hold:
				if _card < _cards.size() - 1:
					_card += 1
					_letters = 0.0
					_set_state(State.TYPING)
				else:
					_set_state(State.STATIC_OUT)
					_static_player.play()
		State.STATIC_OUT:
			if _clock >= STATIC_SECONDS:
				_set_state(State.LEAVING)
		State.LEAVING:
			if not _pop.shown():
				_set_state(State.IDLE)
				finished.emit()


func _set_state(state: State) -> void:
	_state = state
	_clock = 0.0


## A blip every other letter at the speaker's pitch, and the mouth flaps.
func _maybe_blip(index: int) -> void:
	var letter := _card_text().substr(index, 1)
	if letter == " " or letter == "." or letter == ",":
		_mouth_open = false
		return
	_letters_since_blip += 1
	if _letters_since_blip < 2:
		return
	_letters_since_blip = 0
	_mouth_open = not _mouth_open
	_blip_player.pitch_scale = _speaker.voice_pitch * randf_range(0.88, 1.15)
	_blip_player.play()


func _card_text() -> String:
	return " ".join(_cards[_card]) if _card < _cards.size() else ""


func _card_letters() -> int:
	return _card_text().length()


func _box_width() -> float:
	return minf(MAX_WIDTH, floorf(size.x * 0.5) - 72.0)


func _draw() -> void:
	if not _pop.shown() or _speaker == null:
		return
	var width := _box_width()
	var corner := Vector2(MARGIN - roundf(_pop.hidden_share() * (width + MARGIN)), MARGIN)
	panel(Rect2(corner - Vector2(2, 2), Vector2(width + 4.0, HEIGHT)))
	# The portrait in its little frame.
	var portrait := corner + Vector2(1, 1)
	box(Rect2(portrait, Vector2(28, 28)), Color(0.03, 0.05, 0.08))
	var crackling := _state in [State.STATIC_IN, State.STATIC_OUT]
	if not crackling:
		PortraitPainter.paint(self, portrait, _speaker, _mouth_open and _state == State.TYPING, _blinking)
	# Scanlines over the portrait, for that video-call-from-1999 look.
	for y in range(0, 28, 2):
		box(Rect2(portrait + Vector2(0, y), Vector2(28, 1)), Color(0, 0, 0, 0.25))
	if crackling:
		for i in 90:
			box(Rect2(portrait + Vector2(randi() % 28, randi() % 28), Vector2(randi() % 3 + 1, 1)), tint(randf_range(0.2, 0.9)))
	outline(Rect2(portrait - Vector2.ONE, Vector2(30, 30)), tint(0.8))
	# Name plate and the words, typed out so far.
	var words_left := corner.x + 33.0
	var name_text := _speaker.comm_name if not _speaker.comm_name.is_empty() else _speaker.display_name
	text(Vector2(words_left, corner.y + 1.0), name_text.to_upper(), YELLOW)
	if crackling:
		text(Vector2(words_left, corner.y + 10.0), "..." if blink(0.3) else "", tint(0.6), BIG)
		return
	var shown := int(_letters) if _state == State.TYPING else _card_letters()
	var y := corner.y + 9.0
	var used := 0
	if _card >= _cards.size():
		return
	for text_line in _cards[_card]:
		var part := text_line.substr(0, clampi(shown - used, 0, text_line.length()))
		text(Vector2(words_left, y), part, GREEN, BIG)
		used += text_line.length() + 1
		y += 9.0
	# "More" arrow when another card follows.
	if _state == State.HOLDING and _card < _cards.size() - 1 and blink(0.4):
		pixels(Vector2(corner.x + width - 6.0, corner.y + HEIGHT - 8.0), ["###", ".#."], YELLOW)
