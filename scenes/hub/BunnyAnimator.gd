class_name BunnyAnimator
extends Node3D
## Makes a chibi animal model move: legs and arms swing when walking, the
## body bobs, long ears flop behind with a little lag, and when standing
## still she breathes and blinks. No animation files needed: it's all done
## by turning the model's parts (found by name) a little every frame.
##
## Used by JackiVisual.tscn, the crew (scenes/hub/crew/) and the other
## critters. The player and NPCs call animate() every frame.
##
## Standing still, they can hold a POSE (set `pose`, for the crew's
## activities aboard): "stand", "sit", "sleep", "work", "eat", "read",
## "dance", "wave" or "lean".


## How far the legs swing, in radians, at full walking speed.
@export var stride: float = 0.65
## Steps per second at full walking speed.
@export var step_rate: float = 2.2
## Which way the ears swing when walking: 1 = tips forward (ears that stand
## up flop back), -1 = tips backward (lop ears that hang down trail behind).
@export var ear_swing: float = 1.0
## What they're doing when not walking (see the list above).
@export var pose: String = "stand"

@export_group("Bendy ears")
## For models with bendy ears (an "EarRig" skeleton in the head, like
## Jacki's): each ear is two springy segments that lag behind the head's
## movement, the tips lagging behind the bases (overlapping action). Start
## walking and they swing back; stop and they flop forward and wobble; turn
## and they swing out.
## How stiff the upper ear is (higher = snappier, less floppy).
@export var ear_stiffness: float = 55.0
## How quickly the upper ear's wobble dies down (lower = wobblier).
@export var ear_damping: float = 5.5
## How stiff the ear tips are (they lag behind the upper ear).
@export var ear_tip_stiffness: float = 80.0
@export var ear_tip_damping: float = 4.5
## How strongly the head's movement throws the ears around.
@export var ear_inertia: float = 0.035
## How far back the ears trail at a full walk (radians).
@export var ear_walk_trail: float = 0.22

var _time := 0.0
var _walk := 0.0
var _ear_lag := 0.0
var _blink := 3.0
## Where the body sits when standing still (the bob is added on top).
var _body_rest_y := 0.0
var _legs_rest_y := 0.0
var _pose_time := 0.0
var _snore: Label3D

@onready var _body: Node3D = get_node_or_null("Body")
@onready var _head: Node3D = get_node_or_null("Body/Head")
@onready var _leg_left: Node3D = get_node_or_null("LegLeft")
@onready var _leg_right: Node3D = get_node_or_null("LegRight")
@onready var _arm_left: Node3D = get_node_or_null("Body/ArmLeft")
@onready var _arm_right: Node3D = get_node_or_null("Body/ArmRight")
@onready var _ear_left: Node3D = get_node_or_null("Body/Head/EarLeft")
@onready var _ear_right: Node3D = get_node_or_null("Body/Head/EarRight")
@onready var _eyelids: Node3D = get_node_or_null("Body/Head/Eyelids")
@onready var _ear_rig: Skeleton3D = get_node_or_null("Body/Head/EarRig")

## Bendy ears: for each side, [upper angle (x: back/forward, z: out/in),
## its speed, tip angle, its speed].
var _ears := {}
var _last_head_position := Vector3.ZERO
var _last_head_velocity := Vector3.ZERO
var _last_head_yaw := 0.0
var _ears_started := false


func _ready() -> void:
	if _body != null:
		_body_rest_y = _body.position.y
	if _leg_left != null:
		_legs_rest_y = _leg_left.position.y


## Where her right hand is, for things she holds (Snack.gd), if the model
## has a "Hand" marker on its right arm (Jacki does); null otherwise.
func hand() -> Node3D:
	return get_node_or_null("Body/ArmRight/Hand") as Node3D


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
	if _ear_rig != null and _head != null:
		_swing_bendy_ears(delta, amount)
	if _head != null:
		_head.rotation.x = sin(_time * 2.0) * 0.03 * amount
	_pose_time += delta
	_apply_pose(1.0 - amount)
	_update_blink(delta)


## Holds the pose on top of standing still. `strength` fades it out as she
## starts walking.
func _apply_pose(strength: float) -> void:
	var t := _pose_time
	rotation.x = 0.0
	rotation.z = 0.0
	if _snore != null:
		_snore.visible = false
	if _leg_left != null:
		_leg_left.position.y = _legs_rest_y
		_leg_right.position.y = _legs_rest_y
	if _arm_right != null:
		_arm_right.rotation.z = 0.0
	if strength <= 0.01 or pose == "stand" or _body == null or _leg_left == null or _arm_left == null:
		return
	match pose:
		"sit":
			var drop := _body_rest_y * 0.45
			_body.position.y -= drop * strength
			_leg_left.position.y = _legs_rest_y - drop * strength
			_leg_right.position.y = _legs_rest_y - drop * strength
			_leg_left.rotation.x = 1.45 * strength
			_leg_right.rotation.x = 1.45 * strength
			_arm_left.rotation.x = 0.5 * strength
			_arm_right.rotation.x = 0.5 * strength
		"sleep":
			# Flat on her back, face up, breathing slowly. Zzz.
			rotation.x = PI / 2.0 * strength
			_body.position.y = _body_rest_y + sin(t * 1.2) * 0.012
			if _snore == null:
				_snore = Label3D.new()
				_snore.text = "z"
				_snore.font_size = 48
				_snore.pixel_size = 0.006
				_snore.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				_snore.modulate = Color(0.7, 0.8, 1.0)
				add_child(_snore)
			_snore.visible = true
			_snore.text = "z".repeat(1 + int(t) % 3)
			_snore.position = Vector3(0.0, 0.3 + fposmod(t, 1.0) * 0.2, 1.2)
		"work":
			# Tinkering: hands busy in front, a little bob.
			_arm_left.rotation.x = (0.9 + sin(t * 7.0) * 0.35) * strength
			_arm_right.rotation.x = (0.9 + sin(t * 7.0 + 2.0) * 0.35) * strength
			_body.rotation.x = 0.12 * strength
			_body.position.y += absf(sin(t * 3.5)) * 0.01 * strength
		"eat":
			# A bite every couple of seconds.
			var bite := clampf(sin(t * 2.6) * 2.0, 0.0, 1.0)
			_arm_right.rotation.x = (0.4 + bite * 1.5) * strength
			_arm_left.rotation.x = 0.5 * strength
		"read":
			_arm_left.rotation.x = 1.1 * strength
			_arm_right.rotation.x = 1.1 * strength
			if _head != null:
				_head.rotation.x = -0.25 * strength
		"dance":
			_body.position.y += absf(sin(t * 5.0)) * 0.05 * strength
			rotation.z = sin(t * 2.5) * 0.12 * strength
			_arm_left.rotation.x = (2.4 + sin(t * 5.0) * 0.5) * strength
			_arm_right.rotation.x = (2.4 - sin(t * 5.0) * 0.5) * strength
			_leg_left.rotation.x = sin(t * 5.0) * 0.25 * strength
			_leg_right.rotation.x = -sin(t * 5.0) * 0.25 * strength
		"wave":
			_arm_right.rotation.x = 2.6 * strength
			_arm_right.rotation.z = sin(t * 8.0) * 0.4 * strength
		"lean":
			rotation.z = 0.1 * strength
			_arm_left.rotation.x = 0.6 * strength
			_arm_right.rotation.x = 0.6 * strength


## The bendy ears: two springs per ear, shoved around by how the head
## actually moves (speeding up, slowing down, bobbing, turning). The tip
## spring is shoved by the upper ear's own swing, so it lags behind it and
## overshoots: overlapping action.
func _swing_bendy_ears(delta: float, amount: float) -> void:
	if delta <= 0.0:
		return
	var head_position := _head.global_position
	var head_basis := _head.global_basis.orthonormalized()
	var yaw := atan2(head_basis.z.x, head_basis.z.z)
	if not _ears_started:
		_ears_started = true
		_last_head_position = head_position
		_last_head_yaw = yaw
		for side in ["Left", "Right"]:
			_ears[side] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	var velocity := (head_position - _last_head_position) / delta
	var acceleration := (velocity - _last_head_velocity) / delta
	acceleration = acceleration.limit_length(40.0)  # (Teleports and cuts don't fling them.)
	var turn_rate := clampf(wrapf(yaw - _last_head_yaw, -PI, PI) / delta, -8.0, 8.0)
	_last_head_position = head_position
	_last_head_velocity = velocity
	_last_head_yaw = yaw
	# The push on the ears, in the head's own directions (its face looks
	# down -Z): speeding up forward throws the tips back, bobbing up and
	# down flaps them, moving sideways swings them the other way.
	var push := head_basis.inverse() * acceleration * ear_inertia
	var trail := ear_swing * (0.12 + ear_walk_trail * amount)
	var steps := maxi(1, ceili(delta / 0.008))  # Small steps keep the springs steady.
	var step := delta / steps
	for side: String in _ears:
		var outward := -1.0 if side == "Left" else 1.0  # (Her left is at -X once she faces -Z.)
		var state: Array = _ears[side]
		var upper: Vector2 = state[0]
		var upper_speed: Vector2 = state[1]
		var tip: Vector2 = state[2]
		var tip_speed: Vector2 = state[3]
		var shove := Vector2(push.z * ear_swing * -1.0 + push.y * 0.5, -push.x + absf(turn_rate) * 0.025 * outward)
		for i in steps:
			var upper_force := (Vector2(trail, 0.0) - upper) * ear_stiffness - upper_speed * ear_damping + shove * ear_stiffness
			upper_speed += upper_force * step
			upper += upper_speed * step
			var tip_force := -tip * ear_tip_stiffness - tip_speed * ear_tip_damping - upper_force * 0.35 + shove * ear_tip_stiffness * 0.5
			tip_speed += tip_force * step
			tip += tip_speed * step
		# Kept to gentle angles: past these, bent ears stretch like taffy.
		upper = upper.clamp(Vector2(-0.55, -0.22), Vector2(0.55, 0.22))
		tip = tip.clamp(Vector2(-0.45, -0.18), Vector2(0.45, 0.18))
		_ears[side] = [upper, upper_speed, tip, tip_speed]
		var upper_bone := _ear_rig.find_bone("Ear" + side)
		var tip_bone := _ear_rig.find_bone("Ear" + side + "Tip")
		if upper_bone >= 0:
			_ear_rig.set_bone_pose_rotation(upper_bone, Quaternion(Basis.from_euler(Vector3(upper.x, 0.0, upper.y))))
		if tip_bone >= 0:
			_ear_rig.set_bone_pose_rotation(tip_bone, Quaternion(Basis.from_euler(Vector3(tip.x, 0.0, tip.y))))


## Tired, heavy blinks every few seconds.
func _update_blink(delta: float) -> void:
	if _eyelids == null:
		return
	_blink -= delta
	if _blink < 0.0:
		_blink = randf_range(2.5, 6.0)
	_eyelids.scale.y = 2.4 if _blink < 0.15 else 1.0
