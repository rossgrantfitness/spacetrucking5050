extends SceneTree
## Used by tools/validate.sh: plays the first mission on autopilot, from a
## new game, to shake out errors in the story, menus and money:
##   arrive in the truck stop -> talk to Marge -> take the pie job -> visit
##   Lily's pumps -> board the rig -> get towed home -> see the payout card.
## It checks the job was taken, delivered and paid, then quits politely.
## It saves to a scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_mission.gd


enum Step { ARRIVE, TALK_TO_MARGE, VISIT_LILY, LEAVE_LILY, BOARD, FLY_HOME, PAYOUT, DONE }

var _frame := 0
var _step := Step.ARRIVE
var _step_started := 0
var _game: Node
var _credits_before := 0


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	_game = root.get_node("GameState")
	_game.call("new_game")
	_credits_before = _game.get("credits")
	_game.set("next_spawn", "FromShip")
	change_scene_to_file("res://scenes/hub/TruckStop.tscn")


func _process(_delta: float) -> bool:
	_frame += 1
	var waited := _frame - _step_started
	match _step:
		Step.ARRIVE:
			if _room_ready():
				_player().global_position = Vector3(-14.0, 0.0, -8.6)
				_next(Step.TALK_TO_MARGE)
		Step.TALK_TO_MARGE:
			# Keep pressing E: through her lines, then "TAKE THE JOB".
			if waited % 8 == 0:
				_tap("interact")
			if _game.get("active_job_id") == "first_pie_run" and not _busy():
				_player().global_position = Vector3(10.0, 0.0, 4.6)
				_next(Step.VISIT_LILY)
		Step.VISIT_LILY:
			if waited % 8 == 0:
				_tap("interact")
			if waited > 120:
				_next(Step.LEAVE_LILY)
		Step.LEAVE_LILY:
			# "Next" while she's talking, "back" to close her menu.
			if waited % 8 == 0:
				_tap("interact" if root.get_node("Dialogue").call("is_active") else "ui_cancel")
			if not _busy() and waited > 30:
				_player().global_position = Vector3(18.6, 0.0, 9.0)
				_next(Step.BOARD)
		Step.BOARD:
			if waited % 10 == 0:
				_tap("interact")
			if current_scene != null and current_scene.name == "FlightSandbox":
				_next(Step.FLY_HOME)
		Step.FLY_HOME:
			if waited == 60:
				current_scene.call("_arrive", "base")  # Get towed home.
			if waited > 60 and current_scene != null and current_scene.name == "Dispatch":
				_next(Step.PAYOUT)
		Step.PAYOUT:
			if _room_ready() and waited % 10 == 0:
				_tap("interact")  # Close the payout card.
			if waited > 200:
				_check_results()
				_next(Step.DONE)
				_game.call("quit_game")
	if _frame > 30000 and _step != Step.DONE:
		push_error("Smoke test: the first mission got stuck at step %s" % Step.keys()[_step])
		_step = Step.DONE
		_game.call("quit_game")
	return false


func _check_results() -> void:
	if not _game.call("has_flag", "first_mission_done"):
		push_error("Smoke test: delivering the pies should finish the first mission")
	if int(_game.get("credits")) <= _credits_before:
		push_error("Smoke test: delivering the pies should pay")
	if not (_game.get("pending_payout") as Dictionary).is_empty():
		push_error("Smoke test: the payout card should have been shown")


func _next(step: Step) -> void:
	_step = step
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
