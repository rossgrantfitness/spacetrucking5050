extends SceneTree
## Used by tools/validate.sh: ROADSIDE FUEL. Drains the tank in flight and
## checks the engines die, Gas-N-Go calls, the tanker turns up, puts a
## little fuel in and bills her (wallet first, then the tab). Saves to a
## scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_roadside.gd


var _time := 0.0
var _started := false
var _drained := false
var _money_before := 0
var _called := false


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	root.get_node("GameState").call("new_game")
	# Don't make the test wait for the real tanker.
	var tuning: Resource = root.get_node("GameState").get("tuning")
	tuning.set("roadside_call_seconds", 0.5)
	tuning.set("roadside_wait_seconds", 20.0)  # (Long enough for the call to get through the takeoff chatter.)


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		root.get_node("DebugMenu").call("skip_opening")
		change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")
		return false
	var flight := current_scene
	if flight == null or not flight.scene_file_path.ends_with("FlightSandbox.tscn"):
		return false
	_time += delta
	if _time < 1.0:
		return false
	var state := root.get_node("GameState")
	var ship: Node3D = flight.get_node("World/Ship")
	var model: Object = ship.get("flight")
	if not _drained:
		_drained = true
		model.set("fuel", 0.0)
		model.set("velocity", Vector3.ZERO)
		_money_before = int(state.get("credits")) - int(state.get("tab"))
		return false
	var comm: Node = flight.get_node("FlightHUD").get("comm")
	if comm.call("is_busy") and (comm.get("_speaker") as Resource) != null:
		var who := str((comm.get("_speaker") as Resource).resource_path)
		if who.ends_with("gasngo_moe.tres") or who.ends_with("dispatch_morning.tres"):
			_called = true
	var fuel := float(model.get("fuel"))
	if fuel > 0.0:
		var tuning: Resource = state.get("tuning")
		var paid := _money_before - (int(state.get("credits")) - int(state.get("tab")))
		var price := int(load("res://scenes/flight/RoadsideFuel.gd").call("price", tuning))
		if absf(fuel - float(tuning.get("roadside_fuel"))) > 0.01:
			push_error("Smoke test (roadside): the tanker should put in roadside_fuel (got %.2f)" % fuel)
		if paid != price:
			push_error("Smoke test (roadside): the tanker should bill %d (billed %d)" % [price, paid])
		if not _called:
			push_error("Smoke test (roadside): Gas-N-Go or dispatch should have called about the dry tank")
		print("Smoke roadside: engines died, Gas-N-Go called, tanker came, %d%% fuel for %d. Watch the gauge." % [roundi(fuel * 100.0), paid])
		state.call("_silence_everything")
		quit()
	elif _time > 1.0 and float(ship.get("flight").call("speed")) > 1.0:
		push_error("Smoke test (roadside): with an empty tank the rig shouldn't speed up (%.1f m/s)" % float(model.call("speed")))
		quit(1)
	elif _time > 60.0:
		push_error("Smoke test (roadside): the tanker never came")
		quit(1)
	return false
