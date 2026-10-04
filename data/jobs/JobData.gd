class_name JobData
extends Resource
## One delivery job. Each job gets its own .tres file in this folder.
##
## Pay is base pay plus two optional bonuses:
## - CARE bonus (fragile, perishable or live cargo): paid in full if the
##   cargo arrives perfect, and shrinks with every bonk. 0 = not fragile.
## - RUSH bonus: paid if you arrive within the target time. Late is fine:
##   you still get the base pay. A rush job never fails.
##
## (A real job board, clients and payouts arrive with M2. For now one
## practice haul rides along in the flight sandbox so the HUD has a job to
## show.)


## What's in the back, shown on the HUD and the manifest.
@export var cargo_name: String = "Mystery crates"
## Who's paying.
@export var client_name: String = "Somebody"
## Where it's going (short, it's shown on the HUD).
@export var destination_name: String = "TRUCK STOP"

## Pay for showing up with the cargo, no matter what.
@export_range(0, 100000, 10) var base_pay: int = 300

## Fragile bonus: all of it for perfect cargo, less for every bonk.
## 0 = not a fragile job.
@export_range(0, 100000, 10) var care_bonus: int = 0

## Rush jobs: arrive within this many seconds for the rush bonus.
## 0 = not a rush job (no timer at all).
@export_range(0.0, 3600.0, 5.0, "suffix:s") var rush_seconds: float = 0.0
@export_range(0, 100000, 10) var rush_bonus: int = 0


## What this job pays for cargo in `condition` (0 to 1) arriving after
## `seconds` of flying.
func pay_for(condition: float, seconds: float) -> int:
	var pay := float(base_pay) + care_bonus * clampf(condition, 0.0, 1.0)
	if is_rush() and seconds <= rush_seconds:
		pay += rush_bonus
	return roundi(pay)


func is_rush() -> bool:
	return rush_seconds > 0.0


func is_fragile() -> bool:
	return care_bonus > 0
