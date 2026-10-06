extends "res://tools/tests/TestSuite.gd"
## Checks for round 14's desktop PC: the inbox, the invoices and the little
## game, Asteroid Alley. Every test puts GameState back the way it found it,
## and saving goes to a scratch file.

const SCRATCH_SAVE: String = "user://self_test_save.json"


func _fresh() -> Dictionary:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	return before


func _restore(before: Dictionary) -> void:
	GameState.apply_save_data(before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_SAVE))
	SaveSystem.save_path = "user://save.json"


func test_mail_arrives_with_the_story() -> void:
	var ids := {}
	for email in GameState.emails.emails:
		check(not ids.has(email.id), "email ids are unique (%s)" % email.id)
		ids[email.id] = true
		check(not email.subject.is_empty() and not email.body.is_empty(), "%s has a subject and a body" % email.id)
	var at_start := GameState.emails.inbox({})
	check(at_start.size() >= 3, "a new game starts with a few emails waiting")
	var later := GameState.emails.inbox({"first_mission_done": true})
	check(later.size() > at_start.size(), "more mail arrives as the story moves along")
	check(later[0].requires_flag == "first_mission_done", "the newest mail comes first")


func test_deliveries_become_invoices() -> void:
	var before := _fresh()
	GameState.accept_job(GameState.jobs.find("first_long_haul"))
	check(GameState.deliver_at("tidewater"), "the first long haul delivers at Tidewater")
	# A 7-day haul crosses into week 2, so the weekly bills are on the list too.
	check(GameState.invoices.size() == 2 and int(GameState.invoices[1]["total"]) < 0, "a delivery leaves a paid invoice (and the week's bills)")
	var invoice := GameState.invoices[0]
	check(int(invoice["total"]) > 0 and str(invoice["to"]) == GameState.places.find("tidewater").display_name, "the invoice says what it paid and where")
	var saved := GameState.to_save_data()
	GameState.new_game()
	GameState.apply_save_data(saved)
	check(GameState.invoices.size() == 2, "invoices are saved")
	_restore(before)


func test_old_saves_from_the_home_base_wake_up_at_the_truck_stop() -> void:
	var before := _fresh()
	var old := GameState.to_save_data()
	old["launch_from"] = "base"
	GameState.apply_save_data(old)
	check(GameState.launch_from == "truck_stop", "an old save parked at the home base wakes up at the truck stop")
	_restore(before)


func test_asteroid_alley_is_fair_and_ends_in_a_bonk() -> void:
	var game := AsteroidAlley.new()
	check(game.state == AsteroidAlley.State.TITLE, "it starts on the title screen")
	game.start()
	game.steer(-1)
	game.steer(-1)
	check(game.lane == 0, "you can't hop off the left edge")
	var bonked := false
	for i in 4000:
		# Never all three lanes blocked at once: there's always a way through.
		var rows := {}
		for thing in game.things:
			if thing["kind"] == "rock":
				var row := roundi(float(thing["y"]))
				rows[row] = int(rows.get(row, 0)) + 1
		for row: int in rows:
			check(rows[row] < AsteroidAlley.LANES, "a row of rocks always leaves a lane open")
		if game.step(1.0 / 30.0) == "bonk":
			bonked = true
			break
	check(bonked and game.state == AsteroidAlley.State.OVER, "sitting still, a rock gets you sooner or later")
	check(game.score > 0, "you score for every bit of road")
	check(game.speed > AsteroidAlley.START_SPEED, "it gets faster the longer you last")
