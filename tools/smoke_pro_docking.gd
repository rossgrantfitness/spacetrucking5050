extends SceneTree
## Used by tools/validate.sh: PRO DOCKING. With the switch on, flies the rig
## through the truck stop's ring, checks the bay lights up (in clear space
## at every station), backs the rig into it and holds it there, and checks
## the dock crew's tip and that she docks. Saves to a scratch file, never
## the player's real save (and never touches the player's settings file).
##
## Run it with:  godot --headless --path . -s tools/smoke_pro_docking.gd


var _time := 0.0
var _started := false
var _stage := 0
var _money := 0
var _parked_at := 0.0
var _inside := 0.0


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	root.get_node("GameState").call("new_game")


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		# Pro docking on, just for this test (never saved over the player's
		# own choice). On the first frame: the settings file has been read.
		root.get_node("Settings").set("keep_changes", false)
		root.get_node("Settings").set("pro_docking", true)
		root.get_node("DebugMenu").call("skip_opening")
		change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")
		return false
	var flight := current_scene
	if flight == null or not flight.scene_file_path.ends_with("FlightSandbox.tscn"):
		if _stage == 3 and flight != null and flight.scene_file_path.ends_with("TruckStop.tscn"):
			_inside += delta
			if _inside > 2.0:
				_pass()  # Climbed out at the truck stop.
		return false
	_time += delta
	if _time < 1.0:
		return false
	var ship: Node3D = flight.get_node("World/Ship")
	var state := root.get_node("GameState")
	match _stage:
		0:
			_check_every_bay(flight, ship)
			# Line up just outside the truck stop's ring and roll through it.
			var ring: Node3D = flight.get_node("World/Places/truck_stop/ApproachRing")
			var into: Vector3 = ring.call("through_direction")
			ship.call("teleport", Transform3D(Basis.looking_at(into, Vector3.UP), ring.global_position - into * 60.0))
			ship.get("flight").set("velocity", into * 25.0)
			_stage = 1
		1:
			var bay: Node3D = flight.get("_pro_dock")
			if bay != null:
				# Back into the bay and stop dead.
				var axis: Vector3 = bay.get("axis")
				ship.call("teleport", Transform3D(Basis.looking_at(-axis, Vector3.UP), bay.get("bay_center")))
				ship.get("flight").set("velocity", Vector3.ZERO)
				_money = int(state.get("credits"))
				_stage = 2
			elif _time > 20.0:
				_fail("flying through the ring with pro docking on should light up the bay")
			elif str(flight.get("_docking_at")) != "":
				_fail("with pro docking on, the autopilot shouldn't take over at the ring")
		2:
			if str(flight.get("_docking_at")) == "truck_stop":
				var tip := int(state.get("credits")) - _money
				if tip <= 0:
					_fail("the dock crew should tip for a park")
				elif not state.call("has_flag", "pro_docked"):
					_fail("a pro park should be remembered")
				else:
					print("Smoke pro docking: backed in, tip %d, docking." % tip)
					_stage = 3
					_parked_at = _time
			elif _time > 40.0:
				_fail("parked in the bay, she should have docked (held %.1f s)" % float((flight.get("_pro_dock") as Node).get("held") if flight.get("_pro_dock") != null else -1.0))
		3:
			if _time - _parked_at > 30.0:
				_fail("after the tip, she should have climbed out at the truck stop")
	return false


## Every station with a loading bay gets one in clear space.
func _check_every_bay(flight: Node, ship: Node3D) -> void:
	var places: Dictionary = flight.get("_places")
	for id: String in places:
		var place: Resource = root.get_node("GameState").get("places").call("find", id)
		if place == null or int(place.get("kind")) == 2:
			continue  # (Drive-throughs keep the autopilot.)
		var ring: Node3D = (places[id] as Node3D).get_node_or_null("ApproachRing")
		if ring == null:
			continue
		var bay: Node3D = load("res://scenes/flight/ProDocking.gd").new()
		flight.get_node("World").add_child(bay)
		bay.call("start", ship, id, (places[id] as Node3D).get_node("DockPoint").global_position, ring.call("through_direction"))
		var radius := float(root.get_node("GameState").get("tuning").get("pro_dock_bay_radius"))
		if not bay.call("_clear", bay.get("bay_center"), radius * 0.8):
			push_error("Smoke test (pro docking): the bay at %s is inside something solid" % id)
		bay.free()


func _pass() -> void:
	if _stage == 4:
		return
	_stage = 4
	root.get_node("GameState").call("quit_game")  # (Quits politely: the radio's playing in there.)


func _fail(why: String) -> void:
	push_error("Smoke test (pro docking): " + why)
	quit(1)
