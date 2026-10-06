extends SceneTree
## Used by tools/validate.sh: the debug menu's jump (autoload/DebugMenu.gd).
## Jumps to 1 minute out from Tidewater and checks the autopilot gets
## there and starts docking in about that long. Saves to a scratch file,
## never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_debug_jump.gd


var _time := 0.0
var _jumped := false


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	root.get_node("GameState").call("new_game")


func _process(delta: float) -> bool:
	if not _jumped:
		# (Autoloads are only ready once the game's running.)
		_jumped = true
		root.get_node("DebugMenu").call("skip_opening")
		root.get_node("DebugMenu").call("jump", "tidewater", 1.0)
		return false
	_time += delta
	var flight := current_scene
	if flight != null and flight.scene_file_path.ends_with("FlightSandbox.tscn") and flight.get("_docking_at") == "tidewater":
		print("Smoke debug jump: 1 minute out from Tidewater, docking after %d s." % roundi(_time))
		root.get_node("GameState").call("_silence_everything")
		quit()
	elif _time > 150.0:
		push_error("Smoke test (debug jump): 1 minute out from Tidewater should reach its ring in about a minute")
		quit(1)
	return false
