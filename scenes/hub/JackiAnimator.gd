class_name JackiAnimator
extends Node3D
## Jacki on foot, with real animations: the developer's model rigged onto a
## free skeleton with its animation set (art/models/jacki_rigged.glb, made
## by tools/rig_jacki.py from Quaternius's CC0 "Ultimate Animated Character
## Pack"). Plays Idle, Walk and Run as she moves, and holds a POSE when she
## stands still, like BunnyAnimator does for the hand-animated critters
## (same animate() and `pose`, so the player and the rooms don't care which
## one they've got).

## Poses she can hold standing still -> [animation, loops?]. (A one-shot
## animation stops on its last frame: sitting down stays seated.)
const POSES := {
	"stand": ["Idle", true], "sit": ["SitDown", false], "sleep": ["SitDown", false],
	"work": ["PickUp", true], "eat": ["Idle", true], "read": ["Idle", true],
	"dance": ["Victory", true], "wave": ["Victory", false], "lean": ["Idle", true],
}
## Animations that loop.
const LOOPING: PackedStringArray = ["Idle", "Walk", "Run", "Walk_Carry", "Run_Carry", "Victory", "PickUp"]

## What she's doing when not walking (see POSES).
@export var pose: String = "stand"
## Above this (1 = walking speed), she runs instead of walks.
@export var run_above: float = 1.3
## How fast the walk and run animations play at walking / running speed
## (raise them if her feet slide, lower them if she moonwalks).
@export var walk_rate: float = 1.0
@export var run_rate: float = 0.75
## Seconds to blend from one animation to the next.
@export var blend: float = 0.2

var _player: AnimationPlayer
var _hand: BoneAttachment3D


func _ready() -> void:
	var found := find_children("*", "AnimationPlayer", true, false)
	if found.is_empty():
		return
	_player = found[0] as AnimationPlayer
	for animation_name in LOOPING:
		if _player.has_animation(animation_name):
			_player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	_player.play("Idle")
	var skeleton := find_children("*", "Skeleton3D", true, false)
	if not skeleton.is_empty():
		_hand = BoneAttachment3D.new()
		_hand.name = "Hand"
		_hand.bone_name = "Fist.R"
		(skeleton[0] as Skeleton3D).add_child(_hand)


## Called every frame by whoever moves her. `walking` is her speed, where 1
## means walking speed (0 = standing still).
func animate(_delta: float, walking: float) -> void:
	if _player == null:
		return
	if walking > 0.05:
		var running := walking > run_above
		_play("Run" if running else "Walk", true)
		_player.speed_scale = walking * (run_rate if running else walk_rate)
		return
	_player.speed_scale = 1.0
	var held: Array = POSES.get(pose, POSES["stand"])
	_play(held[0], held[1])


## Where her right hand is, for things she holds (a snack, a can).
func hand() -> Node3D:
	return _hand


func _play(animation_name: String, _loops: bool) -> void:
	if _player.current_animation == animation_name or not _player.has_animation(animation_name):
		return
	if _player.assigned_animation == animation_name and not _player.is_playing():
		return  # A one-shot that already finished (seated): stay put.
	_player.play(animation_name, blend)
