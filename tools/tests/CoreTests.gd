extends "res://tools/tests/TestSuite.gd"
## Checks for the M0 plumbing: settings, saving, tuning.


func test_pitch_follows_invert_y() -> void:
	var original := Settings.invert_y  # Put back at the end; nothing is saved.
	Settings.invert_y = false
	check(Settings.pitch_from_vertical_input(-1.0) > 0.0, "stick up should mean nose up by default")
	check(Settings.pitch_from_vertical_input(1.0) < 0.0, "stick down should mean nose down by default")
	Settings.invert_y = true
	check(Settings.pitch_from_vertical_input(-1.0) < 0.0, "with invert Y, stick up should mean nose down")
	Settings.invert_y = original


func test_settings_file_values_are_checked() -> void:
	var original := Settings.invert_y  # Put back at the end; nothing is saved.
	Settings.invert_y = false
	Settings.apply_saved_data({"invert_y": "yes please"})
	check(Settings.invert_y == false, "a hand-edited invert_y that isn't true/false should be ignored")
	Settings.apply_saved_data({"invert_y": true})
	check(Settings.invert_y == true, "a saved invert_y of true should load")
	Settings.apply_saved_data({})
	check(Settings.invert_y == true, "missing values should keep the current setting")
	Settings.invert_y = original


func test_json_round_trip() -> void:
	# A scratch file, so the player's real settings are never touched.
	var path := "user://self_test_scratch.json"
	var data := {"version": 1, "credits": 250, "name": "test"}
	check(SaveSystem.write_json(path, data), "write_json should succeed")
	var loaded := SaveSystem.read_json(path)
	check(loaded.get("credits") == 250, "numbers should survive a save and load")
	check(loaded.get("name") == "test", "text should survive a save and load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(SaveSystem.read_json(path).is_empty(), "a missing file should load as empty")


func test_tuning_values_are_sane() -> void:
	var tuning := GameState.tuning
	check(tuning != null, "tuning.tres should load")
	check(tuning.stick_deadzone >= 0.0 and tuning.stick_deadzone < 1.0, "deadzone must be from 0 up to (not including) 1")
	check(tuning.steer_response > 0.0, "steer_response must be above 0 or steering never moves")
