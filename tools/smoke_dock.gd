extends SceneTree
## Used by tools/validate.sh: plays the loading dock (scenes/dock/). Climbs
## onto the forklift, drives it a little (checks it moves), then for each
## pallet: lines the forks up under it, lifts it, carries it to a glowing
## spot in the hold and sets it down. Checks every pallet snapped into a
## spot, the load is snug, and she's back in the truck stop where she was.
## Saves to a scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_dock.gd


const RETURN_SPOT := Vector3(-11.5, 0.0, 12.2)

var _time := 0.0
var _stage := "start"
var _stage_time := 0.0
var _pallet := 0
var _game: Node
var _start_z := 0.0


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	_game = root.get_node("GameState")
	_game.call("new_game")
	_game.set("dock_pallets", 3)
	_game.set("return_scene", "res://scenes/hub/TruckStop.tscn")
	_game.set("return_position", RETURN_SPOT)
	change_scene_to_file("res://scenes/dock/LoadingDock.tscn")


func _next(stage: String) -> void:
	_stage = stage
	_stage_time = 0.0


func _process(delta: float) -> bool:
	_time += delta
	_stage_time += delta
	if _time > 90.0:
		push_error("Smoke test (dock): got stuck at stage " + _stage)
		quit(1)
		return false
	var dock := current_scene
	if dock == null:
		return false
	match _stage:
		"start":
			if _stage_time > 0.5 and dock.get("forklift") != null:
				dock.call("_climb_on")
				var lift: Node3D = dock.get("forklift")
				if lift.get("driver") == null:
					push_error("Smoke test (dock): she should climb onto the forklift")
				_start_z = lift.global_position.z
				_next("drive")
		"drive":
			# Hold "forward" for a moment: the forklift should roll toward the hold.
			Input.action_press("move_forward")
			if _stage_time > 1.2:
				Input.action_release("move_forward")
				var lift: Node3D = dock.get("forklift")
				if lift.global_position.z > _start_z - 0.5:
					push_error("Smoke test (dock): driving forward should move the forklift")
				_next("line_up")
		"line_up":
			if _stage_time < 0.3:
				return false
			var pallets: Array = dock.get("pallets")
			var lift: Node3D = dock.get("forklift")
			var pallet: Node3D = pallets[_pallet]
			# Face the pallet with the forks right under it.
			var toward := Vector3(pallet.global_position.x - lift.global_position.x, 0.0, pallet.global_position.z - lift.global_position.z).normalized()
			lift.global_transform = Transform3D(Basis.looking_at(toward), pallet.global_position - toward * 1.75)
			lift.call("use_forks", dock.call("_pickable"))
			_next("carry")
		"carry":
			if _stage_time < 0.6:
				return false
			var lift: Node3D = dock.get("forklift")
			if lift.get("carrying") == null:
				push_error("Smoke test (dock): the forks should lift pallet %d" % _pallet)
				quit(1)
				return false
			var spots: PackedVector3Array = dock.get("spots")
			var spot: Vector3 = spots[_pallet]
			# Into the hold, nose first, so the pallet sits over its spot.
			lift.global_transform = Transform3D(Basis.IDENTITY, spot + Vector3(0.0, 0.0, 1.75))
			lift.call("use_forks", dock.call("_pickable"))
			_next("set_down")
		"set_down":
			if _stage_time < 1.5:
				return false
			if int(dock.call("loaded")) != _pallet + 1:
				push_error("Smoke test (dock): pallet %d should snap into its spot" % _pallet)
				quit(1)
				return false
			_pallet += 1
			if _pallet < (dock.get("pallets") as Array).size():
				_next("line_up")
				return false
			if not dock.get("done"):
				push_error("Smoke test (dock): a full hold should finish the loading")
			if float((_game.get("rig") as Dictionary).get("snug", 0.0)) <= 0.0:
				push_error("Smoke test (dock): a full hold should make a snug load")
			_next("finish")
		"finish":
			if _stage_time > 1.6 and int(_stage_time * 4.0) % 2 == 0:
				_tap("ui_accept")  # "NICE" on the SNUG LOAD card.
			if dock.scene_file_path.ends_with("TruckStop.tscn"):
				_next("back")
		"back":
			if _stage_time > 3.0:
				var player: Node3D = dock.get("player")
				if player == null or player.global_position.distance_to(RETURN_SPOT) > 1.5:
					push_error("Smoke test (dock): she should come back to where she was")
				print("Smoke dock: loaded every pallet and came back.")
				_game.call("_silence_everything")
				_next("quit")
		"quit":
			if _stage_time > 0.3:
				quit()
	return false


func _tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
