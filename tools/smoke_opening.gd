extends SceneTree
## Used by tools/validate.sh: plays the opening of a new game.
##   start in dispatch -> Raccoony starts talking by himself -> hear him out
##   -> the objective says take the wheel -> take it (the flight) -> the
##   nav points at the truck stop, Raccoony calls and the radio dips while
##   he talks -> walk into the truck stop -> Marge has a "!" and the
##   objective says talk to her.
## Saves to a scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_opening.gd
## (Game classes can't be named here: this script is compiled before the
## autoloads they use exist, so it pokes at them by name.)


var _time := 0.0
var _stage := "dispatch"
var _stage_time := 0.0
var _game: Node
var _ducked := false


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	_game = root.get_node("GameState")
	_game.call("new_game")
	_game.set("next_spawn", "FromHallway")
	change_scene_to_file("res://scenes/hub/Dispatch.tscn")


func _next(stage: String) -> void:
	_stage = stage
	_stage_time = 0.0


func _objective(flying: bool) -> Dictionary:
	return load("res://scenes/ui/hud/Objective.gd").call("current", flying)


func _process(delta: float) -> bool:
	_time += delta
	_stage_time += delta
	if _time > 120.0:
		push_error("Smoke test (opening): got stuck at stage " + _stage)
		quit(1)
		return false
	var dialogue := root.get_node("Dialogue")
	match _stage:
		"dispatch":
			if str(_objective(false)["target"]) != "npc:dispatch_morning" and not _game.call("has_flag", "intro_heard"):
				push_error("Smoke test (opening): the first objective should point at Raccoony")
			if dialogue.call("is_active"):
				_next("listen")
			elif _stage_time > 8.0:
				push_error("Smoke test (opening): Raccoony should start talking by himself")
				quit(1)
		"listen":
			# Click through his lines.
			if int(_stage_time * 6.0) % 2 == 0:
				_tap("interact")
			if _game.call("has_flag", "intro_heard"):
				_next("to_the_wheel")
			elif _stage_time > 20.0:
				push_error("Smoke test (opening): hearing Raccoony out should set intro_heard")
				quit(1)
		"to_the_wheel":
			if _stage_time > 0.5:
				if str(_objective(false)["target"]) != "wheel":
					push_error("Smoke test (opening): after Raccoony, the objective should be the wheel")
				change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")
				_next("flying")
		"flying":
			var flight := current_scene
			if flight == null or not flight.scene_file_path.ends_with("FlightSandbox.tscn") or _stage_time < 1.0:
				return false
			if not _game.call("has_flag", "took_the_wheel"):
				push_error("Smoke test (opening): taking the wheel should be remembered")
			if str(flight.get("_destination_id")) != "truck_stop":
				push_error("Smoke test (opening): the nav should point at the truck stop (got %s)" % flight.get("_destination_id"))
			if not str(_objective(true)["text"]).contains("TRUCK STOP"):
				push_error("Smoke test (opening): in flight, the objective should be the truck stop")
			var comm: Node = flight.get_node("FlightHUD").get("comm")
			if comm.call("is_busy") and root.get_node("Radio").get("talk_duck"):
				_ducked = true
			if _stage_time > 9.0:
				if not _ducked:
					push_error("Smoke test (opening): Raccoony should call, with the radio turned down while he talks")
				# Pull in at the truck stop (as if docked) and walk in.
				_game.set("launch_from", "truck_stop")
				_game.set("next_spawn", "FromShip")
				change_scene_to_file("res://scenes/hub/TruckStop.tscn")
				_next("truck_stop")
		"truck_stop":
			if current_scene == null or not current_scene.scene_file_path.ends_with("TruckStop.tscn") or _stage_time < 3.0:
				return false
			if str(_objective(false)["target"]) != "npc:truckstop_control":
				push_error("Smoke test (opening): at the truck stop, the objective should point at Marge")
			var marge_has_news := false
			for node in current_scene.find_children("*", "NPC", true, false):
				var data: Resource = node.get("data")
				if data != null and data.resource_path.ends_with("truckstop_control.tres"):
					marge_has_news = node.call("has_news")
			if not marge_has_news:
				push_error("Smoke test (opening): Marge should have a \"!\" (she has the first job)")
			print("Smoke opening: Raccoony, the wheel, the call, Marge's \"!\". All there.")
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
