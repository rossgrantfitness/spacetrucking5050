extends SceneTree
## Used by tools/validate.sh: flies the rig into a wall at boost speed and
## checks the whole crash plays out: out of control, the explosion, the
## reload prompt (it presses a key), and back to the last save (here there's no save yet, so
## it's back into the flight). It saves to a scratch file, never the
## player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_crash.gd


enum Step { WAIT, RAM, SPINNING, WRECKED, BACK, DONE }

var _frame := 0
var _step := Step.WAIT
var _step_started := 0
var _game: Node
var _first_flight: Node
var _saw_card := false


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	_game = root.get_node("GameState")
	_game.call("new_game")
	root.get_node("SaveSystem").call("delete_save")
	change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")


func _process(_delta: float) -> bool:
	_frame += 1
	var waited := _frame - _step_started
	match _step:
		Step.WAIT:
			if current_scene != null and current_scene.name == "FlightSandbox" and waited > 60:
				_first_flight = current_scene
				_next(Step.RAM)
		Step.RAM:
			if waited == 1:
				# A wall 80 m ahead, and the rig flying at it at boost speed.
				var ship: Node3D = current_scene.get_node("World/Ship")
				var wall := StaticBody3D.new()
				var shape := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size = Vector3(400.0, 400.0, 20.0)
				shape.shape = box
				wall.add_child(shape)
				current_scene.get_node("World").add_child(wall)
				var nose: Vector3 = -ship.global_basis.z
				wall.global_position = ship.global_position + nose * 80.0
				wall.look_at(ship.global_position, Vector3.UP)
				ship.get("flight").set("velocity", nose * 220.0)
			if current_scene.get_node("World/Ship").get("out_of_control") == true:
				_next(Step.SPINNING)
			elif waited > 120:
				_fail("the rig should have crashed into the wall")
		Step.SPINNING:
			if current_scene.get_node("World/Ship").get("destroyed") == true:
				_next(Step.WRECKED)
			elif waited > 400:
				_fail("the rig should have blown up after spinning out")
		Step.WRECKED:
			var card := root.get_children().filter(func(n: Node) -> bool: return n.get_class() == "CanvasLayer" and n.get_script() != null and str(n.get_script().resource_path).ends_with("WreckScreen.gd"))
			if not card.is_empty() and not _saw_card:
				_saw_card = true
				print("Smoke crash: the reload prompt is up")
			if _saw_card and waited % 60 == 30:
				_tap_any_key()  # "Press any key to reload."
			if current_scene != null and current_scene != _first_flight and current_scene.name == "FlightSandbox":
				_next(Step.BACK)
			elif waited > 4000:
				_fail("after pressing a key at the reload prompt, the game should go back to the last save")
		Step.BACK:
			if waited > 300:
				if not _saw_card:
					_fail("the reload prompt should have shown")
				if current_scene.get_node("World/Ship").get("out_of_control") == true:
					_fail("after restarting, the rig should be in one piece")
				_next(Step.DONE)
				_game.call("quit_game")
	return false


func _next(step: Step) -> void:
	_step = step
	print("Smoke crash: ", Step.keys()[step])
	_step_started = _frame


func _fail(why: String) -> void:
	push_error("Smoke crash: " + why)
	_step = Step.DONE
	_game.call("quit_game")


func _tap_any_key() -> void:
	for pressed: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = KEY_SPACE
		key.pressed = pressed
		Input.parse_input_event(key)
