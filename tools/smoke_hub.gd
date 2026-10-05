extends SceneTree
## Used by tools/validate.sh: a quick "smoke test" of walking around your
## home, which is the inside of your rig, parked at the truck stop.
## Wakes up in the apartment, walks out to the hallway, steps out of the
## rig's airlock into the truck stop, boards again, walks into dispatch,
## talks to Dottie, climbs to the cockpit and takes off, then gets towed
## back to the truck stop, so any errors in those code paths show up.
##
## Run it with:  godot --headless --path . -s tools/smoke_hub.gd


enum Stage { APARTMENT, HALLWAY, OUTSIDE, BACK_ABOARD, DISPATCH, TALKING, COCKPIT, FLYING, TOWED, DONE }

var _frame := 0
var _stage := Stage.APARTMENT
var _stage_frame := 0


func _initialize() -> void:
	# Never touch the player's real save.
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	root.get_node("GameState").call("new_game")
	root.get_node("GameState").set("next_spawn", "Bed")
	change_scene_to_file("res://scenes/hub/Apartment.tscn")


func _process(_delta: float) -> bool:
	_frame += 1
	var waited := _frame - _stage_frame
	match _stage:
		Stage.APARTMENT:
			if waited == 20:
				Input.action_press("move_right")
			if waited == 50:
				Input.action_release("move_right")
				_go("res://scenes/hub/Hallway.tscn", "FromApartment")
				_next(Stage.HALLWAY)
		Stage.HALLWAY:
			# Walk a little, then out of the airlock (the rig's parked at the
			# truck stop).
			if waited == 40:
				Input.action_press("move_forward")
			if waited == 70:
				Input.action_release("move_forward")
				_player().global_position = Vector3(1.0, 0.0, -6.0)
			if waited > 80 and waited % 10 == 0:
				_tap("interact")
			if _in("TruckStop"):
				_next(Stage.OUTSIDE)
		Stage.OUTSIDE:
			# Straight back in through the station's airlock.
			if _ready_room() and waited > 30:
				_player().global_position = Vector3(18.6, 0.0, 9.0)
				if waited % 10 == 0:
					_tap("interact")
			if _in("Hallway"):
				_next(Stage.BACK_ABOARD)
		Stage.BACK_ABOARD:
			if _ready_room() and waited == 30:
				_player().global_position = Vector3(0.0, 0.0, -19.6)  # Into the dispatch door.
			if _in("Dispatch"):
				_next(Stage.DISPATCH)
		Stage.DISPATCH:
			# Walk up to the counter and talk to the clerk.
			if _ready_room() and waited == 30:
				_player().global_position = Vector3(-1.4, 0.0, -1.15)
			if waited == 40:
				_tap("interact")
				_next(Stage.TALKING)
		Stage.TALKING:
			# Keep pressing E through Dottie's lines (and closing anything she
			# opens), then climb the stairs.
			if waited % 8 == 0:
				_tap("interact" if root.get_node("Dialogue").call("is_active") else "ui_cancel")
			if waited > 30 and not (_player() as Node).call("is_busy"):
				_player().global_position = Vector3(3.6, 2.45, -3.6)
				_next(Stage.COCKPIT)
		Stage.COCKPIT:
			if waited % 10 == 0:
				_tap("interact")
			if _in("FlightSandbox"):
				_next(Stage.FLYING)
		Stage.FLYING:
			if waited == 60:
				# In flight now: get towed straight back to the truck stop.
				current_scene.call("_arrive", "truck_stop")
				_next(Stage.TOWED)
		Stage.TOWED:
			if _in("TruckStop"):
				_next(Stage.DONE)
		Stage.DONE:
			if waited == 30:
				root.get_node("GameState").call("quit_game")
	if _frame == 20000:
		push_error("Smoke test: walking around the rig got stuck at stage %s" % Stage.keys()[_stage])
		root.get_node("GameState").call("quit_game")
	return false


func _next(stage: Stage) -> void:
	_stage = stage
	_stage_frame = _frame
	print("Smoke hub: ", Stage.keys()[stage])


func _in(scene_name: String) -> bool:
	return current_scene != null and current_scene.name == scene_name


func _ready_room() -> bool:
	return current_scene != null and current_scene.get("_ready_to_play") == true


func _player() -> Node3D:
	return current_scene.get("player") as Node3D


func _go(scene: String, spawn: String) -> void:
	root.get_node("GameState").set("next_spawn", spawn)
	change_scene_to_file(scene)


func _tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
