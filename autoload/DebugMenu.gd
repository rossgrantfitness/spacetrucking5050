extends Node
## The DEBUG MENU, for testing without playing the whole way there. Press
## F10 anywhere (on foot or flying) to open it:
##   - JUMP NEAR A PLACE: puts the rig a few minutes out from a station
##     (1, 3 or 5 minutes at cruise speed), on autopilot and lined up, so
##     you can test an arrival without a full run. (From on foot it takes
##     off first.)
##   - GIVE ME A JOB: any job in the game, yours right now (handy for
##     testing heavy loads), whatever the story says.
##   - SKIP THE OPENING, +5,000 credits, and a free fill-up and repair.
##   - STORY: SKIP TO...: jumps to a point in {husband}'s story (see
##     docs/STORY.md), so you can test one beat without 14 deliveries.
##
## Also from the command line (handy for automated tests):
##     godot --path . -- --jump=tidewater:3
## starts the game straight into flight, 3 minutes out from Tidewater.
##
## Turn it off for release builds with `enabled` below (or debug_menu in
## tuning.tres).


## Places you can jump near, in menu order (place ids).
const JUMP_PLACES: PackedStringArray = ["tidewater", "truck_stop", "high_roller", "gas_n_go"]
const JUMP_MINUTES: Array[int] = [1, 3, 5]
const FLIGHT_SCENE: String = "res://scenes/flight/FlightSandbox.tscn"
## The story's beats, in order: [name, what happens next, flags set by
## then, deliveries made by then, story jobs delivered by then]. Each beat
## includes everything before it.
const STORY_BEATS: Array = [
	["MARGE KNOWS THE RIG", "Talk to Marge at the truck stop.", ["first_mission_done"], 2, []],
	["MARGE'S PIE", "Marge offers his standing order: a pie for Gill.", ["marge_mentioned_white"], 4, []],
	["GILL AND THE PIE", "Talk to Gill at Tidewater.", ["white_pie_done"], 5, ["white_pie"]],
	["DUSTY'S CHIP", "Talk to Dusty at the truck stop.", ["gill_talked_white"], 6, []],
	["THE MESSAGE", "Fly anywhere: it plays about 45 s after takeoff.", ["white_chip"], 6, []],
	["THE LAST LOAD", "Talk to the boss at the office.", ["white_voicemail", "story_call_white_message"], 6, []],
	["THE TAPES", "Talk to Gill at Tidewater.", ["white_last_load_done"], 7, ["white_last_load"]],
	["AFTER", "White Noise is on the dial; people remember.", ["white_story_done"], 7, []],
]

var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_from_command_line.call_deferred()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_F10:
		return
	if not GameState.tuning.debug_menu or _open:
		return
	get_viewport().set_input_as_handled()
	open()


## Shows the debug menu and does what's picked.
func open() -> void:
	_open = true
	var mouse := Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tree := get_tree()
	var options: Array = []
	for id in JUMP_PLACES:
		var place := GameState.places.find(id)
		options.append({"text": "JUMP NEAR " + (place.display_name if place != null else id.to_upper()),
				"description": "Start a few minutes out from here, on autopilot, lined up for the approach."})
	options.append({"text": "GIVE ME A JOB", "description": "Any job in the game, yours right now (drops the one you're hauling)."})
	options.append({"text": "SKIP THE OPENING", "description": "As if you'd collected your first check from the boss and met Marge."})
	options.append({"text": "+5,000 CREDITS", "description": "Free money. Don't tell the tax droids."})
	options.append({"text": "FILL UP AND FIX UP", "description": "Both tanks full, hull and cargo like new."})
	options.append({"text": "STORY: SKIP TO...", "description": "Jump to a point in the story, to test one beat."})
	options.append({"text": "CLOSE", "description": ""})
	var pick := await MenuPanel.ask(tree, "DEBUG MENU", "For testing. (F10 to open; turn off with debug_menu in tuning.tres.)", options)
	if pick >= 0 and pick < JUMP_PLACES.size():
		var minutes_options: Array = []
		for minutes in JUMP_MINUTES:
			minutes_options.append({"text": "%d MINUTE%s OUT" % [minutes, "" if minutes == 1 else "S"], "description": "At cruise speed."})
		var how_far := await MenuPanel.ask(tree, "HOW FAR OUT?", "", minutes_options)
		if how_far >= 0:
			_open = false
			jump(JUMP_PLACES[pick], JUMP_MINUTES[how_far])
			return
	match pick - JUMP_PLACES.size():
		0:
			await _give_job()
		1:
			skip_opening()
		2:
			GameState.add_credits(5000)
		3:
			_fill_up()
		4:
			await _story_menu()
	_open = false
	Input.mouse_mode = mouse


## Puts the rig `minutes` out from `place_id`. In flight it's instant;
## anywhere else it takes off first.
func jump(place_id: String, minutes: float) -> void:
	GameState.debug_jump = {"place": place_id, "minutes": minutes}
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("debug_jump") and scene.scene_file_path == FLIGHT_SCENE:
		scene.call("debug_jump")
	else:
		LoadingScreen.go(get_tree(), FLIGHT_SCENE, "flight")


## Past the opening: the first check collected, Marge met.
func skip_opening() -> void:
	for flag in ["opening_called", "met_boss", "first_check", "boss_sent_to_marge", "heard_about_marge", "met_marge"]:
		GameState.set_flag(flag)
	GameState.checks = GameState.checks.filter(func(check: Dictionary) -> bool: return check.get("job") != "prologue")
	if GameState.launch_from == GameState.OPEN_SPACE:
		GameState.launch_from = "truck_stop"


## Lists every job (with its weight) and hands over the one picked.
func _give_job() -> void:
	var jobs: Array = []
	var options: Array = []
	for job: JobData in GameState.jobs.jobs:
		if job == null:
			continue
		jobs.append(job)
		var to := GameState.places.find(job.to_place)
		options.append({"text": "%s  (%s)" % [job.cargo_name.to_upper(), HudWidget.tons_text(job.weight)],
				"description": "To %s. %s" % [to.display_name if to != null else "?", HubServices.job_summary(job)]})
	var pick := await MenuPanel.ask(get_tree(), "GIVE ME A JOB", "Any job, right now.", options)
	if pick < 0 or pick >= jobs.size():
		return
	GameState.active_job_id = ""
	GameState.accept_job(jobs[pick] as JobData)
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("debug_jump"):
		scene.call("_set_destination", scene.call("_pick_destination"))


func _story_menu() -> void:
	var options: Array = []
	for beat: Array in STORY_BEATS:
		options.append({"text": beat[0], "description": beat[1]})
	var pick := await MenuPanel.ask(get_tree(), "STORY: SKIP TO...", "Sets the story up as if you'd played to here. Then go do the next thing.", options)
	if pick >= 0 and pick < STORY_BEATS.size():
		story_jump(pick)


## Sets the story up as if you'd played up to beat `index` (STORY_BEATS).
func story_jump(index: int) -> void:
	skip_opening()
	for i in index + 1:
		var beat: Array = STORY_BEATS[i]
		for flag: String in beat[2]:
			GameState.set_flag(flag)
		GameState.deliveries = maxi(GameState.deliveries, int(beat[3]))
		for job_id: String in beat[4]:
			GameState.set_flag(job_id + "_arrived_perfect")
			if not job_id in GameState.finished_jobs:
				GameState.finished_jobs.append(job_id)
	GameState.save_game()


func _fill_up() -> void:
	for key in ["fuel", "boost_fuel", "hull", "cargo"]:
		GameState.rig[key] = 1.0
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("debug_jump"):
		scene.call("_restore_rig")


## "--jump=tidewater:3" after "--" on the command line: straight into flight.
func _start_from_command_line() -> void:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--jump="):
			continue
		var parts := arg.trim_prefix("--jump=").split(":")
		if SaveSystem.has_save():
			GameState.load_game()
		skip_opening()
		jump(parts[0], float(parts[1]) if parts.size() > 1 else 3.0)
		return
