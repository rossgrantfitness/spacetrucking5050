extends "res://tools/tests/TestSuite.gd"
## Checks for the PS1 look and the station's traffic. Whether it LOOKS right
## is for the playtest; these check the plumbing.


func test_low_res_view_shrinks_to_about_240_rows() -> void:
	check(PSXView.shrink_for(720.0, 240) == 3, "a 720-row view should be drawn at 1/3 size (240 rows)")
	check(PSXView.shrink_for(1080.0, 270) == 4, "a 1080-row view aiming for 270 rows should be drawn at 1/4 size")
	check(PSXView.shrink_for(100.0, 240) == 1, "a tiny view should never shrink below full size")


func test_psx_shader_globals_are_declared() -> void:
	# Every 3D shader reads these; if they're missing, models won't compile.
	for setting in ["shader_globals/psx_snap_resolution", "shader_globals/psx_affine_strength"]:
		check(ProjectSettings.has_setting(setting), "%s is missing from Project Settings" % setting)


func test_ps1_tuning_is_sane() -> void:
	var tuning := GameState.tuning
	check(tuning.psx_resolution_height >= 120, "the low-res view needs a sensible number of rows")
	check(tuning.vertex_snap_scale > 0.0, "the vertex snap grid can't be zero")
	check(tuning.color_levels >= 2.0, "there must be at least 2 shades per color")
	check(tuning.haze_end > tuning.haze_start, "the haze must end farther away than it starts")


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
