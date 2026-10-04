extends SceneTree
## Used by tools/validate.sh: a quick "smoke test" of the flight sandbox. It
## flies on autopilot for a few seconds (thrust, mouse, brake, turn, boost,
## switch to the cockpit and back, open and close the pause menu, go back to
## the launch point), with the traffic flying around, plus the HUD and
## radio: flipping stations, switching it off and on, hiding and showing the
## HUD, the HUD demo and a comm call. Then it flies through the truck stop's
## approach ring, lets the autopilot dock, and checks you end up inside.
## Any errors in those code paths show up, then it quits politely.
##
## Run it with:  godot --headless --path . -s tools/smoke_flight.gd


const SCENE: String = "res://scenes/flight/FlightSandbox.tscn"

var _frame := 0
var _docked_at := 0


func _initialize() -> void:
	# Never touch the player's real save.
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
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
		290:
			# A big bonk and a little one: sparks, sound, smoke, hull bar.
			var ship := current_scene.get_node("World/Ship")
			ship.call("bonk", 40.0, ship.get("global_position") + Vector3(0, 0, -15), Vector3.BACK)
			ship.call("bonk", 6.0, ship.get("global_position") + Vector3(5, 0, 0), Vector3.LEFT)
		295:
			_tap("radio_next")
			_tap("hud_demo")
			current_scene.get_node("FlightHUD").get("comm").call("call_in",
					load("res://data/npcs/trucker_pip.tres"), "Smoke test! Is this thing on? Testing, testing, one two three gnomes.")
		298:
			_tap("toggle_hud")
			_tap("radio_previous")
			_tap("radio_power")
		299:
			_tap("radio_power")
		300:
			_tap("toggle_hud")
			_tap("pause")
		320:
			_tap("pause")
		320:
			_tap("hud_demo")
			# "Back to the launch point", like the pause menu button.
			current_scene.call("_back_to_launch_point")
		330:
			# Just in front of the truck stop's approach ring, thrusting
			# through it: the autopilot should take over and dock.
			var ship := current_scene.get_node("World/Ship")
			var ring: Node3D = current_scene.get_node("World/Places/truck_stop/ApproachRing")
			ship.call("teleport", Transform3D(Basis.IDENTITY, ring.global_position + Vector3(0, 0, 60)))
			Input.action_press("throttle_up")
	if _frame > 330 and current_scene != null and current_scene.name == "TruckStop" and _docked_at == 0:
		_docked_at = _frame
		Input.action_release("throttle_up")
	if _docked_at > 0 and _frame == _docked_at + 120:
		root.get_node("GameState").call("quit_game")
	if _frame == 20000 and _docked_at == 0:
		push_error("Smoke test: flying through the truck stop's ring should dock and walk inside")
		root.get_node("GameState").call("quit_game")
	return false


## Presses and releases an action, like a quick tap of a button.
func _tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
