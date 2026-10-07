extends SceneTree
## Used by tools/validate.sh: plays the trip to the Frostline (the farthest,
## steepest of Beta 4's systems) on autopilot:
##   with Penny's waffle cones loaded, the cruise autopilot flies the last
##   stretch up into Flurry's Comet Creamery's tilted ring -> climb out in
##   the parlor: payout card -> talk to Penny (she says hello, then tells
##   her the freezer died and calls the company: a new order) -> board the
##   rig again.
## It checks the delivery paid and opened up the Frostline, Penny's story
## moved on, and the rig launches from the creamery.
## It saves to a scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_frontier.gd


enum Step { FLY, AT_CREAMERY, TALK_TO_PENNY, BOARD, SETTLE, DONE }

var _frame := 0
var _step := Step.FLY
var _step_started := 0
var _game: Node


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	_game = root.get_node("GameState")
	_game.call("new_game")
	for flag in ["met_boss", "met_marge", "first_mission_done", "glimmer_heard", "glimmer_open", "dustbowl_heard", "dustbowl_open",
			"greenhouse_heard", "greenhouse_open", "frostline_heard"]:
		_game.call("set_flag", flag)
	var jobs: Resource = _game.get("jobs")
	_game.call("accept_job", jobs.call("find", "frostline_cones"))
	_game.set("launch_from", "truck_stop")
	change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")


func _process(_delta: float) -> bool:
	_frame += 1
	var waited := _frame - _step_started
	match _step:
		Step.FLY:
			if waited == 60:
				# Skip most of the climb: start 1.8 km out from the creamery's
				# ring and let the cruise autopilot take it from there.
				Engine.time_scale = 4.0
				_put_ship_before("World/Places/creamery/ApproachRing", 1800.0)
				current_scene.call("engage_course", PackedStringArray(["creamery"]))
			if current_scene != null and current_scene.name == "Creamery":
				Engine.time_scale = 1.0
				_next(Step.AT_CREAMERY)
		Step.AT_CREAMERY:
			# Close the payout card.
			if _room_ready() and waited % 10 == 0:
				_tap("interact")
			if _room_ready() and waited > 150 and not _busy():
				_check_delivery()
				_player().global_position = Vector3(-7.0, 0.0, -3.3)
				_next(Step.TALK_TO_PENNY)
		Step.TALK_TO_PENNY:
			# Keep pressing E: her hello, then the freezer, then "GOT IT".
			if waited % 8 == 0:
				_tap("interact")
			if "penny_freezer" in (_game.get("orders") as Array) and not _busy():
				if not _game.call("has_flag", "penny_met"):
					push_error("Smoke Frontier: Penny should have introduced herself")
				_player().global_position = Vector3(9.8, 0.0, 5.8)
				_next(Step.BOARD)
		Step.BOARD:
			# Board the rig (into its hallway), through dispatch, up to the
			# cockpit door.
			if current_scene != null and current_scene.get("_ready_to_play") == true:
				match current_scene.name:
					"Hallway":
						if _player().global_position.z > -19.0:
							_player().global_position = Vector3(0.0, 0.0, -19.6)
					"Dispatch":
						if _player().global_position.y < 2.0:
							_player().global_position = Vector3(3.6, 2.45, -3.6)
						if waited % 10 == 0:
							_tap("interact")
					_:
						if waited % 10 == 0:
							_tap("interact")
			if current_scene != null and current_scene.name == "FlightSandbox":
				if _game.get("launch_from") != "creamery":
					push_error("Smoke Frontier: after the creamery, the rig should launch from there")
				_next(Step.SETTLE)
		Step.SETTLE:
			# Let the flight settle for a few seconds before quitting (quitting
			# while it's still starting up can leave sounds half-released).
			if waited > 300:
				_next(Step.DONE)
				_game.call("quit_game")
	if _frame > 30000 and _step != Step.DONE:
		push_error("Smoke Frontier: got stuck at step %s" % Step.keys()[_step])
		_step = Step.DONE
		_game.call("quit_game")
	return false


func _check_delivery() -> void:
	if not _game.call("has_flag", "frostline_open"):
		push_error("Smoke Frontier: delivering Penny's cones should open up the Frostline")
	var checks: Array = _game.get("checks")
	if checks.is_empty() or str((checks.back() as Dictionary).get("job")) != "frostline_cones":
		push_error("Smoke Frontier: delivering the cones should leave a check at the office")
	if not (_game.get("pending_payout") as Dictionary).is_empty():
		push_error("Smoke Frontier: the payout card should have been shown")


## Puts the rig `meters` out in front of an approach ring, pointed at it.
func _put_ship_before(ring_path: String, meters: float) -> void:
	var ship := current_scene.get_node("World/Ship")
	var ring: Node3D = current_scene.get_node(ring_path)
	var through: Vector3 = ring.call("through_direction")
	ship.call("teleport", Transform3D(Basis.looking_at(through, Vector3.UP), ring.global_position - through * meters))


func _next(step: Step) -> void:
	_step = step
	print("Smoke Frontier: ", Step.keys()[step])
	_step_started = _frame


func _room_ready() -> bool:
	return current_scene != null and current_scene.get("_ready_to_play") == true


func _player() -> Node3D:
	return current_scene.get("player") as Node3D


func _busy() -> bool:
	var player := _player()
	return player == null or player.call("is_busy")


func _tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
