extends SceneTree
## Used by tools/validate.sh: a quick "smoke test" of the flight sandbox. It
## flies on autopilot for a few seconds (thrust, mouse, brake, turn, boost,
## switch to the cockpit and back, open and close the pause menu, go back to
## the start), with the traffic flying around,
## so any errors in those code paths show up, then quits politely.
##
## Run it with:  godot --headless --path . -s tools/smoke_flight.gd


const SCENE: String = "res://scenes/flight/FlightSandbox.tscn"

var _frame := 0


func _initialize() -> void:
	change_scene_to_file(SCENE)


func _process(_delta: float) -> bool:
	_frame += 1
	match _frame:
		10:
			Input.action_press("throttle_up")  # Burn forward.
			var wiggle := InputEventMouseMotion.new()  # Mouse steering's path.
			wiggle.relative = Vector2(30.0, -10.0)
			wiggle.screen_relative = Vector2(30.0, -10.0)
			Input.parse_input_event(wiggle)
		120:
			Input.action_release("throttle_up")
			Input.action_press("steer_right", 0.8)
			Input.action_press("steer_up", 0.5)
			Input.action_press("boost")
		220:
			Input.action_release("steer_right")
			Input.action_release("steer_up")
			Input.action_release("boost")
			Input.action_press("throttle_down")  # Brake with reverse thrust.
			_tap("toggle_camera")
		280:
			Input.action_release("throttle_down")
			_tap("toggle_camera")
		300:
			_tap("pause")
		320:
			_tap("pause")
		340:
			# "Back to the start", like the pause menu button.
			current_scene.call("_back_to_start")
		400:
			root.get_node("GameState").call("quit_game")
	return false


## Presses and releases an action, like a quick tap of a button.
func _tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
