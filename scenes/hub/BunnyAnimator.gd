class_name BunnyAnimator
extends Node3D
## Makes a chibi animal model move: legs and arms swing when walking, the
## body bobs, long ears flop behind with a little lag, and when standing
## still she breathes and blinks. No animation files needed: it's all done
## by turning the model's parts (found by name) a little every frame.
##
## Used by BunnyVisual.tscn and the other critters' models (built by
## tools/build_hub.gd). The player and NPCs call animate() every frame.


## How far the legs swing, in radians, at full walking speed.
@export var stride: float = 0.65
## Steps per second at full walking speed.
@export var step_rate: float = 2.2
## Which way the ears swing when walking: 1 = tips forward (ears that stand
## up flop back), -1 = tips backward (lop ears that hang down trail behind).
@export var ear_swing: float = 1.0

var _time := 0.0
var _walk := 0.0
var _ear_lag := 0.0
var _blink := 3.0
## Where the body sits when standing still (the bob is added on top).
var _body_rest_y := 0.0

@onready var _body: Node3D = get_node_or_null("Body")
@onready var _head: Node3D = get_node_or_null("Body/Head")
@onready var _leg_left: Node3D = get_node_or_null("LegLeft")
@onready var _leg_right: Node3D = get_node_or_null("LegRight")
@onready var _arm_left: Node3D = get_node_or_null("Body/ArmLeft")
@onready var _arm_right: Node3D = get_node_or_null("Body/ArmRight")
@onready var _ear_left: Node3D = get_node_or_null("Body/Head/EarLeft")
@onready var _ear_right: Node3D = get_node_or_null("Body/Head/EarRight")
@onready var _eyelids: Node3D = get_node_or_null("Body/Head/Eyelids")


func _ready() -> void:
	if _body != null:
		_body_rest_y = _body.position.y


## `walking` runs from 0 (standing still) to 1 (full walking speed).
func animate(delta: float, walking: float) -> void:
	_walk = lerpf(_walk, clampf(walking, 0.0, 1.5), 1.0 - exp(-10.0 * delta))
	var amount := minf(_walk, 1.0)
	if _walk > 0.02:
		_time += delta * step_rate * TAU * maxf(_walk, 0.3)  # Step along.
	var swing := sin(_time) * stride * amount
	if _leg_left != null:
		_leg_left.rotation.x = swing
		_leg_right.rotation.x = -swing
	if _arm_left != null:
		_arm_left.rotation.x = -swing * 0.8
		_arm_right.rotation.x = swing * 0.8
	if _body != null:
		# A little bounce in each step, or slow breathing when standing.
		var breathe := sin(Time.get_ticks_msec() / 1000.0 * 1.6) * 0.008
		_body.position.y = _body_rest_y + absf(sin(_time)) * 0.035 * amount + breathe
		_body.rotation.x = -0.08 * amount  # Lean into the walk.
	# Ears trail behind when walking and bounce with the steps.
	_ear_lag = lerpf(_ear_lag, 0.5 * amount, 1.0 - exp(-4.0 * delta))
	if _ear_left != null:
		_ear_left.rotation.x = (0.15 + _ear_lag + sin(_time * 2.0) * 0.08 * amount) * ear_swing
		_ear_right.rotation.x = (0.05 + _ear_lag * 0.8 + sin(_time * 2.0 + 0.6) * 0.08 * amount) * ear_swing
	if _head != null:
		_head.rotation.x = sin(_time * 2.0) * 0.03 * amount
	_update_blink(delta)


## Tired, heavy blinks every few seconds.
func _update_blink(delta: float) -> void:
	if _eyelids == null:
		return
	_blink -= delta
	if _blink < 0.0:
		_blink = randf_range(2.5, 6.0)
	_eyelids.scale.y = 2.4 if _blink < 0.15 else 1.0
