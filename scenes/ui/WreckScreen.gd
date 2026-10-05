class_name WreckScreen
extends CanvasLayer
## The card after the rig blows up: WRECKED, one of Jack's deadpan
## one-liners (res://data/dialogue/wreck_lines.tres), and then straight back
## to your last save, nothing lost. Any key skips the wait.
##
## Use it with:
##     WreckScreen.show_and_restart(get_tree())


const LINES: LineList = preload("res://data/dialogue/wreck_lines.tres")
const FLIGHT_SCENE: String = "res://scenes/flight/FlightSandbox.tscn"

var _time: float = 0.0
var _going: bool = false
var _line: String = ""
var _card: Control


## Shows the card, then reloads the last save.
static func show_and_restart(tree: SceneTree) -> void:
	tree.root.add_child(WreckScreen.new())


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_line = LINES.pick(rng)
	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.draw.connect(_draw_card)
	add_child(_card)


func _process(delta: float) -> void:
	_time += delta
	_card.queue_redraw()
	if _time > GameState.tuning.wreck_card_seconds:
		_restart()


func _input(event: InputEvent) -> void:
	# Any key or button (after a moment, so a held button doesn't skip it).
	if _time > 0.8 and event.is_pressed() and not event.is_echo() and not event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
		_restart()


## Back to the last save: the room you were last in, with whatever you had
## then. No save yet (the flight sandbox)? Then just fly again.
func _restart() -> void:
	if _going:
		return
	_going = true
	Engine.time_scale = 1.0
	get_tree().paused = false
	var tree := get_tree()
	if GameState.load_game() and not GameState.current_room.is_empty():
		LoadingScreen.go(tree, GameState.current_room, "start")
	else:
		LoadingScreen.go(tree, FLIGHT_SCENE, "flight")
	queue_free()


func _draw_card() -> void:
	var screen := _card.size
	var fade := clampf(_time / 0.6, 0.0, 1.0)
	_card.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.12, 0.0, 0.03, 0.82 * fade))
	if _time < 0.5:
		return
	var font := ThemeDB.fallback_font if _card.get_theme_default_font() == null else _card.get_theme_default_font()
	var middle := screen * 0.5
	var blink := 1.0 if fmod(_time, 0.8) < 0.55 else 0.55
	_card.draw_string(font, Vector2(0.0, middle.y - 40.0), "WRECKED", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 64, Color(1.0, 0.3, 0.3, blink))
	_card.draw_string(font, Vector2(0.0, middle.y + 30.0), GameState.names.bunny_name.to_upper() + ": " + _line.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, screen.x, 24, Color(1.0, 0.9, 0.8))
	var left := maxi(ceili(GameState.tuning.wreck_card_seconds - _time), 0)
	_card.draw_string(font, Vector2(0.0, middle.y + 90.0), "BACK TO YOUR LAST SAVE IN %d... NOTHING LOST.  (ANY KEY)" % left,
			HORIZONTAL_ALIGNMENT_CENTER, screen.x, 16, Color(1.0, 1.0, 1.0, 0.7))
