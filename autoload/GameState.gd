extends Node
## The live state of the game while it runs, and everything that goes into
## a save file: money, the story so far, the job you're hauling, the rig's
## tanks and hull, and its upgrades.
##
## Any script can reach it as `GameState` because it's an autoload (Godot
## creates it once at startup and keeps it alive the whole time).
##
## Saving: save_game() writes user://save.json (SaveSystem.gd). The game
## saves itself whenever you walk into a room, take a job, get paid or buy
## something.


## Emitted when money changes (the on-foot HUD shows your balance).
signal credits_changed

## The one shared copy of every feel number. To change values, open
## res://data/tuning.tres and use the Inspector.
var tuning: Tuning = preload("res://data/tuning.tres")
## The big names (the bunny, her husband, the base, the money). Change them in
## res://data/world_names.tres.
var names: WorldNames = preload("res://data/world_names.tres")
## Every place, job and upgrade in the game (see res://data/).
var places: PlaceList = preload("res://data/places/places.tres")
var systems: SystemList = preload("res://data/systems/systems.tres")
var jobs: JobList = preload("res://data/jobs/jobs.tres")
## The everyday loads around the story jobs (see FreightMarket.gd).
var freight: FreightMarket = preload("res://data/freight/freight_market.tres")
## Route choices out on the road: toll turnpikes, shortcuts, scenic lanes.
var routes: RouteList = preload("res://data/routes/routes.tres")
var upgrades: UpgradeList = preload("res://data/upgrades/upgrades.tres")
var sights: Logbook = preload("res://data/logbook/sights.tres")
var ships: ShipList = preload("res://data/ships/ships.tres")
var paints: PaintList = preload("res://data/ships/paints.tres")
var emails: EmailList = preload("res://data/pc/emails.tres")
var crew: CrewRoster = preload("res://data/crew/crew.tres")
## Every brand and snack in the galaxy's vending machines.
var brands: BrandCatalog = preload("res://data/brands/brands.tres")

## How much a new game starts with.
const STARTING_CREDITS: int = 150

## Where to put the bunny when the next room loads: the name of one of that
## room's spawn spots. Set when walking through a door.
var next_spawn: String = ""

# --- Saved -----------------------------------------------------------------------
## Money in the bank.
var credits: int = STARTING_CREDITS
## Story flags that have been reached ("first_mission_done": true...).
var flags: Dictionary = {}
## The job you're hauling (its id), or "" for none.
var active_job_id: String = ""
## When it's a freight market load (FreightMarket.gd): the load itself
## (made up on the board, so it's kept here, and saved as plain data).
var active_freight: JobData = null
## Freight loads already taken off this period's boards (their ids).
var taken_freight: Array[String] = []
## Makes this game's freight market its own (picked at new game).
var market_seed: int = 0
## Seconds flown on the current job (for rush bonuses).
var job_seconds: float = 0.0
## The rig's state between flights: both tanks, the hull and the cargo
## (1 = full / perfect), a snack from a truck stop (1 = had one this trip:
## steadier hands under boost), and whether this load's been weighed at a
## weigh station (1 = certified: a weigh slip bonus on delivery; 0.5 =
## weighed but overweight: fined, no slip).
var rig: Dictionary = {"fuel": 1.0, "boost_fuel": 1.0, "hull": 1.0, "cargo": 1.0, "snack": 0.0, "weighed": 0.0}
## The rigs you own (ids from res://data/ships/ships.tres), the one you
## drive, and its paint job.
var owned_ships: Array[String] = ["lazy_susan"]
var active_ship: String = "lazy_susan"
var paint: String = "factory"
## Upgrades bought (their ids).
var owned_upgrades: Array[String] = []
## Where the rig is parked (a place id): it launches from here, and the
## rig's airlock opens onto this place. (Home is the inside of the rig.)
## OPEN_SPACE is the start of a new game: drifting out past the company HQ.
var launch_from: String = "truck_stop"
## Parked in open space, out past the company HQ, where a new game starts
## (no station: the airlock opens onto vacuum).
const OPEN_SPACE: String = "open_space"
## The room you were last in (a scene path), for "Continue".
var current_room: String = ""
## Jobs that can't be done again (ids of delivered non-repeatable jobs).
var finished_jobs: Array[String] = []
## How many times you've docked at each place (place id -> count), so
## people can remember you (and Moe can finish his sentence).
var visits: Dictionary = {}
## How many deliveries you've made, ever (and how many were everyday
## freight market loads).
var deliveries: int = 0
var freight_delivered: int = 0
## The logbook: every sight you've seen (its id -> how many times).
var logbook: Dictionary = {}
## How many hauls (trips out on the road) you've started, ever. Route
## events use it for their cooldowns.
var hauls: int = 0
## Route events that have happened: event id -> the haul number it last
## happened on.
var event_history: Dictionary = {}
## Paid invoices for the PC (newest last): each is {"cargo", "client",
## "to", "total", "day"}. Only the latest INVOICE_LIMIT are kept.
var invoices: Array[Dictionary] = []
const INVOICE_LIMIT: int = 20
## Which day it is (day 1 = the day the game starts; see Economy.date_text
## for the calendar date).
var day: int = 1
## The time of day on the galaxy's clock, in minutes after midnight (0 to
## 1440). TimeOfDay.gd moves it on while you play.
var minute: float = 480.0
## When you took the job you're hauling (Economy.now_minutes), so the payout
## can say how long it was on the road.
var job_started: float = 0.0
## The debug menu's jump (autoload/DebugMenu.gd), not saved: {"place",
## "minutes"} for the flight to start that far out from that place.
var debug_jump: Dictionary = {}
## Show the date card (the day, the month, the year) when the next room or
## the flight comes up: set when a game is started or loaded.
var show_date_card: bool = false
## Bills you couldn't pay yet (Economy.gd): paid off from your next delivery.
var tab: int = 0
## Signed up for insurance at Dusty's (weekly premium, cheaper repairs).
var insured: bool = false
## Experience each rig has earned: rig id -> XP (see Economy.level_of).
var ship_xp: Dictionary = {}
## The best score in Asteroid Alley, the game on her PC.
var pc_high_score: int = 0
## Best scores on the TV console's games (TVConsole.gd): game id -> score.
var console_scores: Dictionary = {}
## Snacks and drinks she's tried from vending machines: product id -> how
## many times (the first taste of a brand, she reads the back of the packet).
var tasted: Dictionary = {}
## What the crew remember (see scenes/hub/ShipLife.gd): days of friendship,
## small talk already said, lost things found and handed back.
var crew_memory: Dictionary = {}

# --- Not saved -------------------------------------------------------------------
## The pay breakdown from a delivery that just happened, shown when you walk
## inside ({} = nothing to show).
var pending_payout: Dictionary = {}
## Checks waiting at the OrbitalEx office (the truck stop): one per
## delivery, until you check in (HubServices.check_in). Each is a delivery's
## pay breakdown (see deliver_at), at the employee rate. Owning the company,
## you're paid on the spot instead.
var checks: Array[Dictionary] = []
## The first check (a new game starts just after this delivery).
const PROLOGUE_CHECK := {"job": "prologue", "cargo_name": "Bulk kitty litter", "client_name": "Fizzwick Pet Supply",
		"base": 300, "care": 0, "rush": 0, "hold": 0, "total": 300, "condition": 1.0}
## New orders waiting at the OrbitalEx office (job ids): people tell you
## their problems, you tell them to call the company (see Conversation's
## places_order), and next time you check in, the boss hands you the job.
var orders: Array[String] = []
## The last weekly bills, waiting to be shown on the bills card (or {}).
var pending_bills: Dictionary = {}

## The smallest the game window can get. Everything is drawn at the screen's
## own resolution, from this up to 4K.
const MIN_WINDOW_SIZE := Vector2i(800, 600)

var _quitting := false


func _ready() -> void:
	# When the window's close button is clicked, let quit_game() handle it
	# instead of Godot closing on the spot.
	get_tree().auto_accept_quit = false
	get_tree().root.min_size = MIN_WINDOW_SIZE


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


# --- Story flags ------------------------------------------------------------------

## Whether the opening is still going: pull into the truck stop and
## collect your (tiny) check from the boss. (Saves from before the opening
## existed count as past it.)
func in_opening() -> bool:
	return not has_flag("met_boss") and not has_flag("met_marge")


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func set_flag(flag: String) -> void:
	if not flag.is_empty():
		flags[flag] = true


## Writes a sight in the logbook. Returns true the first time it's seen.
func log_sight(id: String) -> bool:
	if sights.find(id) == null:
		return false
	var first := not logbook.has(id)
	logbook[id] = int(logbook.get(id, 0)) + 1
	return first


## A new haul begins (the rig heads out on the road).
func start_haul() -> void:
	hauls += 1


## Notes that route event `id` just happened (on this haul).
func note_event(id: String) -> void:
	event_history[id] = hauls


## Counts a visit to a place (docking there). Returns how many visits
## that makes, this one included.
func visit(place_id: String) -> int:
	visits[place_id] = int(visits.get(place_id, 0)) + 1
	return visits[place_id]


# --- Money ------------------------------------------------------------------------

func add_credits(amount: int) -> void:
	credits += amount
	credits_changed.emit()
	if amount > 0:
		Sfx.play("cash")


## Pays `amount` if there's enough money. Returns whether it worked.
func spend(amount: int) -> bool:
	if amount > credits:
		return false
	credits -= amount
	credits_changed.emit()
	if amount > 0:
		Sfx.play("cash", -4.0, 0.9)  # A slightly lower ka-ching for paying out.
	return true


# --- Jobs -------------------------------------------------------------------------

## The job being hauled, or null.
func active_job() -> JobData:
	if active_job_id.is_empty():
		return null
	if FreightMarket.is_freight_id(active_job_id):
		return active_freight if active_freight != null and active_freight.id == active_job_id else null
	return jobs.find(active_job_id)


## Whether `job` can be offered right now (story flag reached, not a one-off
## that's already done).
func job_available(job: JobData) -> bool:
	if job == null:
		return false
	if not job.requires_flag.is_empty() and not has_flag(job.requires_flag):
		return false
	return job.repeatable or not job.id in finished_jobs


## The jobs on the board at `place_id`: the hand-written ones first, then
## the freight market's loads from there. ("base" is dispatch aboard the
## rig: the freight from wherever she's parked.)
func board_jobs(place_id: String) -> Array[JobData]:
	var found: Array[JobData] = []
	for job in jobs.jobs:
		if job != null and job.on_job_board and job.from_place == place_id and job_available(job):
			found.append(job)
	found.append_array(freight_board(launch_from if place_id == "base" else place_id))
	return found


## The freight market's loads on the board at `place_id` today (minus the
## ones already taken).
func freight_board(place_id: String) -> Array[JobData]:
	var period := freight.period_of(day)
	var found: Array[JobData] = []
	for job in freight.board(place_id, period, market_seed):
		if not job.id in taken_freight:
			found.append(job)
	return found


## Takes a job: fresh cargo, clock at zero. Only one job at a time.
func accept_job(job: JobData) -> bool:
	if job == null or not active_job_id.is_empty():
		return false
	active_job_id = job.id
	active_freight = null
	if FreightMarket.is_freight_id(job.id):
		active_freight = job
		# Off the board. (Old periods' ids are forgotten: those boards are gone.)
		var period := ":%d:" % freight.period_of(day)
		taken_freight = taken_freight.filter(func(id: String) -> bool: return period in id)
		taken_freight.append(job.id)
	orders.erase(job.id)
	job_seconds = 0.0
	job_started = Economy.now_minutes()
	rig["cargo"] = 1.0
	rig["weighed"] = 0.0  # (A new load needs its own weigh-in.)
	save_game()
	return true


## Delivers the current job at `place_id`, if that's where it's going: pays
## out and remembers the breakdown for the payout card. Returns whether a
## delivery happened.
func deliver_at(place_id: String) -> bool:
	var job := active_job()
	if job == null or job.to_place != place_id:
		return false
	var pay := job.pay_breakdown(rig.get("cargo", 1.0), job_seconds)
	# Bigger rigs carry more, and get paid more for it.
	var hold := roundi(job.base_pay * (active_ship_data().pay_bonus - 1.0))
	pay["hold"] = hold
	pay["total"] = int(pay["total"]) + hold
	# Weighed and certified at a weigh station on the way: a weigh slip bonus.
	var slip := roundi(job.base_pay * tuning.weigh_slip_bonus) if float(rig.get("weighed", 0.0)) >= 1.0 else 0
	pay["weigh"] = slip
	pay["total"] = int(pay["total"]) + slip
	rig["weighed"] = 0.0
	pay["job"] = job.id
	pay["cargo_name"] = job.cargo_name
	pay["client_name"] = job.client_name
	pay["condition"] = rig.get("cargo", 1.0)
	# Working for OrbitalEx, the check waits at their office until you check
	# in (minus their cut). Owning the company, it's all yours, right now.
	if has_flag("owns_company"):
		pay["paid_now"] = Economy.take_home(int(pay["total"]))
		add_credits(int(pay["paid_now"]))
	else:
		checks.append(pay.duplicate())
	# How long it was on the road (the calendar ran the whole way), and the
	# rig earns experience.
	pay["road_minutes"] = maxf(Economy.now_minutes() - job_started, 0.0)
	pay["xp"] = Economy.xp_for(int(pay["total"]))
	pay["levels"] = Economy.add_xp(int(pay["xp"]))
	pay["level"] = Economy.level_of()
	pay["tab_paid"] = Economy.settle_tab() if has_flag("owns_company") else 0
	pay["arrived_day"] = day
	var place := places.find(place_id)
	invoices.append({"cargo": job.cargo_name, "client": job.client_name,
			"to": place.display_name if place != null else place_id, "total": int(pay["total"]), "day": day})
	if invoices.size() > INVOICE_LIMIT:
		invoices.remove_at(0)
	set_flag(job.completes_flag)
	deliveries += 1
	# So people can remember how it went: "<job>_arrived_perfect", "_bumpy"
	# or "_rough". (Not for everyday freight: nobody's keeping score.)
	var condition: float = rig.get("cargo", 1.0)
	if not FreightMarket.is_freight_id(job.id):
		set_flag(job.id + ("_arrived_perfect" if condition >= 0.95 else ("_arrived_bumpy" if condition >= 0.7 else "_arrived_rough")))
	else:
		freight_delivered += 1
	if not job.repeatable:
		finished_jobs.append(job.id)
	active_job_id = ""
	active_freight = null
	job_seconds = 0.0
	pending_payout = pay
	save_game()
	return true


# --- The rig ----------------------------------------------------------------------

## The rig you're driving (its data file; see res://data/ships/).
func active_ship_data() -> ShipData:
	var ship := ships.find(active_ship)
	return ship if ship != null else ships.ships[0]


## The rig's numbers with every bought upgrade applied (a copy; the file in
## res://data/ships/ is never changed).
func upgraded_ship(base: ShipData) -> ShipData:
	var ship := base.duplicate() as ShipData
	for id in owned_upgrades:
		var upgrade := upgrades.find(id)
		if upgrade != null:
			upgrade.apply_to(ship)
	Economy.apply_level(ship, Economy.level_of(base.id))
	return ship


## The bolt-on parts you can see on the rig, from the upgrades you own (see
## RigAddOns.gd).
func owned_add_ons() -> PackedStringArray:
	var parts := PackedStringArray()
	for id in owned_upgrades:
		var upgrade := upgrades.find(id)
		if upgrade != null and upgrade.add_on != "none":
			parts.append(upgrade.add_on)
	return parts


func owns_upgrade(id: String) -> bool:
	return id in owned_upgrades


# --- Saving -----------------------------------------------------------------------

## Everything worth keeping, as plain data for the save file.
func to_save_data() -> Dictionary:
	return {
		"credits": credits,
		"flags": flags.keys(),
		"active_job": active_job_id,
		"active_freight": FreightMarket.to_save(active_freight) if active_freight != null else {},
		"taken_freight": taken_freight,
		"market_seed": market_seed,
		"freight_delivered": freight_delivered,
		"job_seconds": job_seconds,
		"rig": rig,
		"upgrades": owned_upgrades,
		"launch_from": launch_from,
		"room": current_room,
		"finished_jobs": finished_jobs,
		"visits": visits,
		"deliveries": deliveries,
		"logbook": logbook,
		"hauls": hauls,
		"event_history": event_history,
		"ships": owned_ships,
		"active_ship": active_ship,
		"paint": paint,
		"invoices": invoices,
		"day": day,
		"minute": minute,
		"job_started": job_started,
		"pc_high_score": pc_high_score,
		"tab": tab,
		"insured": insured,
		"ship_xp": ship_xp,
		"console_scores": console_scores,
		"tasted": tasted,
		"crew_memory": crew_memory,
		"checks": checks,
		"orders": orders,
	}


## Puts saved data back. Anything missing or the wrong type keeps its
## new-game value, so old or hand-edited saves can't break anything.
func apply_save_data(data: Dictionary) -> void:
	new_game()
	checks = []
	if data.get("checks") is Array:
		for check: Variant in data["checks"]:
			if check is Dictionary and ((check as Dictionary).get("total") is int or (check as Dictionary).get("total") is float):
				checks.append(check as Dictionary)
	if data.get("orders") is Array:
		for id: Variant in data["orders"]:
			if jobs.find(str(id)) != null:
				orders.append(str(id))
	if data.get("credits") is float or data.get("credits") is int:
		credits = int(data["credits"])
	if data.get("flags") is Array:
		for flag: Variant in data["flags"]:
			set_flag(str(flag))
	if data.get("active_job") is String and jobs.find(data["active_job"]) != null:
		active_job_id = data["active_job"]
	if data.get("market_seed") is int or data.get("market_seed") is float:
		market_seed = int(data["market_seed"])
	if data.get("freight_delivered") is int or data.get("freight_delivered") is float:
		freight_delivered = maxi(int(data["freight_delivered"]), 0)
	if data.get("taken_freight") is Array:
		for id: Variant in data["taken_freight"]:
			if FreightMarket.is_freight_id(str(id)):
				taken_freight.append(str(id))
	if data.get("active_freight") is Dictionary and data.get("active_job") is String and data["active_job"] == (data["active_freight"] as Dictionary).get("id"):
		active_freight = FreightMarket.from_save(data["active_freight"])
		if active_freight != null:
			active_job_id = active_freight.id
	if data.get("job_seconds") is float or data.get("job_seconds") is int:
		job_seconds = float(data["job_seconds"])
	if data.get("rig") is Dictionary:
		for key: String in rig:
			var value: Variant = data["rig"].get(key)
			if value is float or value is int:
				rig[key] = clampf(float(value), 0.0, 1.0)
	if data.get("upgrades") is Array:
		for id: Variant in data["upgrades"]:
			if upgrades.find(str(id)) != null and not str(id) in owned_upgrades:
				owned_upgrades.append(str(id))
	if data.get("launch_from") is String and (places.find(data["launch_from"]) != null or data["launch_from"] == OPEN_SPACE):
		launch_from = data["launch_from"]
	if launch_from == "base":
		launch_from = "truck_stop"  # Old saves: there's no home base in space any more.
	if data.get("room") is String and ResourceLoader.exists(data["room"]):
		current_room = data["room"]
	if data.get("finished_jobs") is Array:
		for id: Variant in data["finished_jobs"]:
			finished_jobs.append(str(id))
	if data.get("visits") is Dictionary:
		for id: Variant in data["visits"]:
			var count: Variant = data["visits"][id]
			if places.find(str(id)) != null and (count is int or count is float):
				visits[str(id)] = maxi(int(count), 0)
	if data.get("deliveries") is int or data.get("deliveries") is float:
		deliveries = maxi(int(data["deliveries"]), 0)
	if data.get("logbook") is Dictionary:
		for id: Variant in data["logbook"]:
			var times: Variant = data["logbook"][id]
			if sights.find(str(id)) != null and (times is int or times is float):
				logbook[str(id)] = maxi(int(times), 1)
	if data.get("hauls") is int or data.get("hauls") is float:
		hauls = maxi(int(data["hauls"]), 0)
	if data.get("event_history") is Dictionary:
		for id: Variant in data["event_history"]:
			var haul: Variant = data["event_history"][id]
			if haul is int or haul is float:
				event_history[str(id)] = maxi(int(haul), 0)
	if data.get("ships") is Array:
		for id: Variant in data["ships"]:
			if ships.find(str(id)) != null and not str(id) in owned_ships:
				owned_ships.append(str(id))
	if data.get("active_ship") is String and data["active_ship"] in owned_ships:
		active_ship = data["active_ship"]
	if data.get("paint") is String and paints.find(data["paint"]) != null:
		paint = data["paint"]
	if data.get("invoices") is Array:
		for entry: Variant in data["invoices"]:
			if entry is Dictionary:
				invoices.append({"cargo": str(entry.get("cargo", "")), "client": str(entry.get("client", "")),
						"to": str(entry.get("to", "")), "total": int(entry.get("total", 0)), "day": int(entry.get("day", 1))})
	if data.get("day") is int or data.get("day") is float:
		day = maxi(int(data["day"]), 1)
	if data.get("minute") is int or data.get("minute") is float:
		minute = clampf(float(data["minute"]), 0.0, 1439.0)
	if data.get("job_started") is int or data.get("job_started") is float:
		job_started = maxf(float(data["job_started"]), 0.0)
	if data.get("pc_high_score") is int or data.get("pc_high_score") is float:
		pc_high_score = maxi(int(data["pc_high_score"]), 0)
	if data.get("tab") is int or data.get("tab") is float:
		tab = maxi(int(data["tab"]), 0)
	if data.get("insured") is bool:
		insured = data["insured"]
	if data.get("ship_xp") is Dictionary:
		for id: Variant in data["ship_xp"]:
			var xp: Variant = data["ship_xp"][id]
			if xp is int or xp is float:
				ship_xp[str(id)] = maxi(int(xp), 0)
	if data.get("console_scores") is Dictionary:
		for game: Variant in data["console_scores"]:
			var best: Variant = data["console_scores"][game]
			if best is int or best is float:
				console_scores[str(game)] = maxi(int(best), 0)
	if data.get("tasted") is Dictionary:
		for id: Variant in data["tasted"]:
			var times: Variant = data["tasted"][id]
			if brands.find_product(str(id)) != null and (times is int or times is float):
				tasted[str(id)] = maxi(int(times), 0)
	if data.get("crew_memory") is Dictionary:
		# Plain numbers in little lists; anything odd is dropped.
		for list: Variant in data["crew_memory"]:
			var value: Variant = data["crew_memory"][list]
			if value is Dictionary:
				var clean := {}
				for key: Variant in value:
					if value[key] is int or value[key] is float:
						clean[str(key)] = int(value[key])
				crew_memory[str(list)] = clean
			elif value is int or value is float:
				crew_memory[str(list)] = int(value)
	credits_changed.emit()


## Someone called the company for a job (`job_id`): it waits at the office
## as a new order, unless it's already waiting, being hauled or done.
func place_order(job_id: String) -> void:
	if job_id in orders or job_id == active_job_id or job_id in finished_jobs:
		return
	orders.append(job_id)


## The orders waiting at the office that can be taken now, oldest first.
func waiting_orders() -> Array[JobData]:
	var found: Array[JobData] = []
	for id in orders:
		var job := jobs.find(id)
		if job != null and job.id != active_job_id and job_available(job):
			found.append(job)
	return found


## Cashes every check waiting at the office: adds what you take home and
## pays off any tab. Returns {"checks": the checks, "total": what you got,
## "tab_paid"}.
func collect_checks() -> Dictionary:
	var collected := checks.duplicate()
	var total := 0
	for check in collected:
		total += int(check.get("total", 0))
	checks.clear()
	if total > 0:
		add_credits(total)
	var tab_paid := Economy.settle_tab()
	save_game()
	return {"checks": collected, "total": total, "tab_paid": tab_paid}


## Back to the very start: no money to speak of, no story yet.
func new_game() -> void:
	credits = STARTING_CREDITS
	flags = {}
	active_job_id = ""
	active_freight = null
	taken_freight = []
	market_seed = randi()
	freight_delivered = 0
	job_seconds = 0.0
	rig = {"fuel": 1.0, "boost_fuel": 1.0, "hull": 1.0, "cargo": 1.0, "snack": 0.0, "weighed": 0.0}
	owned_upgrades = []
	owned_ships = ["lazy_susan"]
	active_ship = "lazy_susan"
	paint = "factory"
	launch_from = OPEN_SPACE  # She starts out in her rig, drifting past the company HQ.
	current_room = ""
	finished_jobs = []
	visits = {}
	deliveries = 0
	logbook = {}
	hauls = 0
	event_history = {}
	pending_payout = {}
	pending_bills = {}
	checks = [PROLOGUE_CHECK.duplicate()]  # The game starts just after a delivery.
	orders = []
	invoices = []
	day = 1
	minute = tuning.start_hour * 60.0
	job_started = 0.0
	tab = 0
	insured = false
	ship_xp = {}
	pc_high_score = 0
	console_scores = {}
	tasted = {}
	crew_memory = {}
	credits_changed.emit()


func save_game() -> void:
	SaveSystem.save_game(to_save_data())


## Loads the save file, if there is one. Returns whether there was.
func load_game() -> bool:
	var data := SaveSystem.load_game()
	if data.is_empty():
		return false
	apply_save_data(data)
	show_date_card = true
	return true


## Closes the game politely: stops every sound, gives the audio system a
## moment to let go of them, then quits. (Quitting while sounds are still
## playing makes Godot print a harmless but alarming "leaked at exit"
## warning.)
func quit_game() -> void:
	if _quitting:
		return
	_quitting = true
	Radio.stop_everything()
	_silence_everything()
	await get_tree().create_timer(0.1, true).timeout
	# Once more, in case something started a sound in the meantime (a scene
	# that was still loading, say).
	_silence_everything()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


## Stops every sound and lets go of it, so nothing is still holding audio
## when the game closes (that shows up as "leaked" warnings).
func _silence_everything() -> void:
	for type_name: String in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for player in get_tree().root.find_children("*", type_name, true, false):
			player.call("stop")
			player.set("stream", null)
