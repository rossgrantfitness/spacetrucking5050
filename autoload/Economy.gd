extends Node
## Money and time on the road (milestone M6). GameState holds the numbers;
## this holds the rules. Every price and rate is in res://data/tuning.tres
## ("Time and bills", "Rig levels") or in the data files, never here.
##
## TIME: the calendar is 365 days in 12 months (res://data/calendar.tres),
## and the clock runs while you play: fast while you fly (a 10-minute haul is
## a day or two on the road), gently while you're parked, and a whole night
## when you sleep. TimeOfDay.gd ticks it; the rates are in tuning.tres.
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


const MINUTES_PER_DAY: float = 1440.0

## The galaxy's calendar (month names and lengths).
var calendar: CalendarData = preload("res://data/calendar.tres")


## Which week of the calendar `on_day` is in (week 1 = days 1 to 7).
func week_of(on_day: int) -> int:
	return floori((on_day - 1) / float(DAYS_PER_WEEK)) + 1


## A date, like "14 HAULWIND 5050" (today's if `on_day` is 0).
func date_text(on_day: int = 0) -> String:
	var date := calendar.date_of(on_day if on_day > 0 else GameState.day)
	return "%d %s %d" % [date["day"], calendar.month_name(date["month"]), date["year"]]


## A short date, like "14 HAU" (for tight spots like the PC's lists).
func short_date_text(on_day: int = 0) -> String:
	var date := calendar.date_of(on_day if on_day > 0 else GameState.day)
	return "%d %s" % [date["day"], calendar.month_name(date["month"]).substr(0, 3)]


## The time on the galaxy's clock, like "06:42 GST".
func clock_text() -> String:
	var minutes := floori(GameState.minute)
	return "%02d:%02d %s" % [floori(minutes / 60.0), minutes % 60, calendar.clock_name]


## The hour of the day (0 to 23).
func hour() -> int:
	return floori(GameState.minute / 60.0)


## "14 HAULWIND 5050", for the HUD and the PC.
func calendar_text() -> String:
	return date_text()


## Days left until the next bills (1 to 7).
func days_to_bills() -> int:
	return DAYS_PER_WEEK - (GameState.day - 1) % DAYS_PER_WEEK


## All the time since day 1 began, in minutes (for "how long did that take").
func now_minutes() -> float:
	return (GameState.day - 1) * MINUTES_PER_DAY + GameState.minute


## Moves the clock on `minutes`, rolling over into new days (and paying the
## bills for every week that ends). Returns how many days went by.
func advance_minutes(minutes: float) -> int:
	if minutes <= 0.0:
		return 0
	GameState.minute += minutes
	var days := floori(GameState.minute / MINUTES_PER_DAY)
	if days > 0:
		GameState.minute -= days * MINUTES_PER_DAY
		pass_days(days)
	return days


## Sleeps until the next morning (tuning: wake_up_hour). Returns the days
## that went by (1, or 0 if it's still before morning, say a 3 a.m. bedtime).
func sleep_until_morning() -> int:
	var wake := GameState.tuning.wake_up_hour * 60.0
	var minutes := wake - GameState.minute
	if minutes <= 60.0:
		minutes += MINUTES_PER_DAY  # (Under an hour's sleep isn't a night: sleep to tomorrow.)
	return advance_minutes(minutes)


## How long a trip of `meters` takes on the calendar at the rig's cruising
## speed, in minutes.
func trip_minutes(meters: float, ship: ShipData = null) -> float:
	var rig := ship if ship != null else GameState.active_ship_data()
	return meters / maxf(rig.max_speed, 1.0) * GameState.tuning.flight_minutes_per_second


## About how long `job` takes on the road, in minutes (from where it's
## picked up, or from `from_place` for jobs handed out aboard).
func job_trip_minutes(job: JobData, from_place: String = "") -> float:
	var from := GameState.places.find(job.from_place)
	if from == null or not from.on_the_map:
		from = GameState.places.find(from_place if not from_place.is_empty() else GameState.launch_from)
	var to := GameState.places.find(job.to_place)
	if from == null or to == null or not from.on_the_map or not to.on_the_map:
		return 0.0
	return trip_minutes(from.map_position.distance_to(to.map_position))


## A length of calendar time in words: "2 DAYS 5 HRS", "9 HRS", "40 MIN".
func span_text(minutes: float) -> String:
	var whole := roundi(minutes)
	var days := floori(whole / MINUTES_PER_DAY)
	var hours := floori((whole % int(MINUTES_PER_DAY)) / 60.0)
	if days > 0:
		return "%d DAY%s %d HR%s" % [days, "" if days == 1 else "S", hours, "" if hours == 1 else "S"]
	if hours > 0:
		return "%d HR%s" % [hours, "" if hours == 1 else "S"]
	return "%d MIN" % maxi(whole, 1)


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
	# On the PC's invoice list too (as money going out).
	GameState.invoices.append({"cargo": "WEEKLY BILLS", "client": GameState.names.company_name, "to": "", "total": -total, "day": GameState.day})
	if GameState.invoices.size() > GameState.INVOICE_LIMIT:
		GameState.invoices.remove_at(0)
	GameState.set_flag("first_bills")  # (Billing sends a statement: see the PC's mail.)
	if total - paid > 0:
		GameState.set_flag("ran_a_tab")
	bills_paid.emit(result)
	return result


## Pays the tab off from the wallet as far as it'll go (after a delivery).
## Returns how much was paid off.
## OrbitalEx's cut of a job right now: tuning's company_cut while you work
## for them, nothing once you own the company.
func company_cut() -> float:
	return 0.0 if GameState.has_flag("owns_company") else GameState.tuning.company_cut


## A job's full CONTRACT value: what the client pays the company. Jobs are
## quoted at this (the job board, the HUD, the delivery card), and you
## keep `net_pay` of it after the company's cut (see "The company" in
## tuning.tres). Always the employee-rate figure, owner or not.
func contract_value(net_pay: int) -> int:
	return roundi(net_pay / maxf(1.0 - GameState.tuning.company_cut, 0.01))


## What you actually take home from a job worth `net_pay` at the employee
## rate: the same, while you work for OrbitalEx; the whole contract once
## it's yours.
func take_home(net_pay: int) -> int:
	return contract_value(net_pay) if GameState.has_flag("owns_company") else net_pay


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
