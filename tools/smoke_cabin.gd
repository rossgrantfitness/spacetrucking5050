extends SceneTree
## Used by tools/validate.sh: a smoke test of round 9's flight extras, from
## a new game on the long haul:
##   chart a course -> a comm call -> Jacki replies -> flip through all the
##   radio stations (and set off DJ reactions) -> the cinema camera (director,
##   free, back to chase) -> get up and walk into the
##   cabin -> walk the rig's rooms (the galley; the apartment's live window)
##   -> sleep (skips to just outside Tidewater)
##   -> back in the seat.
## It checks each step worked, then quits politely. It saves to a scratch
## file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_cabin.gd
## (Game classes can't be named here: this script is compiled before the
## autoloads they use exist, so it pokes at them by name.)


enum Step { FLY, CALL, REPLY, RADIO, CINEMA, CABIN, WALK, NAP, WAKE, NO_COURSE_NAP, DONE }

var _frame := 0
var _step := Step.FLY
var _step_started := 0
var _game: Node
var _far_before := 0.0
var _visited_galley := false


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
			if waited == 20:
				_check_routes_go_round_the_rocks()
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
				_fail("Jacki's reply should go out over the comms")
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
				if room.name != "Dispatch":
					_fail("getting up should bring you down the cockpit stairs into dispatch")
				# Walk through the rig to the apartment (the hallway door).
				current_scene.call("_walk_to_room", "res://scenes/hub/Hallway.tscn", "FromDispatch")
				_next(Step.WALK)
			elif waited > 3000:
				_fail("the cabin should open")
		Step.WALK:
			var here: Node = current_scene.get("_cabin_room")
			# Hallway -> galley (to see the crew in flight) -> hallway -> apartment.
			if here != null and here.name == "Hallway" and here.get("_ready_to_play") == true:
				if _visited_galley:
					current_scene.call("_walk_to_room", "res://scenes/hub/Apartment.tscn", "FromHallway")
				else:
					current_scene.call("_walk_to_room", "res://scenes/hub/Galley.tscn", "FromHallway")
			if here != null and here.name == "Galley" and here.get("_ready_to_play") == true and not _visited_galley:
				if not load("res://scenes/hub/ShipLife.gd").get("in_flight"):
					_fail("aboard in flight, the crew should know the rig is flying")
				_visited_galley = true
				current_scene.call("_walk_to_room", "res://scenes/hub/Hallway.tscn", "FromGalley")
			if here != null and here.name == "Apartment" and here.get("_ready_to_play") == true:
				if here.get_node_or_null("NapBed") == null:
					_fail("in flight, the apartment's bed should be for napping")
				if here.get_node_or_null("LiveWindow") == null:
					_fail("in flight, the apartment window should show what's outside, live")
				# Walk up to the bed (well, appear next to it) and press E for
				# real, the way a player does (the button has to get through
				# the cabin's little viewport, and not wake her straight back up).
				var bed := (here.get_node("NapBed") as Node3D).global_position
				(here.get("player") as Node3D).global_position = Vector3(bed.x, 0.1, bed.z + 1.0)
				_next(Step.NAP)
			elif waited > 4000:
				_fail("walking between the rig's rooms in flight got stuck")
		Step.NAP:
			# Sleeping skips ahead: she wakes up back in the seat, just
			# outside Tidewater.
			if waited == 1:
				_far_before = _distance_to_tidewater()
			if waited == 15:
				_tap("interact")
			if waited == 60 and not current_scene.get("_napping") and current_scene.get("_in_cabin"):
				_fail("pressing E at the bed in flight should start a nap (and keep her asleep)")
			if not current_scene.get("_napping") and not current_scene.get("_in_cabin"):
				if _distance_to_tidewater() > 4000.0 or _distance_to_tidewater() >= _far_before:
					_fail("sleeping in flight should skip ahead to just outside the next stop")
				_next(Step.WAKE)
			elif waited > 2000:
				_fail("sleeping in flight should end with her back in the seat")
		Step.WAKE:
			if waited == 60:
				if current_scene.get("_in_cabin"):
					_fail("walking out of the cabin should put you back in the seat")
				if current_scene.get_node("World/Ship").get("cruise") == null:
					_fail("the autopilot should still be driving after a walk around the cabin")
				# Now with the autopilot switched off: the bed should still work
				# (it sets a course for the job's drop-off).
				current_scene.call("_open_cabin")
				_next(Step.NO_COURSE_NAP)
		Step.NO_COURSE_NAP:
			var room: Node = current_scene.get("_cabin_room")
			if room != null and room.name != "Apartment" and room.get("_ready_to_play") == true:
				current_scene.call("_walk_to_room", "res://scenes/hub/Apartment.tscn", "FromHallway")
			if room != null and room.name == "Apartment" and room.get("_ready_to_play") == true and not current_scene.get("_napping"):
				# The autopilot lets go while she's up (it got there, or was
				# switched off): the bed should still work.
				current_scene.set("_course", PackedStringArray())
				current_scene.get_node("World/Ship").set("cruise", null)
				current_scene.call("_nap")
				if not current_scene.get("_napping"):
					_fail("the bed should always work, even with the autopilot off")
				if current_scene.get_node("World/Ship").get("cruise") == null:
					_fail("sleeping with no course set should set one for the job's drop-off")
				_finish()
			elif waited > 3000:
				_fail("couldn't get back to the bed with the autopilot off")
	if _frame > 20000 and _step != Step.DONE:
		_fail("got stuck at step %s" % Step.keys()[_step])
	return false


## The autopilot's routes into a station with rocks all around it should
## go round them to the lane, never straight through: from every side, no
## leg of the route (before the lane) dips into the ball of rocks.
func _check_routes_go_round_the_rocks() -> void:
	var shells: Dictionary = current_scene.get("_shells")
	for id: String in ["truck_stop", "tidewater"]:
		var field: Node3D = shells.get(id)
		if field == null:
			_fail("%s should have rocks all around it" % id)
			continue
		var center := field.global_position
		var outer: float = (field.get("shell_radii") as Vector2).y
		for side: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3(1, -1, 1).normalized()]:
			var start := center + side * 9000.0
			var points: Array = current_scene.call("approach_points", id, start)
			var here := start
			for i in points.size() - 2:  # (The last two legs run down the lane.)
				var point: Vector3 = points[i]
				var nearest := Geometry3D.get_closest_point_to_segment(center, here, point)
				if nearest.distance_to(center) < outer - 50.0:
					_fail("the route into %s from %s cuts through its rocks" % [id, side])
					break
				here = point


func _distance_to_tidewater() -> float:
	var ship: Node3D = current_scene.get_node("World/Ship")
	var ring: Node3D = current_scene.get_node("World/Places/tidewater/ApproachRing")
	return ship.global_position.distance_to(ring.global_position)


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


func _tap(action: String) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
