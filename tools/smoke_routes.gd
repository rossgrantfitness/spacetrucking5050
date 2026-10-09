extends SceneTree
## Used by tools/validate.sh: ROUTE CHOICES AND REST STOPS. In the flight
## scene, checks the rest stops were built from their data; that the safe
## course from the Glimmer System to Greenhouse Reach goes round the Rubble
## Run while the shortcut goes through it; that the Starlight Turnpike
## takes its toll at the gate and its current carries the rig past cruising
## speed; and that the scenic lane goes in the logbook. Saves to a scratch
## file, never the player's real save.
##
## Run it with:  godot --headless --path . -s tools/smoke_routes.gd


var _time := 0.0
var _started := false
var _stage := 0
var _money := 0
var _stage_time := 0.0


func _initialize() -> void:
	root.get_node("SaveSystem").set("save_path", "user://smoke_test_save.json")
	root.get_node("GameState").call("new_game")


func _process(delta: float) -> bool:
	if not _started:
		_started = true
		root.get_node("DebugMenu").call("skip_opening")
		change_scene_to_file("res://scenes/flight/FlightSandbox.tscn")
		return false
	var flight := current_scene
	if flight == null or not flight.scene_file_path.ends_with("FlightSandbox.tscn"):
		return false
	_time += delta
	if _time < 1.0:
		return false
	var state := root.get_node("GameState")
	var ship: Node3D = flight.get_node("World/Ship")
	var routes: Resource = state.get("routes")
	match _stage:
		0:
			var places: Dictionary = flight.get("_places")
			for id: String in ["comet_diner", "skyway_depot", "weigh_station"]:
				if not places.has(id):
					return _fail("the rest stop %s should be out in space" % id)
			# The safe way round the Rubble Run, and the shortcut through it.
			var belt: Resource = routes.call("find", "rubble_run")
			var middle: Vector3 = belt.call("middle")
			var reach := maxf(float(belt.get("belt_width")), float(belt.call("length"))) * 0.5
			var from: Vector3 = (places["high_roller"] as Node3D).global_position + Vector3(0.0, 0.0, 4000.0)
			var safe: Array = flight.call("approach_points", "arboretum", from)
			if _closest(safe, from, middle) < reach:
				return _fail("the safe course to Greenhouse Reach should go round the Rubble Run")
			var through: Array = flight.call("approach_points", "route:rubble_run", from)
			if through.size() != 2 or _closest(through, from, middle) > 100.0:
				return _fail("the shortcut should go straight through the Rubble Run")
			# Onto the Starlight Turnpike at cruising speed.
			var lane: Resource = routes.call("find", "starlight_turnpike")
			var start: Vector3 = lane.get("start")
			var along: Vector3 = (Vector3(lane.get("finish")) - start).normalized()
			ship.call("teleport", Transform3D(Basis.looking_at(along, Vector3.UP), start + along * 2000.0))
			ship.get("flight").set("velocity", along * 55.0)
			ship.get("controls").set("lever", 1.0)  # Throttle up: ride the current (braking drops you out of it).
			state.call("add_credits", 500)
			_money = int(state.get("credits"))
			_stage = 1
			_stage_time = _time
		1:
			var speed := float(ship.get("flight").call("speed"))
			if _time - _stage_time > 6.0:
				if int(state.get("credits")) >= _money:
					return _fail("the turnpike should take its toll at the gate")
				if speed < 100.0:
					return _fail("the turnpike's current should carry the rig past cruising speed (%.0f m/s)" % speed)
				print("Smoke routes: turnpike toll %d, current up to %.0f m/s." % [_money - int(state.get("credits")), speed])
				# Down the middle of the scenic lane.
				var scenic: Resource = routes.call("find", "nebula_overlook")
				var dir: Vector3 = (Vector3(scenic.get("finish")) - Vector3(scenic.get("start"))).normalized()
				ship.call("teleport", Transform3D(Basis.looking_at(dir, Vector3.UP), scenic.call("middle")))
				_stage = 2
				_stage_time = _time
		2:
			if _time - _stage_time > 2.0:
				var logbook: Dictionary = state.get("logbook")
				if not logbook.has("nebula_overlook"):
					return _fail("driving the scenic lane should go in the logbook")
				if float((state.get("rig") as Dictionary).get("snack", 0.0)) <= 0.0:
					return _fail("the view should steady her hands")
				print("Smoke routes: rest stops built, safe way round the belt, shortcut through it, toll paid, scenic view logged.")
				_stage = 3
				state.call("quit_game")
	return false


## How close a course (from `from` through `points`) passes to `spot`.
func _closest(points: Array, from: Vector3, spot: Vector3) -> float:
	var best := INF
	var here := from
	for point: Vector3 in points:
		best = minf(best, spot.distance_to(Geometry3D.get_closest_point_to_segment(spot, here, point)))
		here = point
	return best


func _fail(why: String) -> bool:
	push_error("Smoke test (routes): " + why)
	quit(1)
	return false
