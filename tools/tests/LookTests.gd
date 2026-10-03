extends "res://tools/tests/TestSuite.gd"
## Checks for the PS1 look and the station's traffic. Whether it LOOKS right
## is for the playtest; these check the plumbing.


func test_wobble_grid_matches_the_screen_shape() -> void:
	check(PSXScreen.snap_grid(Vector2(1920, 1080), 480.0).is_equal_approx(Vector2(853.333, 480.0)), "a 16:9 screen gets a 16:9 snap grid")
	check(PSXScreen.snap_grid(Vector2(800, 600), 480.0).is_equal_approx(Vector2(640.0, 480.0)), "an 800x600 screen gets a 4:3 snap grid")


func test_dither_dots_scale_with_the_screen() -> void:
	check(PSXScreen.dither_dot_size(1080.0, 540.0) == 2.0, "at 1080p each dither dot is 2 pixels")
	check(PSXScreen.dither_dot_size(2160.0, 540.0) == 4.0, "at 4K each dither dot is 4 pixels")
	check(PSXScreen.dither_dot_size(600.0, 540.0) == 1.0, "small screens never go below 1-pixel dots")


func test_psx_shader_globals_are_declared() -> void:
	# Every 3D shader reads these; if they're missing, models won't compile.
	for setting in ["shader_globals/psx_snap_resolution", "shader_globals/psx_affine_strength"]:
		check(ProjectSettings.has_setting(setting), "%s is missing from Project Settings" % setting)


func test_ps1_tuning_is_sane() -> void:
	var tuning := GameState.tuning
	check(tuning.vertex_snap_rows >= 60.0, "the vertex snap grid needs a sensible number of rows")
	check(tuning.dither_rows >= 60.0, "the dither dots need a sensible size")
	check(tuning.color_levels >= 2.0, "there must be at least 2 shades per color")
	check(tuning.haze_end > tuning.haze_start, "the haze must end farther away than it starts")


func test_window_never_gets_smaller_than_800_by_600() -> void:
	check(GameState.MIN_WINDOW_SIZE == Vector2i(800, 600), "the smallest supported window is 800x600")


func test_traffic_route_is_a_closed_smooth_loop() -> void:
	var spots := PackedVector3Array([Vector3(0, 0, 0), Vector3(500, 0, 0), Vector3(500, 0, -500), Vector3(0, 100, -500)])
	var route := TrafficShip.build_route(spots)
	var length := route.get_baked_length()
	check(length > 1500.0, "the loop should be at least as long as its straight lines (got %.0f m)" % length)
	check(route.sample_baked(0.0).distance_to(route.sample_baked(length)) < 1.0, "the loop's end should meet its start")
	for spot in spots:
		var nearest := route.get_closest_point(spot)
		check(nearest.distance_to(spot) < 1.0, "the loop should pass through every waypoint")


func test_too_few_waypoints_make_an_empty_route() -> void:
	check(TrafficShip.build_route(PackedVector3Array([Vector3.ZERO])).point_count == 0, "one spot isn't a loop")
