class_name Conversation
extends Resource
## One thing a person might say, and when. An NPC's data file holds a list
## of these; when you talk to them, the FIRST one whose conditions all match
## is used (so put the most specific ones first). If none match, they say
## their plain `lines`.
##
## After the lines, a conversation can set story flags, offer you a job
## (with a yes/no choice), or open a menu (the job board, a shop...).


## Only when ALL of these story flags are set.
@export var needs_flags: PackedStringArray = PackedStringArray()
## Never when ANY of these story flags are set.
@export var blocked_by_flags: PackedStringArray = PackedStringArray()
## Only while you're hauling this job (empty = any time).
@export var needs_active_job: String = ""
## Only when you're NOT hauling anything.
@export var needs_no_job: bool = false

## What they say, one box per line. Can use {bunny}, {husband}, {base},
## {currency}.
@export var lines: PackedStringArray = PackedStringArray()
## Story flags set after the lines.
@export var sets_flags: PackedStringArray = PackedStringArray()
## A job they offer at the end (you get to say yes or no).
@export var offers_job: JobData
## A menu to open at the end: "job_board", "fuel", "mechanic", "jukebox",
## "vending" (empty = none).
@export var opens_menu: String = ""


## Whether this conversation fits the game right now.
func matches() -> bool:
	for flag in needs_flags:
		if not GameState.has_flag(flag):
			return false
	for flag in blocked_by_flags:
		if GameState.has_flag(flag):
			return false
	if not needs_active_job.is_empty() and GameState.active_job_id != needs_active_job:
		return false
	if needs_no_job and not GameState.active_job_id.is_empty():
		return false
	return true
