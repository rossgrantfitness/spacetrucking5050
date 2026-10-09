class_name AsteroidAlley
extends RefCounted
## ASTEROID ALLEY, the little game on her PC: a tiny rig in three lanes,
## rocks tumbling down at it, fuel cans to grab. Hop lanes to dodge. It
## gets faster the longer you last. One bonk and it's over (it's a PC game
## inside a cozy game; nothing's lost but the score).
##
## This is just the rules (so the tests can play it); DesktopPC.gd draws it
## and passes the keys in. Everything is in the PC screen's own little
## pixels: the playfield is WIDTH x HEIGHT.


enum State { TITLE, PLAYING, OVER }

const WIDTH: float = 120.0
const HEIGHT: float = 150.0
const LANES: int = 3
## Where the rig sits (its middle), from the top.
const RIG_Y: float = 128.0
## How fast things come at you at the start, and the fastest it gets
## (playfield pixels per second), and how much faster each second.
const START_SPEED: float = 55.0
const TOP_SPEED: float = 190.0
const SPEEDUP: float = 3.5
## Points for a fuel can.
const CAN_POINTS: int = 25

var state: State = State.TITLE
var lane: int = 1
## Where the rig is drawn across (it slides between lanes).
var rig_x: float = 0.0
var speed: float = START_SPEED
var score: int = 0
## Each thing coming down: {"lane": int, "y": float, "kind": "rock" or "can"}.
var things: Array[Dictionary] = []
## Scrolling stars for the feeling of speed: Vector2s.
var stars: Array[Vector2] = []

var _distance: float = 0.0
var _cans: int = 0
var _spawn_in: float = 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()
	for i in 24:
		stars.append(Vector2(_rng.randf_range(0.0, WIDTH), _rng.randf_range(0.0, HEIGHT)))
	rig_x = lane_x(lane)


## The middle of a lane, across the playfield.
static func lane_x(which: int) -> float:
	return WIDTH * (which + 0.5) / LANES


func start() -> void:
	state = State.PLAYING
	lane = 1
	rig_x = lane_x(lane)
	speed = START_SPEED
	score = 0
	things.clear()
	_distance = 0.0
	_cans = 0
	_spawn_in = 0.6


## Hop one lane left (-1) or right (+1).
func steer(direction: int) -> void:
	if state == State.PLAYING:
		lane = clampi(lane + direction, 0, LANES - 1)


## Moves everything along by `delta` seconds. Returns "bonk" or "can" when
## that just happened (for a sound), otherwise "".
func step(delta: float) -> String:
	for i in stars.size():
		stars[i].y = fposmod(stars[i].y + speed * 0.5 * delta * (1.0 + (i % 3)), HEIGHT)
	rig_x = lerpf(rig_x, lane_x(lane), 1.0 - exp(-18.0 * delta))
	if state != State.PLAYING:
		return ""
	speed = minf(speed + SPEEDUP * delta, TOP_SPEED)
	_distance += speed * delta
	score = int(_distance / 10.0) + _cans * CAN_POINTS
	_spawn_in -= delta
	if _spawn_in <= 0.0:
		_spawn()
		_spawn_in = _rng.randf_range(0.45, 0.9) * START_SPEED / speed + 0.18
	var happened := ""
	for thing in things:
		thing["y"] = float(thing["y"]) + speed * delta
	for i in range(things.size() - 1, -1, -1):
		var thing := things[i]
		var y: float = thing["y"]
		if int(thing["lane"]) == lane and absf(y - RIG_Y) < 9.0:
			if thing["kind"] == "rock":
				state = State.OVER
				happened = "bonk"
			else:
				_cans += 1
				happened = "can"
			things.remove_at(i)
		elif y > HEIGHT + 10.0:
			things.remove_at(i)
	return happened


func _spawn() -> void:
	# A rock in one or two lanes (never all three: there's always a way
	# through), sometimes a fuel can in a free lane.
	var open_lanes := [0, 1, 2]
	open_lanes.shuffle()
	var rocks := 2 if _rng.randf() < clampf((speed - START_SPEED) / 120.0, 0.0, 0.6) else 1
	for i in rocks:
		things.append({"lane": open_lanes.pop_back(), "y": -8.0, "kind": "rock"})
	if _rng.randf() < 0.3 and not open_lanes.is_empty():
		things.append({"lane": open_lanes.pop_back(), "y": -20.0, "kind": "can"})

