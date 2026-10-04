extends SceneTree
## Used by tools/validate.sh: plays the first mission on autopilot, from a
## new game, to shake out errors in the story, menus and money:
##   arrive in the truck stop -> talk to Marge -> take the long haul -> visit
##   Lily's pumps -> board the rig -> (skip most of the road) -> the cruise
##   autopilot flies into Tidewater's ring -> docked: payout card, counter,
##   launch again -> chart a course through the Gas-N-Go drive-through and
##   roll out the far side.
## It checks the job was taken, delivered and paid, then quits politely.
## It saves to a scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_mission.gd


enum Step { ARRIVE, TALK_TO_MARGE, VISIT_LILY, LEAVE_LILY, BOARD, FLY_OUT, DROP_OFF, DRIVE_THROUGH, DONE }

var _frame := 0
var _step := Step.ARRIVE
var _step_started := 0
var _game: Node
var _credits_before := 0
var _rolled_out := false


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
			if _game.get("active_job_id") == "first_long_haul" and not _busy():
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
				_next(Step.FLY_OUT)
		Step.FLY_OUT:
			if waited == 60:
				# Skip most of the 59 km: start 1.8 km out from Tidewater's
				# ring and let the cruise autopilot take it from there.
				Engine.time_scale = 4.0
				_put_ship_before("World/Places/tidewater/ApproachRing", 1800.0)
				current_scene.call("engage_course", PackedStringArray(["tidewater"]))
			if waited > 60 and current_scene.get("_at_counter") == true:
				_next(Step.DROP_OFF)
		Step.DROP_OFF:
			# Close the payout card, then leave the counter.
			if waited % 15 == 0:
				_tap("ui_cancel")
			if waited > 60 and current_scene.get("_at_counter") == false and current_scene.get("_docking_at") == "":
				_check_results()
				_put_ship_before("World/Places/gas_n_go/ApproachRing", 1500.0)
				current_scene.call("engage_course", PackedStringArray(["gas_n_go", "base"]))
				_next(Step.DRIVE_THROUGH)
		Step.DRIVE_THROUGH:
			if waited % 15 == 0 and current_scene.get("_at_counter") == true:
				_tap("ui_cancel")
			if current_scene.get("_leaving") == true:
				_rolled_out = true
			if _rolled_out and current_scene.get("_leaving") == false:
				var ship := current_scene.get_node("World/Ship")
				if ship.get("cruise") == null:
					push_error("Smoke test: after the drive-through, the autopilot should carry on to the next stop")
				if (ship.get("velocity") as Vector3).length() < 10.0:
					push_error("Smoke test: rolling out of a drive-through should keep the rig moving")
				Engine.time_scale = 1.0
				_next(Step.DONE)
				_game.call("quit_game")
	if _frame > 60000 and _step != Step.DONE:
		push_error("Smoke test: the first mission got stuck at step %s" % Step.keys()[_step])
		_step = Step.DONE
		_game.call("quit_game")
	return false


func _check_results() -> void:
	if not _game.call("has_flag", "first_mission_done"):
		push_error("Smoke test: delivering the pies to Tidewater should finish the first mission")
	if int(_game.get("credits")) <= _credits_before:
		push_error("Smoke test: delivering the pies should pay")
	if not (_game.get("pending_payout") as Dictionary).is_empty():
		push_error("Smoke test: the payout card should have been shown")
	if _game.get("launch_from") != "tidewater":
		push_error("Smoke test: after the drop-off, the rig should launch from Tidewater")


## Puts the rig `meters` out in front of an approach ring, pointed at it.
## (Game classes like Ship can't be named here: this script is compiled
## before the autoloads they use exist.)
func _put_ship_before(ring_path: String, meters: float) -> void:
	var ship := current_scene.get_node("World/Ship")
	var ring: Node3D = current_scene.get_node(ring_path)
	var through: Vector3 = ring.call("through_direction")
	ship.call("teleport", Transform3D(Basis.looking_at(through, Vector3.UP), ring.global_position - through * meters))


func _next(step: Step) -> void:
	_step = step
	print("Smoke mission: ", Step.keys()[step])
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
