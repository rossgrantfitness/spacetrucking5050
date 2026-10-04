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
## (1 = full / perfect).
var rig: Dictionary = {"fuel": 1.0, "boost_fuel": 1.0, "hull": 1.0, "cargo": 1.0}
## Upgrades bought (their ids).
var owned_upgrades: Array[String] = []
## Which place the rig launches from next time you board (a place id).
var launch_from: String = "base"
## The room you were last in (a scene path), for "Continue".
var current_room: String = ""
## Jobs that can't be done again (ids of delivered non-repeatable jobs).
var finished_jobs: Array[String] = []

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
	pay["job"] = job.id
	pay["cargo_name"] = job.cargo_name
	pay["client_name"] = job.client_name
	pay["condition"] = rig.get("cargo", 1.0)
	add_credits(pay["total"])
	set_flag(job.completes_flag)
	if not job.repeatable:
		finished_jobs.append(job.id)
	active_job_id = ""
	job_seconds = 0.0
	pending_payout = pay
	save_game()
	return true


# --- The rig ----------------------------------------------------------------------

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
	credits_changed.emit()


## Back to the very start: no money to speak of, no story yet.
func new_game() -> void:
	credits = STARTING_CREDITS
	flags = {}
	active_job_id = ""
	job_seconds = 0.0
	rig = {"fuel": 1.0, "boost_fuel": 1.0, "hull": 1.0, "cargo": 1.0}
	owned_upgrades = []
	launch_from = "base"
	current_room = ""
	finished_jobs = []
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
