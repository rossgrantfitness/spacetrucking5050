extends SceneTree
## Used by tools/validate.sh: plays the opening of a new game.
##   start in flight, cruising toward the truck stop -> Raccoony calls (the
##   radio dips while he talks) -> pull in at the truck stop -> the
##   objective points at the OrbitalEx office's doors -> walk in -> it
##   points at the boss at his desk -> talk to him ->
##   the check card (300 credits out of a 3,000 contract) -> Jacki's
##   reaction, the boss sends her to Marge -> back out to the truck stop:
##   Marge has a "!" -> later, an
##   order called in (Gill's ice): the boss hands it over.
## Saves to a scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_opening.gd
## (Game classes can't be named here: this script is compiled before the
## autoloads they use exist, so it pokes at them by name.)


var _time := 0.0
var _stage := "flying"
var _stage_time := 0.0
var _game: Node
var _ducked := false
var _credits := 0


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	_game = root.get_node("GameState")
	_game.call("new_game")
	change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")


func _next(stage: String) -> void:
	_stage = stage
	_stage_time = 0.0


func _objective(flying: bool) -> Dictionary:
	return load("res://scenes/ui/hud/Objective.gd").call("current", flying)


func _process(delta: float) -> bool:
	_time += delta
	_stage_time += delta
	if _time > 150.0:
		push_error("Smoke test (opening): got stuck at stage " + _stage)
		quit(1)
		return false
	match _stage:
		"flying":
			var flight := current_scene
			if flight == null or not flight.scene_file_path.ends_with("FlightSandbox.tscn") or _stage_time < 1.0:
				return false
			if _stage_time < 1.2:
				if str(flight.get("_destination_id")) != "truck_stop":
					push_error("Smoke test (opening): the nav should point at the truck stop (got %s)" % flight.get("_destination_id"))
				if not str(_objective(true)["text"]).contains("TRUCK STOP"):
					push_error("Smoke test (opening): in flight, the objective should be the truck stop")
				var rig: Node = flight.get("_ship")
				if rig != null and float(rig.get("flight").call("speed")) < 1.0:
					push_error("Smoke test (opening): the game should open already cruising")
				if (_game.get("checks") as Array).size() != 1:
					push_error("Smoke test (opening): the opening's check should be waiting at the office")
			var comm: Node = flight.get_node("FlightHUD").get("comm")
			if comm.call("is_busy") and root.get_node("Radio").get("talk_duck"):
				_ducked = true
			if _stage_time > 9.0:
				if not _ducked or not _game.call("has_flag", "opening_called"):
					push_error("Smoke test (opening): Raccoony should call, with the radio turned down while he talks")
				# Pull in at the truck stop (as if docked) and walk in.
				_game.set("launch_from", "truck_stop")
				_game.set("next_spawn", "FromShip")
				change_scene_to_file("res://scenes/hub/TruckStop.tscn")
				_next("truck_stop")
		"truck_stop":
			if current_scene == null or not current_scene.scene_file_path.ends_with("TruckStop.tscn") or _stage_time < 3.0:
				return false
			if str(_objective(false)["target"]) != "office":
				push_error("Smoke test (opening): at the truck stop, the objective should point at the office doors (got %s)" % _objective(false)["target"])
			# Walk into the doors.
			var player := current_scene.get("player") as Node3D
			player.global_position = Vector3(12.0, 0.0, 14.0)
			_next("into_office")
		"into_office":
			if not _in("OrbitalExOffice") or _stage_time < 1.0 or current_scene.get("_ready_to_play") != true:
				if _stage_time > 15.0:
					push_error("Smoke test (opening): walking into the glass doors should go into the office")
					quit(1)
				return false
			if str(_objective(false)["target"]) != "npc:company_boss":
				push_error("Smoke test (opening): in the office, the objective should point at the boss (got %s)" % _objective(false)["target"])
			_credits = int(_game.get("credits"))
			_to_the_desk()
			_next("check_in")
		"check_in":
			# Talk to him, then tap through his lines, the check card and
			# Jacki's reaction.
			if _stage_time > 0.5 and int(_stage_time * 6.0) % 2 == 0:
				_tap("interact")
			if _game.call("has_flag", "boss_sent_to_marge") and not root.get_node("Dialogue").call("is_active") and not _busy():
				_next("back_out")
			elif _stage_time > 40.0:
				push_error("Smoke test (opening): talking to the boss should end in the check-in (met_boss %s, first_check %s)" % [_game.call("has_flag", "met_boss"), _game.call("has_flag", "first_check")])
				quit(1)
		"back_out":
			if _stage_time < 1.0:
				return false
			if int(_game.get("credits")) != _credits + 300:
				push_error("Smoke test (opening): the check should pay 300 (credits went %d -> %d)" % [_credits, _game.get("credits")])
			if not (_game.get("checks") as Array).is_empty():
				push_error("Smoke test (opening): checking in should collect the check")
			if str(_objective(false)["target"]) != "office_exit":
				push_error("Smoke test (opening): after the check, the objective should point back out of the office (got %s)" % _objective(false)["target"])
			var player := current_scene.get("player") as Node3D
			player.global_position = Vector3(0.0, 0.0, 11.6)
			_next("marge")
		"marge":
			if not _in("TruckStop") or _stage_time < 1.0 or current_scene.get("_ready_to_play") != true:
				if _stage_time > 15.0:
					push_error("Smoke test (opening): the office doors should lead back to the truck stop")
					quit(1)
				return false
			if str(_objective(false)["target"]) != "npc:truckstop_control":
				push_error("Smoke test (opening): back in the truck stop, the objective should point at Marge")
			var marge := _npc("truckstop_control.tres")
			if marge == null or not marge.call("has_news"):
				push_error("Smoke test (opening): Marge should have a \"!\" (she has the first job)")
			# Later on: Gill called in an order. Back at the office, the boss
			# hands it over.
			_game.call("set_flag", "first_mission_done")
			_game.call("place_order", "gill_ice")
			_game.set("next_spawn", "FromTruckStop")
			change_scene_to_file("res://scenes/hub/OrbitalExOffice.tscn")
			_next("order_walk")
		"order_walk":
			if not _in("OrbitalExOffice") or current_scene.get("_ready_to_play") != true or _stage_time < 1.0:
				return false
			_to_the_desk()
			_next("order")
		"order":
			if _stage_time > 0.5 and int(_stage_time * 6.0) % 2 == 0:
				_tap("interact")
			if _game.get("active_job_id") == "gill_ice":
				if not (_game.get("orders") as Array).is_empty():
					push_error("Smoke test (opening): taking the order should clear it from the office")
				print("Smoke opening: the cruise in, Raccoony's call, the office, the boss, the check, Marge's \"!\", a new order. All there.")
				_game.call("_silence_everything")
				_next("quit")
			elif _stage_time > 30.0:
				push_error("Smoke test (opening): the boss should hand over Gill's order")
				quit(1)
		"quit":
			# Keep it quiet until the end: a voice blip still typing out
			# would be left playing at exit (and count as a leak).
			_game.call("_silence_everything")
			if _stage_time > 0.3:
				quit()
	return false


func _in(scene_name: String) -> bool:
	return current_scene != null and current_scene.scene_file_path.ends_with(scene_name + ".tscn")


func _busy() -> bool:
	var player := current_scene.get("player") as Node
	return player != null and player.call("is_busy")


## In front of the boss's desk.
func _to_the_desk() -> void:
	var player := current_scene.get("player") as Node3D
	player.global_position = _npc("company_boss.tres").global_position * Vector3(1.0, 0.0, 1.0) + Vector3(0.0, 0.0, 2.3)


func _npc(file_name: String) -> Node3D:
	for node in current_scene.find_children("*", "NPC", true, false):
		var data: Resource = node.get("data")
		if data != null and data.resource_path.ends_with(file_name):
			return node as Node3D
	return null


func _tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
