class_name JobData
extends Resource
## One delivery job. Each job gets its own .tres file in this folder, and
## res://data/jobs/jobs.tres lists every job in the game.
##
## Pay is base pay plus two optional bonuses:
## - CARE bonus (fragile, perishable or live cargo): paid in full if the
##   cargo arrives perfect, and shrinks with every bonk. 0 = not fragile.
## - RUSH bonus: paid if you arrive within the target time. Late is fine:
##   you still get the base pay. A rush job never fails.
##
## Where it shows up: on the job board at `from_place` (unless it's a story
## job someone offers you in person), once you've reached `requires_flag`.


## A short code name, used in saves. Keep it unique.
@export var id: String = "job"
## What's in the back, shown on the HUD and the job board.
@export var cargo_name: String = "Mystery crates"
## Who's paying.
@export var client_name: String = "Somebody"
## A line or two about the job, for the job board.
@export_multiline var description: String = ""
## Where you pick it up and where it goes (place ids, see res://data/places/).
@export var from_place: String = "base"
@export var to_place: String = "truck_stop"

## How heavy the load is, in tons. Space trucking is BIG: a pie run is
## hundreds of millions of tons. Heavy loads (against the rig's
## load_rating) take longer to get going, longer to stop and swing wider
## in turns (see "Load weight" in tuning.tres). The HUD shows it as
## "450M T"; the job board says "450 million tons".
@export_range(0.0, 1e13, 1.0, "suffix:t") var weight: float = 5e8

## Pay for showing up with the cargo, no matter what.
@export_range(0, 100000, 10) var base_pay: int = 300

## Fragile bonus: all of it for perfect cargo, less for every bonk.
## 0 = not a fragile job.
@export_range(0, 100000, 10) var care_bonus: int = 0
## What kind of careful cargo it is (for the job board's tag): fragile
## (breaks), perishable (spoils) or live (it's alive. Be nice).
@export_enum("fragile", "perishable", "live") var care_kind: String = "fragile"

## Rush jobs: arrive within this many seconds for the rush bonus.
## 0 = not a rush job (no timer at all).
@export_range(0.0, 3600.0, 5.0, "suffix:s") var rush_seconds: float = 0.0
@export_range(0, 100000, 10) var rush_bonus: int = 0

@export_group("Story")
## On: shows on the job board. Off: only a person offers it (story jobs).
@export var on_job_board: bool = true
## Off: once delivered, it never comes back.
@export var repeatable: bool = true
## Only available once this story flag is set (empty = always).
@export var requires_flag: String = ""
## A story flag set when you deliver it.
@export var completes_flag: String = ""


## What this job pays for cargo in `condition` (0 to 1) arriving after
## `seconds` of flying.
func pay_for(condition: float, seconds: float) -> int:
	return pay_breakdown(condition, seconds)["total"]


## The pay, piece by piece: {"base", "care", "rush", "total"}.
func pay_breakdown(condition: float, seconds: float) -> Dictionary:
	var care := roundi(care_bonus * clampf(condition, 0.0, 1.0))
	var rush := rush_bonus if is_rush() and seconds <= rush_seconds else 0
	return {"base": base_pay, "care": care, "rush": rush, "total": base_pay + care + rush}


func is_rush() -> bool:
	return rush_seconds > 0.0


func is_fragile() -> bool:
	return care_bonus > 0
