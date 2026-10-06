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
##   "npc:<file name>" - someone to talk to (like "npc:truckstop_control",
##       or "npc:company_boss" for the boss in the OrbitalEx office)
##   "office"  - the OrbitalEx office's glass doors, in the truck stop
##   "office_exit" - the office's doors back out into the truck stop
## (In the truck stop, a goal in the office points at its doors; in the
## office, a goal out in the truck stop points at the way out.)


## {"text": the line, "target": what it points at (see above), or ""}.
## `flying`: in the driver's seat (not walking the cabin).
static func current(flying: bool) -> Dictionary:
	var goal := _current(flying)
	if flying or not _standing_in_a_station():
		return goal
	var target: String = goal["target"]
	var in_office := _room_path() == OFFICE
	if target == BOSS and not in_office:
		goal["target"] = "office"
	elif in_office and not target.is_empty() and target != BOSS:
		goal["target"] = "office_exit"
	return goal


const OFFICE := "res://scenes/hub/OrbitalExOffice.tscn"
const BOSS := "npc:company_boss"


static func _current(flying: bool) -> Dictionary:
	var job := GameState.active_job()
	var at_truck_stop := GameState.launch_from == "truck_stop"
	var in_station := _standing_in_a_station()
	var boss := BOSS
	# The opening: a new game starts just after a delivery, on the way to
	# collect the check (see FlightSandbox._opening_call).
	if GameState.in_opening():
		if flying:
			return _goal("PULL INTO THE TRUCK STOP: YOUR CHECK'S WAITING", "")
		if in_station and at_truck_stop:
			return _goal(GameState.names.fill_in("COLLECT YOUR CHECK: {company} OFFICE").to_upper(), boss)
		if at_truck_stop:
			return _goal(GameState.names.fill_in("OUT THE AIRLOCK TO THE {company} OFFICE").to_upper(), "airlock")
		return _goal("TAKE THE WHEEL: HEAD FOR THE TRUCK STOP", "wheel")
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
	# Checks waiting at the office (working for the company).
	if not GameState.checks.is_empty() and not GameState.has_flag("owns_company"):
		var many := "S" if GameState.checks.size() > 1 else ""
		if in_station and at_truck_stop:
			return _goal(GameState.names.fill_in("CHECK IN AT THE {company} OFFICE (%d CHECK%s WAITING)").to_upper() % [GameState.checks.size(), many], boss)
		return _goal("CHECK IN AT THE TRUCK STOP (%d CHECK%s WAITING)" % [GameState.checks.size(), many], "airlock" if at_truck_stop else ("" if flying else "wheel"))
	# New orders waiting at the office (jobs people called in).
	if not GameState.waiting_orders().is_empty():
		var orders := GameState.waiting_orders().size()
		var plural := "S" if orders > 1 else ""
		if in_station and at_truck_stop:
			return _goal(GameState.names.fill_in("NEW ORDER%s AT THE {company} OFFICE").to_upper() % plural, boss)
		return _goal("NEW ORDER%s WAITING AT THE TRUCK STOP" % plural, "airlock" if at_truck_stop else ("" if flying else "wheel"))
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


## The scene file of the room she's in ("" if none).
static func _room_path() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.current_scene.scene_file_path if tree != null and tree.current_scene != null else ""
