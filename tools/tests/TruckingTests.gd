extends "res://tools/tests/TestSuite.gd"
## Checks the trucker skills and choices: pro docking's rules and tips (the
## flying part is in tools/smoke_pro_docking.gd).


func _fit(across: float, speed: float, facing: float) -> Dictionary:
	return {"across": across, "along": 0.0, "speed": speed, "facing": facing}


func test_parking_needs_slow_centered_and_straight() -> void:
	var tuning := GameState.tuning
	check(ProDocking.is_parked(_fit(0.0, 0.5, 1.0), tuning), "slow, centered, nose in: parked")
	check(ProDocking.is_parked(_fit(0.0, 0.5, -1.0), tuning), "slow, centered, backed in: parked")
	check(not ProDocking.is_parked(_fit(0.0, tuning.pro_dock_max_speed + 1.0, 1.0), tuning), "too fast isn't parked")
	check(not ProDocking.is_parked(_fit(tuning.pro_dock_bay_radius, 0.5, 1.0), tuning), "off to the side isn't parked")
	check(not ProDocking.is_parked(_fit(0.0, 0.5, 0.0), tuning), "sideways isn't parked")
	var far := _fit(0.0, 0.5, 1.0)
	far["along"] = tuning.pro_dock_bay_depth
	check(not ProDocking.is_parked(far, tuning), "out past the end of the bay isn't parked")


func test_neater_parks_and_backing_in_tip_more() -> void:
	var tuning := GameState.tuning
	var perfect := ProDocking.score(_fit(0.0, 0.0, 1.0), tuning)
	var sloppy := ProDocking.score(_fit(tuning.pro_dock_bay_radius * 0.5, tuning.pro_dock_max_speed * 0.9, 0.95), tuning)
	var backed := ProDocking.score(_fit(0.0, 0.0, -1.0), tuning)
	check(perfect["grade"] == "PERFECT" and int(perfect["tip"]) == tuning.pro_dock_tip, "a perfect nose-in park gets the full tip")
	check(int(sloppy["tip"]) < int(perfect["tip"]) and sloppy["grade"] != "PERFECT", "a sloppy park tips less")
	check(backed["backed_in"] and int(backed["tip"]) > int(perfect["tip"]), "backing in tips more")
	check(int(sloppy["tip"]) > 0, "any park gets something")
