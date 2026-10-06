class_name PaddlePods
extends RefCounted
## PADDLE PODS, a game on Jacki's TV console (TVConsole.gd): bat a glowing
## pod back and forth against Digby (the computer player, who's good but
## slow). First to WIN_POINTS wins. Your score is the points you got.
##
## Just the rules; TVConsole.gd draws it. Sizes are in the TV's own pixels.


enum State { TITLE, PLAYING, OVER }

const WIDTH: float = 160.0
const HEIGHT: float = 120.0
const PADDLE_HALF: float = 11.0
const PADDLE_SPEED: float = 110.0
## Digby's paddle is slower than yours (so you can beat him).
const CPU_SPEED: float = 70.0
const START_BALL: float = 70.0
const WIN_POINTS: int = 5

var state: State = State.TITLE
var you_y: float = HEIGHT * 0.5
var cpu_y: float = HEIGHT * 0.5
var ball := Vector2(WIDTH * 0.5, HEIGHT * 0.5)
var ball_velocity := Vector2.ZERO
var you: int = 0
var cpu: int = 0
## The score that counts for the high score table (your points).
var score: int = 0
var you_won := false

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func start() -> void:
	state = State.PLAYING
	you = 0
	cpu = 0
	score = 0
	you_won = false
	you_y = HEIGHT * 0.5
	cpu_y = HEIGHT * 0.5
	_serve(1.0)


## `move` is -1 (up) to 1 (down). Returns "hit", "point", "miss" or "".
func step(delta: float, move: float) -> String:
	if state != State.PLAYING:
		return ""
	you_y = clampf(you_y + move * PADDLE_SPEED * delta, PADDLE_HALF, HEIGHT - PADDLE_HALF)
	# Digby follows the pod, but only so fast (and lazily when it's going away).
	var chase := CPU_SPEED * (1.0 if ball_velocity.x > 0.0 else 0.4)
	cpu_y = move_toward(cpu_y, ball.y, chase * delta)
	cpu_y = clampf(cpu_y, PADDLE_HALF, HEIGHT - PADDLE_HALF)
	ball += ball_velocity * delta
	if ball.y < 2.0 or ball.y > HEIGHT - 2.0:
		ball.y = clampf(ball.y, 2.0, HEIGHT - 2.0)
		ball_velocity.y = -ball_velocity.y
	# Your paddle on the left, Digby's on the right.
	if ball_velocity.x < 0.0 and ball.x < 8.0 and ball.x > 2.0 and absf(ball.y - you_y) < PADDLE_HALF + 2.0:
		_bounce(you_y, 1.0)
		return "hit"
	if ball_velocity.x > 0.0 and ball.x > WIDTH - 8.0 and ball.x < WIDTH - 2.0 and absf(ball.y - cpu_y) < PADDLE_HALF + 2.0:
		_bounce(cpu_y, -1.0)
		return "hit"
	if ball.x < -4.0:
		cpu += 1
		return _after_point(-1.0, "miss")
	if ball.x > WIDTH + 4.0:
		you += 1
		score = you
		return _after_point(1.0, "point")
	return ""


func _bounce(paddle_y: float, direction: float) -> void:
	# Where it hits the paddle sets the angle; every hit is a bit faster.
	var offset := clampf((ball.y - paddle_y) / PADDLE_HALF, -1.0, 1.0)
	var speed := minf(ball_velocity.length() * 1.06, 170.0)
	ball_velocity = Vector2(direction, offset * 0.8).normalized() * speed


func _after_point(serve_to: float, what: String) -> String:
	if you >= WIN_POINTS or cpu >= WIN_POINTS:
		state = State.OVER
		you_won = you >= WIN_POINTS
		return what
	_serve(serve_to)
	return what


func _serve(direction: float) -> void:
	ball = Vector2(WIDTH * 0.5, HEIGHT * 0.5)
	ball_velocity = Vector2(direction, _rng.randf_range(-0.5, 0.5)).normalized() * START_BALL
