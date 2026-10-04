extends SceneTree
## Used by tools/validate.sh: a quick "smoke test" of walking around the base.
## Wakes up in the apartment, walks around, goes through the door to the
## hallway, then visits dispatch, talks to the clerk, boards the ship and
## gets towed home again, so any errors in those code paths show up.
##
## Run it with:  godot --headless --path . -s tools/smoke_hub.gd


var _frame := 0
var _stage := 0
var _stage_frame := 0


func _initialize() -> void:
	# Never touch the player's real save.
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	root.get_node("GameState").set("next_spawn", "Bed")
	change_scene_to_file("res://scenes/hub/Apartment.tscn")


func _process(_delta: float) -> bool:
	_frame += 1
	match _frame:
		20:
			Input.action_press("move_right")
		50:
			Input.action_release("move_right")
			_go("res://scenes/hub/Hallway.tscn", "FromApartment")
		90:
			Input.action_press("move_forward")
		120:
			Input.action_release("move_forward")
			_go("res://scenes/hub/Dispatch.tscn", "FromHallway")
		160:
			# Walk up to the counter and talk to the clerk.
			(current_scene.get("player") as Node3D).global_position = Vector3(-1.4, 0.0, -1.15)
		170:
			_tap("interact")
	# Keep pressing E through Dottie's lines (and closing anything she
	# opens), then climb the stairs and board the ship.
	if _frame > 170 and _stage == 0:
		if _frame % 8 == 0:
			_tap("interact" if root.get_node("Dialogue").call("is_active") else "ui_cancel")
		if _frame > 200 and not (current_scene.get("player") as Node).call("is_busy"):
			(current_scene.get("player") as Node3D).global_position = Vector3(3.6, 2.45, -3.6)
			_stage = 1
	elif _stage == 1:
		if _frame % 10 == 0:
			_tap("interact")
		if current_scene != null and current_scene.name == "FlightSandbox":
			_stage = 2
			_stage_frame = _frame
	elif _stage == 2 and _frame == _stage_frame + 60:
		# In flight now: get towed straight back to the base.
		current_scene.call("_arrive", "base")
		_stage = 3
	elif _stage == 3 and current_scene != null and current_scene.name == "Dispatch":
		_stage = 4
		_stage_frame = _frame
	elif _stage == 4 and _frame == _stage_frame + 30:
		root.get_node("GameState").call("quit_game")
	if _frame == 20000:
		push_error("Smoke test: walking the base got stuck at stage %d" % _stage)
		root.get_node("GameState").call("quit_game")
	return false


func _go(scene: String, spawn: String) -> void:
	root.get_node("GameState").set("next_spawn", spawn)
	change_scene_to_file(scene)


func _tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
