extends SceneTree
## Used by tools/validate.sh: a smoke test of round 9's flight extras, from
## a new game on the long haul:
##   chart a course -> a comm call -> Jack replies -> flip through all the
##   radio stations (and set off DJ reactions) -> the cinema camera (director,
##   free, back to chase) -> get up and walk into the
##   cabin -> nap (time runs fast) -> wake up -> back in the seat.
## It checks each step worked, then quits politely. It saves to a scratch
## file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_cabin.gd
## (Game classes can't be named here: this script is compiled before the
## autoloads they use exist, so it pokes at them by name.)


enum Step { FLY, CALL, REPLY, RADIO, CINEMA, CABIN, NAP, WAKE, DONE }

var _frame := 0
var _step := Step.FLY
var _step_started := 0
var _game: Node


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	_game = root.get_node("GameState")
	_game.call("new_game")
	_game.set("launch_from", "truck_stop")
	_game.call("accept_job", (_game.get("jobs") as Object).call("find", "first_long_haul"))
	change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")


func _process(_delta: float) -> bool:
	_frame += 1
	var waited := _frame - _step_started
	var comm: Node = current_scene.get_node("FlightHUD").get("comm") if current_scene != null and current_scene.has_node("FlightHUD") else null
	match _step:
		Step.FLY:
			if waited == 30:
				current_scene.call("engage_course", PackedStringArray(["tidewater"]))
				if current_scene.get_node("World/Ship").get("cruise") == null:
					_fail("charting a course should engage the cruise autopilot")
				_next(Step.CALL)
		Step.CALL:
			if not comm.call("is_busy"):
				comm.call("call_in", load("res://data/npcs/trucker_wendell.tres"), "Smoke test. Say something back.", 3)
				_next(Step.REPLY)
		Step.REPLY:
			if comm.call("can_reply"):
				comm.call("open_replies")
			if comm.call("is_picking"):
				comm.call("choose_reply", 1)
			var speaker: Resource = comm.get("_speaker")
			if speaker != null and speaker.get("species") == "bunny":
				_next(Step.RADIO)
			elif waited > 3000:
				_fail("Jack's reply should go out over the comms")
		Step.RADIO:
			var radio := root.get_node("Radio")
			radio.call("next_station")
			radio.get("now_playing")
			if waited == 1:
				for event: String in ["storm", "ticket", "new_system", "delivery"]:
					radio.call("dj_react", event, {"place": "TIDEWATER CANNERY", "system": "Tidewater System"})
			if waited >= 22:
				current_scene.call("start_cinema")
				_next(Step.CINEMA)
		Step.CINEMA:
			var controls: Object = current_scene.get_node("World/Ship").get("controls")
			var cinema: Camera3D = current_scene.get_node("World/CinemaCamera")
			if waited == 120:
				if not current_scene.call("in_cinema") or root.get_viewport().get_camera_3d() != cinema:
					_fail("the cinema camera should have the view")
				if not controls.get("hands_free"):
					_fail("in the cinema camera, the stick shouldn't steer the rig")
				current_scene.call("_next_cinema_mode")  # Director -> free camera.
				if cinema.get("mode") != 1:
					_fail("V again should hand you the camera")
			if waited == 200:
				current_scene.call("_next_cinema_mode")  # Free camera -> chase cam.
				if current_scene.call("in_cinema") or controls.get("hands_free"):
					_fail("V a third time should go back to the chase cam, hands on the stick")
				current_scene.call("start_cinema")
				current_scene.call("_open_cabin")  # Getting up leaves the cinema camera.
				_next(Step.CABIN)
		Step.CABIN:
			var room: Node = current_scene.get("_cabin_room")
			if room != null and room.get("_ready_to_play") == true:
				if current_scene.call("in_cinema"):
					_fail("getting up should leave the cinema camera")
				if not current_scene.get_node("World/Ship").get("controls").get("hands_free"):
					_fail("in the cabin, the rig's controls should ignore the keys")
				current_scene.call("_nap")
				_next(Step.NAP)
			elif waited > 3000:
				_fail("the cabin should open")
		Step.NAP:
			if waited == 30:
				if Engine.time_scale <= 1.0:
					_fail("napping should fast-forward time")
				current_scene.call("_wake_up")
				current_scene.call("_back_to_seat")
				_next(Step.WAKE)
		Step.WAKE:
			if waited == 60:
				if Engine.time_scale != 1.0:
					_fail("waking up should put time back to normal")
				if current_scene.get("_in_cabin"):
					_fail("walking out of the cabin should put you back in the seat")
				if current_scene.get_node("World/Ship").get("cruise") == null:
					_fail("the autopilot should still be driving after a walk around the cabin")
				_finish()
	if _frame > 20000 and _step != Step.DONE:
		_fail("got stuck at step %s" % Step.keys()[_step])
	return false


func _next(step: Step) -> void:
	_step = step
	_step_started = _frame
	print("Smoke cabin: ", Step.keys()[step])


func _fail(why: String) -> void:
	push_error("Smoke test (cabin): " + why)
	_finish()


func _finish() -> void:
	if _step == Step.DONE:
		return
	_step = Step.DONE
	Engine.time_scale = 1.0
	_game.call("quit_game")
