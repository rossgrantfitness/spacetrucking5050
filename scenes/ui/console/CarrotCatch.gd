class_name CarrotCatch
extends RefCounted
## CARROT CATCH, a game on Jacki's TV console (TVConsole.gd): slide the
## basket left and right to catch falling carrots (golden ones are worth
## more) and dodge the bits of space junk. Three junk hits and it's over.
## Things fall faster the longer you last.
##
## Just the rules (so the tests can play it); TVConsole.gd draws it and
## passes the controls in. Sizes are in the TV screen's own pixels.


enum State { TITLE, PLAYING, OVER }

const WIDTH: float = 160.0
const HEIGHT: float = 120.0
const BASKET_Y: float = 108.0
const BASKET_HALF: float = 10.0
## How fast the basket slides (screen pixels per second).
const BASKET_SPEED: float = 120.0
const START_FALL: float = 35.0
const TOP_FALL: float = 110.0
const LIVES: int = 3

var state: State = State.TITLE
var basket_x: float = WIDTH * 0.5
var score: int = 0
var lives: int = LIVES
## Each falling thing: {"x": float, "y": float, "kind": "carrot", "gold" or "junk"}.
var things: Array[Dictionary] = []

var _fall: float = START_FALL
var _spawn_in: float = 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func start() -> void:
	state = State.PLAYING
	basket_x = WIDTH * 0.5
	score = 0
	lives = LIVES
	things.clear()
	_fall = START_FALL
	_spawn_in = 0.5


## `slide` is -1 (left) to 1 (right). Returns "catch", "gold", "junk" or ""
## for what just happened (for a sound).
func step(delta: float, slide: float) -> String:
	if state != State.PLAYING:
		return ""
	basket_x = clampf(basket_x + slide * BASKET_SPEED * delta, BASKET_HALF, WIDTH - BASKET_HALF)
	_fall = minf(_fall + 1.5 * delta, TOP_FALL)
	_spawn_in -= delta
	if _spawn_in <= 0.0:
		var roll := _rng.randf()
		var kind := "gold" if roll < 0.08 else ("junk" if roll < 0.38 else "carrot")
		things.append({"x": _rng.randf_range(8.0, WIDTH - 8.0), "y": -6.0, "kind": kind})
		_spawn_in = _rng.randf_range(0.4, 0.9) * START_FALL / _fall + 0.15
	var happened := ""
	for i in range(things.size() - 1, -1, -1):
		var thing := things[i]
		thing["y"] = float(thing["y"]) + _fall * delta
		var y: float = thing["y"]
		if absf(y - BASKET_Y) < 5.0 and absf(float(thing["x"]) - basket_x) < BASKET_HALF + 3.0:
			match thing["kind"]:
				"junk":
					lives -= 1
					happened = "junk"
					if lives <= 0:
						state = State.OVER
				"gold":
					score += 5
					happened = "gold"
				_:
					score += 1
					happened = "catch"
			things.remove_at(i)
		elif y > HEIGHT + 6.0:
			things.remove_at(i)
	return happened
