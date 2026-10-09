extends SceneTree
## Used by tools/validate.sh: OVERDRIVE. Holds the rig at 3,000 km/h (far
## past boost's top speed) and checks the hull strain builds, the warnings
## and a worried comm call come (with the radio dipped), and then she can't
## take it: out of control, a fiery explosion, and the "press any key to
## reload" prompt. Saves to a scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_overdrive.gd


const KMH: float = 3000.0

var _time := 0.0
var _started := false
var _called := false
var _ducked := false


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	root.get_node("GameState").call("new_game")


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
	var ship: Node3D = flight.get_node("World/Ship")
	var model: Object = ship.get("flight")
	if not ship.get("out_of_control"):
		# Floor it: boosting, way past boost's top speed.
		model.set("velocity", (model.call("nose") as Vector3) * KMH / 3.6)
		model.set("boosting", true)
		model.set("burn_left", 1.0)  # Keep the burn lit: on the Newtonian fork only the burn strains the hull.
		model.set("boost_fuel", 1.0)
	var comm: Node = flight.get_node("FlightHUD").get("comm")
	if comm.call("is_busy") and (comm.get("_speaker") as Resource) != null:
		var who := str((comm.get("_speaker") as Resource).resource_path)
		if who.ends_with("crew_digby.tres") or who.ends_with("dispatch_morning.tres") or who.ends_with("space_deputy.tres"):
			_called = true
			if root.get_node("Radio").get("talk_duck"):
				_ducked = true
	var prompt := root.get_children().filter(func(n: Node) -> bool: return n.get_script() != null and str(n.get_script().resource_path).ends_with("WreckScreen.gd"))
	if not prompt.is_empty():
		if float(ship.get("overdrive_strain")) < 1.0:
			push_error("Smoke test (overdrive): the hull strain should have been full when she blew")
		if not _called:
			push_error("Smoke test (overdrive): someone should have called to warn her")
		if not _ducked:
			push_error("Smoke test (overdrive): the radio should dip for the warning calls")
		if (flight.get("_overdrive_called") as Dictionary).size() < 3:
			push_error("Smoke test (overdrive): several warnings should have come before the end")
		print("Smoke overdrive: strain, warnings, calls, out of control, boom, reload prompt. Went 2 fass.")
		root.get_node("GameState").call("_silence_everything")
		quit()
	elif _time > 90.0:
		push_error("Smoke test (overdrive): at %d km/h she should have come apart by now (strain %.2f)" % [KMH, float(ship.get("overdrive_strain"))])
		quit(1)
	return false
