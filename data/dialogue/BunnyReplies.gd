class_name BunnyReplies
extends Resource
## What Jacki can say back when someone calls on the comms. After a call,
## press T (RB on a gamepad) and pick one of three. Pure flavor: replies
## never change anything, they just let her be herself (dry, tired,
## unbothered). Three are picked at random from the list for the kind of
## call it was. Lines can use {bunny}, {husband}, {base} and {currency}.


## Her voice and portrait on the comms.
@export var voice: NPCData

## Replies to each kind of call (see ChatterSet.Situation).
@export var takeoff: PackedStringArray = PackedStringArray()
@export var idle: PackedStringArray = PackedStringArray()
@export var approach: PackedStringArray = PackedStringArray()
@export var bonk: PackedStringArray = PackedStringArray()
@export var boost: PackedStringArray = PackedStringArray()
@export var low_fuel: PackedStringArray = PackedStringArray()
@export var docking: PackedStringArray = PackedStringArray()
@export var rough: PackedStringArray = PackedStringArray()
@export var speeding: PackedStringArray = PackedStringArray()


## Up to `count` different replies for a kind of call (small talk if that
## kind has none).
func pick(situation: ChatterSet.Situation, count: int, rng: RandomNumberGenerator) -> PackedStringArray:
	var pool: PackedStringArray = idle
	match situation:
		ChatterSet.Situation.TAKEOFF: pool = takeoff
		ChatterSet.Situation.APPROACH: pool = approach
		ChatterSet.Situation.BONK: pool = bonk
		ChatterSet.Situation.BOOST: pool = boost
		ChatterSet.Situation.LOW_FUEL: pool = low_fuel
		ChatterSet.Situation.DOCKING: pool = docking
		ChatterSet.Situation.ROUGH: pool = rough
		ChatterSet.Situation.SPEEDING: pool = speeding
	if pool.is_empty():
		pool = idle
	var left := Array(pool)
	var picked := PackedStringArray()
	while picked.size() < count and not left.is_empty():
		picked.append(str(left.pop_at(rng.randi_range(0, left.size() - 1))))
	return picked
