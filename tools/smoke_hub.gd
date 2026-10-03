extends SceneTree
## Used by tools/validate.sh: a quick "smoke test" of walking around the base.
## Wakes up in the apartment, walks around, goes through the door to the
## hallway, then visits dispatch, talks to the clerk, boards the ship and
## docks again, so any errors in those code paths show up.
##
## Run it with:  godot --headless --path . -s tools/smoke_hub.gd


var _frame := 0


func _initialize() -> void:
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
		190:
			for i in 6:
				_tap("interact")
		200:
			# Up the stairs and onto the ship.
			(current_scene.get("player") as Node3D).global_position = Vector3(3.6, 2.45, -3.6)
		215:
			_tap("interact")
		300:
			# In flight now: dock straight back at the base.
			current_scene.call("_dock_at_base")
		360:
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
