class_name CometTail
extends RefCounted
## COMET TAIL, a game on Jacki's TV console (TVConsole.gd): steer a little
## comet around the screen eating stars. Every star makes its tail longer
## and it speeds up a bit. Hit the edge or your own tail and it's over.
## (A snake game, with more sparkle.)
##
## Just the rules; TVConsole.gd draws it. The playfield is a grid of cells.


enum State { TITLE, PLAYING, OVER }

const COLUMNS: int = 20
const ROWS: int = 15
## Seconds per step at the start, and the quickest it gets.
const START_STEP: float = 0.16
const FASTEST_STEP: float = 0.07

var state: State = State.TITLE
## The comet, head first: grid cells.
var body: Array[Vector2i] = []
var star: Vector2i = Vector2i.ZERO
var score: int = 0

var _heading := Vector2i.RIGHT
var _next_heading := Vector2i.RIGHT
var _step_time: float = START_STEP
var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func start() -> void:
	state = State.PLAYING
	body = [Vector2i(6, 7), Vector2i(5, 7), Vector2i(4, 7)]
	_heading = Vector2i.RIGHT
	_next_heading = Vector2i.RIGHT
	_step_time = START_STEP
	_clock = 0.0
	score = 0
	_place_star()


## Turns the comet (it can't turn straight back on itself).
func turn(direction: Vector2i) -> void:
	if direction != -_heading and direction != Vector2i.ZERO:
		_next_heading = direction


## Returns "star" or "crash" when that just happened, otherwise "".
func step(delta: float) -> String:
	if state != State.PLAYING:
		return ""
	_clock += delta
	if _clock < _step_time:
		return ""
	_clock -= _step_time
	_heading = _next_heading
	var head: Vector2i = body[0] + _heading
	var grows := head == star
	var tail_moves_away := body.slice(0, body.size() - (0 if grows else 1))
	if head.x < 0 or head.y < 0 or head.x >= COLUMNS or head.y >= ROWS or head in tail_moves_away:
		state = State.OVER
		return "crash"
	body.push_front(head)
	if grows:
		score += 1
		_step_time = maxf(_step_time * 0.95, FASTEST_STEP)
		_place_star()
		return "star"
	body.pop_back()
	return ""


func _place_star() -> void:
	for attempt in 200:
		var spot := Vector2i(_rng.randi_range(0, COLUMNS - 1), _rng.randi_range(0, ROWS - 1))
		if not spot in body:
			star = spot
			return
