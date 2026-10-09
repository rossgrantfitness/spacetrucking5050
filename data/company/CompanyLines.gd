class_name CompanyLines
extends Resource
## Everything said about (and by) the company in its office and on its
## checks, in res://data/company/company.tres. Edit the words there.
## Lines can use {bunny}, {boss}, {company} and {currency} (see WorldNames).


## The fees on every check, adding up to the company's cut. Each is
## "Label|share" (shares are parts of the cut, any numbers: they're scaled
## to add up).
@export var fee_items: PackedStringArray = PackedStringArray()
## Jacki, reading her very first check.
@export var first_check_reaction: PackedStringArray = PackedStringArray()
## The boss, after that first check (he sends her to Marge).
@export var first_check_boss: PackedStringArray = PackedStringArray()
## Jacki, buying the company.
@export var buyout_jacki: PackedStringArray = PackedStringArray()
## The boss, when she buys the company out from under him.
@export var buyout_boss: PackedStringArray = PackedStringArray()
## The line under the price, before you can afford it (one picked at random).
@export var not_yet: PackedStringArray = PackedStringArray()

@export_group("New orders")
## The card when someone says they'll call the company (their problem
## became an order). Can also use {client}, {cargo} and {to}.
@export_multiline var order_placed: String = ""
## The boss, handing you a new order at check-in. Can also use {client},
## {cargo} and {to}.
@export var order_lines: PackedStringArray = PackedStringArray()
## The same, once you own the company (he works for you now).
@export var owner_order_lines: PackedStringArray = PackedStringArray()
## The boss, when there are more orders still waiting. {count} is how many.
@export var more_orders: PackedStringArray = PackedStringArray()

@export_group("The boss's missions")
## His missions, in order: one at a time, handed out at the office. Buying
## the company only comes up once they're all done (see CompanyMission.gd).
@export var missions: Array[CompanyMission] = []
## The boss, the first time you check in after the last one (the board
## wants to sell).
@export var missions_all_done: PackedStringArray = PackedStringArray()


## The next mission he'll hand out right now, or null (none left, the one
## before isn't done, or not enough deliveries in yet).
func next_mission() -> CompanyMission:
	for mission in missions:
		if mission == null or mission.is_done():
			continue
		if GameState.deliveries < mission.min_deliveries or not GameState.job_available(mission.job):
			return null
		return mission
	return null


## How many missions are done.
func missions_done() -> int:
	return missions.filter(func(mission: CompanyMission) -> bool: return mission != null and mission.is_done()).size()


## Whether every mission's done (then the company's for sale).
func all_missions_done() -> bool:
	return missions_done() >= missions.size()


## The mission for a job id, or null.
func mission_for(job_id: String) -> CompanyMission:
	for mission in missions:
		if mission != null and mission.job != null and mission.job.id == job_id:
			return mission
	return null

