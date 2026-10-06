class_name Objective
extends RefCounted
## What you're meant to be doing right now, in a few words, for the
## objective line on both HUDs (on foot: HubHUD; flying: ObjectiveLine).
## Worked out fresh from the story so far, your job and where you are, so
## it's never out of date.
##
## Also says what (if anything) the line is pointing at in a room, so the
## on-foot HUD can hang a marker over it:
##   "wheel"   - the stairs up to the cockpit (TAKE THE WHEEL)
##   "airlock" - the rig's airlock, out into the station
##   "npc:<file name>" - someone to talk to (like "npc:truckstop_control")


## {"text": the line, "target": what it points at (see above), or ""}.
## `flying`: in the driver's seat (not walking the cabin).
static func current(flying: bool) -> Dictionary:
	var job := GameState.active_job()
	var at_truck_stop := GameState.launch_from == "truck_stop"
	var in_station := _standing_in_a_station()
	# The opening (see Raccoony's data and FlightSandbox._opening_call).
	if GameState.in_opening():
		if not GameState.has_flag("intro_heard"):
			return _goal("TALK TO RACCOONY AT DISPATCH", "npc:dispatch_morning")
		return _goal("TAKE THE WHEEL: UP THE STAIRS IN DISPATCH", "wheel")
	if job == null and not GameState.has_flag("met_marge"):
		if flying:
			return _goal("PULL INTO THE TRUCK STOP (FOLLOW THE YELLOW DIAMOND)", "")
		if in_station and at_truck_stop:
			return _goal("TALK TO MARGE, THE OWL", "npc:truckstop_control")
		if at_truck_stop:
			return _goal("FIND MARGE: OUT THROUGH THE AIRLOCK", "airlock")
		return _goal("TAKE THE WHEEL AND PULL INTO THE TRUCK STOP", "wheel")
	if job != null:
		var to := GameState.places.find(job.to_place)
		var where := to.display_name if to != null else "THE DROP-OFF"
		if flying:
			return _goal("HAUL THE LOAD TO %s" % where, "")
		return _goal("HAUL THE LOAD TO %s: TAKE THE WHEEL" % where, "airlock" if in_station else "wheel")
	if not GameState.has_flag("first_mission_done"):
		if in_station and at_truck_stop:
			return _goal("TALK TO MARGE ABOUT HER PIE RUN", "npc:truckstop_control")
		return _goal("HEAD BACK TO MARGE AT THE TRUCK STOP", "")
	# Free trucking.
	if flying:
		return _goal("NO LOAD: DOCK SOMEWHERE AND PICK A JOB", "")
	return _goal("PICK A JOB: RACCOONY OR THE JOB BOARD IN DISPATCH", "")


static func _goal(text: String, target: String) -> Dictionary:
	return {"text": text, "target": target}


## Walking around a station (not aboard the rig).
static func _standing_in_a_station() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return false
	return not tree.current_scene.scene_file_path in HubRoom.RIG_ROOMS and tree.current_scene is HubRoom
