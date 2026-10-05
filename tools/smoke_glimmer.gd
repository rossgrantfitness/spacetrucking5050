extends SceneTree
## Used by tools/validate.sh: plays the trip to the Glimmer System on
## autopilot, to shake out errors in the new system:
##   with Sal's cards loaded, the cruise autopilot flies into The High
##   Roller's ring -> climb out in the casino: payout card -> talk to Sal
##   (he introduces himself, then offers the jumpsuits; take them) -> pull
##   the slot machine a few times -> board the rig again.
## It checks the delivery paid and opened up Glimmer, Sal's story moved on,
## the slots took a pull, and the rig launches from the casino.
## It saves to a scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_glimmer.gd


enum Step { FLY, AT_CASINO, TALK_TO_SAL, PLAY_SLOTS, BOARD, SETTLE, DONE }

var _frame := 0
var _step := Step.FLY
var _step_started := 0
var _game: Node
var _credits_before := 0


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	_game = root.get_node("GameState")
	_game.call("new_game")
	for flag in ["met_marge", "first_mission_done", "glimmer_heard"]:
		_game.call("set_flag", flag)
	var jobs: Resource = _game.get("jobs")
	_game.call("accept_job", jobs.call("find", "glimmer_cards"))
	_game.set("launch_from", "truck_stop")
	_credits_before = _game.get("credits")
	change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")


func _process(_delta: float) -> bool:
	_frame += 1
	var waited := _frame - _step_started
	match _step:
		Step.FLY:
			if waited == 60:
				# Skip most of the 56 km: start 1.8 km out from the casino's
				# ring and let the cruise autopilot take it from there.
				Engine.time_scale = 4.0
				_put_ship_before("World/Places/high_roller/ApproachRing", 1800.0)
				current_scene.call("engage_course", PackedStringArray(["high_roller"]))
			if current_scene != null and current_scene.name == "HighRollerLounge":
				Engine.time_scale = 1.0
				_next(Step.AT_CASINO)
		Step.AT_CASINO:
			# Close the payout card.
			if _room_ready() and waited % 10 == 0:
				_tap("interact")
			if _room_ready() and waited > 150 and not _busy():
				_check_delivery()
				_player().global_position = Vector3(-7.0, 0.0, -3.3)
				_next(Step.TALK_TO_SAL)
		Step.TALK_TO_SAL:
			# Keep pressing E: his hello, then his pitch, then "TAKE THE JOB".
			if waited % 8 == 0:
				_tap("interact")
			if _game.get("active_job_id") == "sal_jumpsuits" and not _busy():
				_player().global_position = Vector3(6.6, 0.0, 2.6)
				_next(Step.PLAY_SLOTS)
		Step.PLAY_SLOTS:
			# Open the machine, pull three times, walk away.
			if waited in [10, 40, 70, 100]:
				_tap("interact")
			if waited == 140:
				_tap("ui_cancel")
			if waited > 170 and not _busy():
				if not _game.call("has_flag", "played_slots"):
					push_error("Smoke Glimmer: the slot machine should have taken a pull")
				_player().global_position = Vector3(9.8, 0.0, 5.8)
				_next(Step.BOARD)
		Step.BOARD:
			if waited % 10 == 0 and current_scene != null and current_scene.name == "HighRollerLounge":
				_tap("interact")
			if current_scene != null and current_scene.name == "FlightSandbox":
				if _game.get("launch_from") != "high_roller":
					push_error("Smoke Glimmer: after the casino, the rig should launch from there")
				_next(Step.SETTLE)
		Step.SETTLE:
			# Let the flight settle for a few seconds before quitting (quitting
			# while it's still starting up can leave sounds half-released).
			if waited > 300:
				_next(Step.DONE)
				_game.call("quit_game")
	if _frame > 30000 and _step != Step.DONE:
		push_error("Smoke Glimmer: got stuck at step %s" % Step.keys()[_step])
		_step = Step.DONE
		_game.call("quit_game")
	return false


func _check_delivery() -> void:
	if not _game.call("has_flag", "glimmer_open"):
		push_error("Smoke Glimmer: delivering Sal's cards should open up the Glimmer System")
	if int(_game.get("credits")) <= _credits_before:
		push_error("Smoke Glimmer: delivering the cards should pay")
	if not (_game.get("pending_payout") as Dictionary).is_empty():
		push_error("Smoke Glimmer: the payout card should have been shown")


## Puts the rig `meters` out in front of an approach ring, pointed at it.
func _put_ship_before(ring_path: String, meters: float) -> void:
	var ship := current_scene.get_node("World/Ship")
	var ring: Node3D = current_scene.get_node(ring_path)
	var through: Vector3 = ring.call("through_direction")
	ship.call("teleport", Transform3D(Basis.looking_at(through, Vector3.UP), ring.global_position - through * meters))


func _next(step: Step) -> void:
	_step = step
	print("Smoke Glimmer: ", Step.keys()[step])
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
