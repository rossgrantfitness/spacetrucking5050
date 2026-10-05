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
var jobs: JobList = preload("res://data/jobs/jobs.tres")
var upgrades: UpgradeList = preload("res://data/upgrades/upgrades.tres")
var sights: Logbook = preload("res://data/logbook/sights.tres")
var ships: ShipList = preload("res://data/ships/ships.tres")
var paints: PaintList = preload("res://data/ships/paints.tres")

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
## Seconds flown on the current job (for rush bonuses).
var job_seconds: float = 0.0
## The rig's state between flights: both tanks, the hull and the cargo
## (1 = full / perfect), and a snack from a truck stop (1 = had one this
## trip: steadier hands under boost).
var rig: Dictionary = {"fuel": 1.0, "boost_fuel": 1.0, "hull": 1.0, "cargo": 1.0, "snack": 0.0}
## The rigs you own (ids from res://data/ships/ships.tres), the one you
## drive, and its paint job.
var owned_ships: Array[String] = ["lazy_susan"]
var active_ship: String = "lazy_susan"
var paint: String = "factory"
## Upgrades bought (their ids).
var owned_upgrades: Array[String] = []
## Which place the rig launches from next time you board (a place id).
var launch_from: String = "base"
## The room you were last in (a scene path), for "Continue".
var current_room: String = ""
## Jobs that can't be done again (ids of delivered non-repeatable jobs).
var finished_jobs: Array[String] = []
## How many times you've docked at each place (place id -> count), so
## people can remember you (and Moe can finish his sentence).
var visits: Dictionary = {}
## How many deliveries you've made, ever.
var deliveries: int = 0
## The logbook: every sight you've seen (its id -> how many times).
var logbook: Dictionary = {}
## How many hauls (trips out on the road) you've started, ever. Route
## events use it for their cooldowns.
var hauls: int = 0
## Route events that have happened: event id -> the haul number it last
## happened on.
var event_history: Dictionary = {}

# --- Not saved -------------------------------------------------------------------
## The pay breakdown from a delivery that just happened, shown when you walk
## inside ({} = nothing to show).
var pending_payout: Dictionary = {}

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


## Pays `amount` if there's enough money. Returns whether it worked.
func spend(amount: int) -> bool:
	if amount > credits:
		return false
	credits -= amount
	credits_changed.emit()
	return true


# --- Jobs -------------------------------------------------------------------------

## The job being hauled, or null.
func active_job() -> JobData:
	return jobs.find(active_job_id) if not active_job_id.is_empty() else null


## Whether `job` can be offered right now (story flag reached, not a one-off
## that's already done).
func job_available(job: JobData) -> bool:
	if job == null:
		return false
	if not job.requires_flag.is_empty() and not has_flag(job.requires_flag):
		return false
	return job.repeatable or not job.id in finished_jobs


## The jobs on the board at `place_id`.
func board_jobs(place_id: String) -> Array[JobData]:
	var found: Array[JobData] = []
	for job in jobs.jobs:
		if job != null and job.on_job_board and job.from_place == place_id and job_available(job):
			found.append(job)
	return found


## Takes a job: fresh cargo, clock at zero. Only one job at a time.
func accept_job(job: JobData) -> bool:
	if job == null or not active_job_id.is_empty():
		return false
	active_job_id = job.id
	job_seconds = 0.0
	rig["cargo"] = 1.0
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
	pay["job"] = job.id
	pay["cargo_name"] = job.cargo_name
	pay["client_name"] = job.client_name
	pay["condition"] = rig.get("cargo", 1.0)
	add_credits(pay["total"])
	set_flag(job.completes_flag)
	deliveries += 1
	# So people can remember how it went: "<job>_arrived_perfect", "_bumpy"
	# or "_rough".
	var condition: float = rig.get("cargo", 1.0)
	set_flag(job.id + ("_arrived_perfect" if condition >= 0.95 else ("_arrived_bumpy" if condition >= 0.7 else "_arrived_rough")))
	if not job.repeatable:
		finished_jobs.append(job.id)
	active_job_id = ""
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
	return ship


func owns_upgrade(id: String) -> bool:
	return id in owned_upgrades


# --- Saving -----------------------------------------------------------------------

## Everything worth keeping, as plain data for the save file.
func to_save_data() -> Dictionary:
	return {
		"credits": credits,
		"flags": flags.keys(),
		"active_job": active_job_id,
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
	}


## Puts saved data back. Anything missing or the wrong type keeps its
## new-game value, so old or hand-edited saves can't break anything.
func apply_save_data(data: Dictionary) -> void:
	new_game()
	if data.get("credits") is float or data.get("credits") is int:
		credits = int(data["credits"])
	if data.get("flags") is Array:
		for flag: Variant in data["flags"]:
			set_flag(str(flag))
	if data.get("active_job") is String and jobs.find(data["active_job"]) != null:
		active_job_id = data["active_job"]
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
	if data.get("launch_from") is String and places.find(data["launch_from"]) != null:
		launch_from = data["launch_from"]
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
	credits_changed.emit()


## Back to the very start: no money to speak of, no story yet.
func new_game() -> void:
	credits = STARTING_CREDITS
	flags = {}
	active_job_id = ""
	job_seconds = 0.0
	rig = {"fuel": 1.0, "boost_fuel": 1.0, "hull": 1.0, "cargo": 1.0, "snack": 0.0}
	owned_upgrades = []
	owned_ships = ["lazy_susan"]
	active_ship = "lazy_susan"
	paint = "factory"
	launch_from = "base"
	current_room = ""
	finished_jobs = []
	visits = {}
	deliveries = 0
	logbook = {}
	hauls = 0
	event_history = {}
	pending_payout = {}
	credits_changed.emit()


func save_game() -> void:
	SaveSystem.save_game(to_save_data())


## Loads the save file, if there is one. Returns whether there was.
func load_game() -> bool:
	var data := SaveSystem.load_game()
	if data.is_empty():
		return false
	apply_save_data(data)
	return true


## Closes the game politely: stops every sound, gives the audio system a
## moment to let go of them, then quits. (Quitting while sounds are still
## playing makes Godot print a harmless but alarming "leaked at exit"
## warning.)
func quit_game() -> void:
	if _quitting:
		return
	_quitting = true
	for type_name: String in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for player in get_tree().root.find_children("*", type_name, true, false):
			player.call("stop")
	Radio.stop_everything()
	await get_tree().create_timer(0.1, true).timeout
	get_tree().quit()
