extends Node
## Money and time on the road (milestone M6). GameState holds the numbers;
## this holds the rules. Every price and rate is in res://data/tuning.tres
## ("Time and bills", "Rig levels") or in the data files, never here.
##
## TIME: space trucking is slow. A delivery takes days on the calendar (the
## job's trip_days, about a week for a long haul), and sleeping in your bed
## while parked is one night. Nothing else moves the calendar: no clocks,
## no shifts, no hurry.
##
## BILLS: every 7 days on the calendar, OrbitalEx's berth and dispatch fee
## comes due (plus insurance, if you have it). What you can't pay goes on a
## TAB, paid off from your next delivery. No interest, no penalty.
##
## RIG LEVELS: each rig earns XP from the deliveries it makes, and levels up
## (ten levels), getting a little faster, punchier, nimbler, grippier and
## longer-legged each time. Some upgrades need a rig of a certain level.


const DAYS_PER_WEEK: int = 7

## Emitted when bills are paid (or put on the tab): the bill (see pay_bills).
signal bills_paid(bill: Dictionary)


## Which week of the calendar `on_day` is in (week 1 = days 1 to 7).
func week_of(on_day: int) -> int:
	return floori((on_day - 1) / float(DAYS_PER_WEEK)) + 1


## "DAY 12 · WEEK 2", for the HUD and the PC.
func calendar_text() -> String:
	return "DAY %d  ·  WEEK %d" % [GameState.day, week_of(GameState.day)]


## Days left until the next bills (1 to 7).
func days_to_bills() -> int:
	return DAYS_PER_WEEK - (GameState.day - 1) % DAYS_PER_WEEK


## How many days `job` takes on the road.
func trip_days(job: JobData) -> int:
	if job != null and job.trip_days > 0:
		return job.trip_days
	return GameState.tuning.default_trip_days


## What a week's bills come to: {"dispatch", "insurance", "total"}.
func weekly_bill() -> Dictionary:
	var tuning := GameState.tuning
	var insurance := tuning.weekly_insurance if GameState.insured else 0
	return {"dispatch": tuning.weekly_dispatch_fee, "insurance": insurance, "total": tuning.weekly_dispatch_fee + insurance}


## Moves the calendar on `days` days, paying the bills for every week it
## crosses. Returns the bill (see pay_bills), or {} if no bills came due.
func pass_days(days: int) -> Dictionary:
	var weeks_before := week_of(GameState.day)
	GameState.day += maxi(days, 0)
	var weeks := week_of(GameState.day) - weeks_before
	if weeks <= 0:
		return {}
	return pay_bills(weeks)


## Pays `weeks` weeks of bills from the wallet; what's left over goes on
## the tab. Returns {"weeks", "dispatch", "insurance", "total", "paid",
## "on_tab"} (also kept in GameState.pending_bills for the bills card).
func pay_bills(weeks: int) -> Dictionary:
	var bill := weekly_bill()
	var total: int = int(bill["total"]) * weeks
	var paid := mini(total, GameState.credits)
	if paid > 0:
		GameState.spend(paid)
	GameState.tab += total - paid
	var result := {"weeks": weeks, "dispatch": int(bill["dispatch"]) * weeks, "insurance": int(bill["insurance"]) * weeks,
			"total": total, "paid": paid, "on_tab": total - paid, "day": GameState.day}
	GameState.pending_bills = result
	GameState.set_flag("first_bills")  # (Billing sends a statement: see the PC's mail.)
	if total - paid > 0:
		GameState.set_flag("ran_a_tab")
	bills_paid.emit(result)
	return result


## Pays the tab off from the wallet as far as it'll go (after a delivery).
## Returns how much was paid off.
func settle_tab() -> int:
	var paying := mini(GameState.tab, GameState.credits)
	if paying <= 0:
		return 0
	GameState.credits -= paying
	GameState.tab -= paying
	GameState.credits_changed.emit()
	return paying


## What fixing the hull costs right now (insurance pays part of it).
func repair_cost() -> int:
	var tuning := GameState.tuning
	var full := (1.0 - float(GameState.rig["hull"])) * tuning.hull_repair_price
	return ceili(full * (tuning.insured_repair_share if GameState.insured else 1.0))


# --- Rig levels ---------------------------------------------------------------------

## The level a rig with `xp` experience is at (1 to 10).
func level_for_xp(xp: int) -> int:
	var thresholds := GameState.tuning.level_xp
	var level := 1
	for i in thresholds.size():
		if xp >= thresholds[i]:
			level = i + 1
	return level


## The level of the rig `ship_id` (the one you're driving if empty).
func level_of(ship_id: String = "") -> int:
	var id := ship_id if not ship_id.is_empty() else GameState.active_ship
	return level_for_xp(int(GameState.ship_xp.get(id, 0)))


## XP still needed for the next level (0 at the top level).
func xp_to_next(ship_id: String = "") -> int:
	var id := ship_id if not ship_id.is_empty() else GameState.active_ship
	var xp := int(GameState.ship_xp.get(id, 0))
	var level := level_for_xp(xp)
	var thresholds := GameState.tuning.level_xp
	return thresholds[level] - xp if level < thresholds.size() else 0


## The XP a delivery that paid `paid` credits earns.
func xp_for(paid: int) -> int:
	var tuning := GameState.tuning
	return roundi(paid * tuning.xp_per_credit) + tuning.xp_per_delivery


## Gives the rig you're driving `xp` experience. Returns how many levels it
## went up (0 if none).
func add_xp(xp: int) -> int:
	var id := GameState.active_ship
	var before := level_of(id)
	GameState.ship_xp[id] = int(GameState.ship_xp.get(id, 0)) + xp
	if level_of(id) >= 3:
		GameState.set_flag("rig_level_3")  # (Dusty writes about the parts that fit now.)
	return level_of(id) - before


## Makes `ship` (a copy of a rig's numbers) as good as its level: a few
## percent better per level above 1.
func apply_level(ship: ShipData, level: int) -> void:
	var tuning := GameState.tuning
	var steps := float(maxi(level - 1, 0))
	ship.max_speed *= 1.0 + tuning.level_speed * steps
	ship.acceleration *= 1.0 + tuning.level_acceleration * steps
	ship.retro_thrust *= 1.0 + tuning.level_acceleration * steps
	ship.turn_rate *= 1.0 + tuning.level_turn * steps
	ship.pitch_rate *= 1.0 + tuning.level_turn * steps
	ship.grip *= 1.0 + tuning.level_grip * steps
	ship.fuel_tank_seconds *= 1.0 + tuning.level_fuel * steps
