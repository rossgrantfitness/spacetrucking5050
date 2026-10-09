class_name ChatterSet
extends Resource
## Some things ONE person might say over the comms in ONE situation. When
## that situation comes up, the game picks a line at random from all the
## sets that fit (avoiding the line it just used).
##
## A set can be limited to a place (approaching or docking at the truck
## stop...), to parts of the story (flags), or to a job you're hauling.
##
## Lines can use {bunny}, {husband}, {base} and {currency}. Keep them short:
## the comm box is small (about 60 letters fit on one card; longer lines
## flip to a second card).


enum Situation {
	TAKEOFF,  ## A few seconds after launching.
	IDLE,  ## Nothing's happening: small talk, every minute or two.
	APPROACH,  ## Getting close to a place (set `place`).
	BONK,  ## Somebody heard that.
	BOOST,  ## Somebody saw that.
	LOW_FUEL,  ## The low-fuel light just came on.
	DOCKING,  ## The docking autopilot just took over at a place.
	ROUGH,  ## The cargo's rattling: hard turns, slides, wild boosting.
	SPEEDING,  ## A speed trap clocked you.
	OUT_OF_FUEL,  ## The tank ran dry: Gas-N-Go's sending a tanker.
	TANKER,  ## The roadside tanker just filled you up (and billed you).
}

## Who's talking (their name, voice and portrait come from this file).
@export var speaker: NPCData
## When they say it.
@export var situation: Situation = Situation.IDLE
## What they might say, one call per line.
@export var lines: PackedStringArray = PackedStringArray()

@export_group("Only when...")
## Only at this place (a place id like "truck_stop"; empty = anywhere).
@export var place: String = ""
## Only when ALL of these story flags are set.
@export var needs_flags: PackedStringArray = PackedStringArray()
## Never when ANY of these story flags are set.
@export var blocked_by_flags: PackedStringArray = PackedStringArray()
## Only while hauling this job (a job id; empty = any time).
@export var needs_active_job: String = ""
## Only when you're not hauling anything.
@export var needs_no_job: bool = false


## Whether this set fits right now, at `at_place` (a place id, or "").
func matches(at_place: String) -> bool:
	if not place.is_empty() and place != at_place:
		return false
	for flag in needs_flags:
		if not GameState.has_flag(flag):
			return false
	for flag in blocked_by_flags:
		if GameState.has_flag(flag):
			return false
	if not needs_active_job.is_empty() and GameState.active_job_id != needs_active_job:
		return false
	return not (needs_no_job and not GameState.active_job_id.is_empty())
