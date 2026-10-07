extends SceneTree
## Used by tools/validate.sh: {husband}'s message plays in flight.
##   With the message chip from Dusty (the debug menu's story jump), take
##   off from the truck stop -> about 45 s out, the comm crackles: the
##   banner, his portrait, his message -> it can't be answered, the radio
##   dips while it plays -> it never plays again.
## Saves to a scratch file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_story.gd
## (Game classes can't be named here: this script is compiled before the
## autoloads they use exist, so it pokes at them by name.)


var _time := 0.0
var _game: Node
var _heard := false
var _ducked := false


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	_game = root.get_node("GameState")
	_game.call("new_game")
	root.get_node("DebugMenu").call("story_jump", 4)  # Dusty's given her the chip.
	change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")


func _process(delta: float) -> bool:
	_time += delta
	var flight := current_scene
	if flight == null or not flight.scene_file_path.ends_with("FlightSandbox.tscn"):
		return false
	var comm: Node = flight.get_node("FlightHUD").get("comm")
	var speaker: Resource = comm.get("_speaker") if comm.call("is_busy") else null
	if speaker != null and speaker.resource_path.ends_with("white_message.tres"):
		if not _heard:
			_heard = true
			if not _game.call("has_flag", "white_voicemail"):
				push_error("Smoke test (story): playing his message should move the story on")
			if comm.get("_allow_reply"):
				push_error("Smoke test (story): nobody answers a saved message")
		if root.get_node("Radio").get("talk_duck"):
			_ducked = true
	if _heard and not comm.call("is_busy"):
		if not _ducked:
			push_error("Smoke test (story): the radio should dip while his message plays")
		if root.get_node("GameState").get("flags").get("story_call_white_message", false) != true:
			push_error("Smoke test (story): the message should be remembered as played")
		print("Smoke story: the chip, the crackle, his message, the radio dipping. All there.")
		_game.call("_silence_everything")
		quit()
	elif _time > 120.0:
		push_error("Smoke test (story): his message never played (heard: %s)" % _heard)
		quit(1)
	return false
