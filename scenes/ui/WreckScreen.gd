class_name WreckScreen
extends CanvasLayer
## After the rig blows up: no card, the explosion stays on screen, and a
## small prompt at the bottom asks you to reload. Press any key (or click,
## or a gamepad button) and you're back at your last save, nothing lost.
##
## Use it with:
##     WreckScreen.show_and_restart(get_tree())


const FLIGHT_SCENE: String = "res://scenes/flight/FlightSandbox.tscn"
const PROMPT: String = "PRESS ANY KEY TO RELOAD YOUR LAST SAVE"

var _time: float = 0.0
var _going: bool = false
var _prompt: Control


## Shows the reload prompt; reloads the last save when a key is pressed.
static func show_and_restart(tree: SceneTree) -> void:
	tree.root.add_child(WreckScreen.new())


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_prompt = Control.new()
	_prompt.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.draw.connect(_draw_prompt)
	add_child(_prompt)


func _process(delta: float) -> void:
	_time += delta
	_prompt.queue_redraw()


func _input(event: InputEvent) -> void:
	# Any key or button (after a moment, so a held button doesn't skip it).
	if _time > 0.8 and event.is_pressed() and not event.is_echo() and not event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
		reload()


## Back to the last save: the room you were last in, with whatever you had
## then. No save yet (the flight sandbox)? Then just fly again.
func reload() -> void:
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


## The prompt: a small dark strip near the bottom, gently blinking.
func _draw_prompt() -> void:
	if _time < 0.8:
		return
	var screen := _prompt.size
	var square := maxf(2.0, floorf(screen.y / 240.0))
	var width := PixelFont.width(PROMPT, square) + square * 16.0
	var strip := Rect2(Vector2((screen.x - width) * 0.5, screen.y - square * 30.0), Vector2(width, square * 12.0))
	_prompt.draw_rect(strip, Color(0.03, 0.02, 0.06, 0.8))
	var alpha := 1.0 if fmod(_time, 1.0) < 0.7 else 0.55
	PixelFont.draw_centered(_prompt, strip.get_center(), PROMPT, square, Color(1.0, 0.9, 0.8, alpha))
