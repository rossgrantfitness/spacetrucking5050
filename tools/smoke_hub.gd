extends SceneTree
## Used by tools/validate.sh: a quick "smoke test" of walking around your
## home, which is the inside of your rig, parked at the truck stop.
## Wakes up in the apartment, boots up the PC and shuts it down again,
## walks out to the hallway, steps out of the
## rig's airlock into the truck stop, boards again, walks into dispatch,
## talks to whichever crew member is there, uses the job terminal, pops into
## the galley (checking the right crew are in it) and back out through the
## hallway, climbs to the cockpit and takes off, then gets towed back to the
## truck stop, so any errors in those code paths show up.
##
## Run it with:  godot --headless --path . -s tools/smoke_hub.gd


enum Stage { PC, APARTMENT, HALLWAY, OUTSIDE, BACK_ABOARD, DISPATCH, TALKING, WALK_AWAY, TERMINAL, DOOR_PULL, GALLEY, GALLEY_OUT, STAIRS, COCKPIT, FLYING, TOWED, DONE }

var _frame := 0
var _stage := Stage.PC
var _stage_frame := 0
var _saw_pc := false
var _saw_dialogue := false
var _saw_menu := false


func _initialize() -> void:
	# Never touch the player's real save.
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	root.get_node("GameState").call("new_game")
	# Past the opening: parked at the truck stop (smoke_opening.gd plays the opening).
	root.get_node("GameState").call("set_flag", "took_the_wheel")
	root.get_node("GameState").set("launch_from", "truck_stop")
	root.get_node("GameState").set("next_spawn", "Bed")
	change_scene_to_file("res://scenes/hub/Apartment.tscn")


func _process(_delta: float) -> bool:
	_frame += 1
	var waited := _frame - _stage_frame
	match _stage:
		Stage.PC:
			# Sit at the desk, boot up, then shut it down (Esc).
			if _ready_room() and waited == 20:
				_player().global_position = Vector3(2.1, 0.0, -1.0)
			if waited == 30:
				_tap("interact")
			var pc := _pc()
			if pc != null and pc.get("_app") == 1:  # The desktop is up.
				_tap("ui_cancel")
			if waited > 40 and pc == null:
				if not _saw_pc:
					push_error("Smoke test: the apartment's computer should open")
				_next(Stage.APARTMENT)
			_saw_pc = _saw_pc or pc != null
			if waited > 3000:
				push_error("Smoke test: the PC should boot up and shut down")
				_next(Stage.APARTMENT)
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
				# Every sign sits on a board (SignBoards.gd), none floating.
				if current_scene.find_children("SignBoard*", "Node3D", true, false).is_empty():
					push_error("Smoke test: the hallway's signs should be on boards")
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
			# Walk up to whoever's in dispatch today and talk to them.
			if _ready_room() and waited == 30:
				var crew := _crew_here()
				if crew.is_empty():
					_next(Stage.TERMINAL)
				else:
					var spot := crew[0].to_global(Vector3(0.0, 0.0, -1.3))
					_player().global_position = Vector3(spot.x, 0.0, spot.z)
			if waited == 40:
				_tap("interact")
				_next(Stage.TALKING)
		Stage.TALKING:
			# Keep pressing E through their lines (and closing anything they
			# open).
			_saw_dialogue = _saw_dialogue or root.get_node("Dialogue").call("is_active")
			if waited % 8 == 0:
				_tap("interact" if root.get_node("Dialogue").call("is_active") else "ui_cancel")
			if waited > 30 and not (_player() as Node).call("is_busy"):
				if not _saw_dialogue:
					push_error("Smoke test: talking to the crew member in dispatch should start a conversation")
				_next(Stage.WALK_AWAY)
		Stage.WALK_AWAY:
			# Talk to them again, then walk off mid-sentence: that ends it.
			var crew := _crew_here()
			if crew.is_empty():
				_next(Stage.TERMINAL)
			elif waited == 10:
				var spot := crew[0].to_global(Vector3(0.0, 0.0, -1.3))
				_player().global_position = Vector3(spot.x, 0.0, spot.z)
			elif waited == 20:
				_tap("interact")
			elif waited == 30:
				if not root.get_node("Dialogue").call("is_active"):
					push_error("Smoke test: talking to the crew a second time should start a conversation")
				_player().global_position = crew[0].global_position + Vector3(3.5, 0.0, 2.0)
			elif waited == 45:
				if root.get_node("Dialogue").call("is_active") or (_player() as Node).call("is_busy"):
					push_error("Smoke test: walking away from someone should end the conversation")
				_next(Stage.TERMINAL)
		Stage.TERMINAL:
			# The job terminal on the counter opens the job board.
			if waited == 10:
				_player().global_position = Vector3(0.3, 0.0, -0.9)
			if waited == 20:
				_tap("interact")
			_saw_menu = _saw_menu or (waited > 20 and (_player() as Node).call("is_busy"))
			if waited > 20 and waited % 8 == 0:
				_tap("ui_cancel")
			if waited > 60 and not (_player() as Node).call("is_busy"):
				if not _saw_menu:
					push_error("Smoke test: the dispatch job terminal should open the job board")
				_next(Stage.DOOR_PULL)
		Stage.DOOR_PULL:
			# The door to the hallway is under the camera: walking toward it,
			# out of frame, takes her through (no hunting for it off-screen).
			if waited == 10:
				_player().global_position = Vector3(-2.8, 0.0, 1.5)
				Input.action_press("move_back")
			if _in("Hallway"):
				Input.action_release("move_back")
				_go("res://scenes/hub/Galley.tscn", "FromHallway")
				_next(Stage.GALLEY)
			elif waited > 400:
				Input.action_release("move_back")
				push_error("Smoke test: walking out of frame toward dispatch's hallway door should go through it")
				_go("res://scenes/hub/Galley.tscn", "FromHallway")
				_next(Stage.GALLEY)
		Stage.GALLEY:
			# The crew in the galley should be the ones ShipLife says.
			if _ready_room() and waited == 30:
				var expected: Array = load("res://scenes/hub/ShipLife.gd").call("crew_in", "res://scenes/hub/Galley.tscn")
				if _crew_here().size() != expected.size():
					push_error("Smoke test: the galley should have %d crew in it, not %d" % [expected.size(), _crew_here().size()])
				_player().global_position = Vector3(2.8, 0.0, 2.75)  # Into the door back to the hallway.
			if _in("Hallway"):
				_next(Stage.GALLEY_OUT)
		Stage.GALLEY_OUT:
			if _ready_room() and waited == 30:
				_player().global_position = Vector3(0.0, 0.0, -19.6)  # Into the dispatch door.
			if _in("Dispatch"):
				_next(Stage.STAIRS)
		Stage.STAIRS:
			if _ready_room() and waited == 30:
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


## The crew members (CrewNPC) in the current room.
func _crew_here() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for person in current_scene.get_node("People").get_children():
		if person.get_script() != null and str(person.get_script().resource_path).ends_with("CrewNPC.gd"):
			found.append(person as Node3D)
	return found


func _pc() -> Node:
	for node in root.get_children():
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("DesktopPC.gd"):
			return node
	return null


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
