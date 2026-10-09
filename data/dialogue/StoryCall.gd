class_name StoryCall
extends Resource
## A call that matters, made ONCE: someone (or something) on the comms
## while you fly, when the story has got to the right point. Unlike the
## small talk in flight_chatter.tres, a story call is never random and
## never repeats. They live in res://data/dialogue/story_calls.tres; the
## first one that fits plays, at most one per trip (see CommChatter.gd).
##
## Lines can use {bunny}, {husband}, {base}, {currency}, {company} and
## {boss}. Each line gets its own card in the comm box.


## A short code name. Once it has played, the story flag
## "story_call_<id>" is set, and it never plays again.
@export var id: String = "call"
## Who's talking (their name, voice and portrait come from this file).
@export var speaker: NPCData
## What they say, one card per line.
@export var lines: PackedStringArray = PackedStringArray()
## A banner shown across the screen just before (e.g. "PLAYING A SAVED
## MESSAGE"). Empty = none.
@export var banner: String = ""
## Whether Jacki can say something back.
@export var repliable: bool = true
## What she can say back (empty = her usual one-liners).
@export var replies: PackedStringArray = PackedStringArray()
## How long after takeoff, at the earliest (seconds of flying).
@export_range(0.0, 600.0, 1.0, "suffix:s") var delay_seconds: float = 40.0
## Story flags set once it has played.
@export var sets_flags: PackedStringArray = PackedStringArray()

@export_group("Only when...")
## Only when ALL of these story flags are set.
@export var needs_flags: PackedStringArray = PackedStringArray()
## Never when ANY of these story flags are set.
@export var blocked_by_flags: PackedStringArray = PackedStringArray()
## Only after this many deliveries, ever.
@export_range(0, 1000) var min_deliveries: int = 0
## Only while hauling this job (a job id; empty = any time).
@export var needs_active_job: String = ""


## The flag that remembers it has played.
func played_flag() -> String:
	return "story_call_" + id


## Whether it should play now.
func fits() -> bool:
	if GameState.has_flag(played_flag()) or GameState.deliveries < min_deliveries:
		return false
	for flag in needs_flags:
		if not GameState.has_flag(flag):
			return false
	for flag in blocked_by_flags:
		if GameState.has_flag(flag):
			return false
	return needs_active_job.is_empty() or GameState.active_job_id == needs_active_job


## Everything it says, as the comm box takes it (one card per line).
func words() -> String:
	return "\n".join(lines)
