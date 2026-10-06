extends "res://tools/tests/TestSuite.gd"
## Checks for how you find your way around: each rig's rooms have their own
## color cast, and your job's drop-off stands out on the course chart.


func test_each_rig_has_its_own_soft_interior_tint() -> void:
	var seen := {}
	for ship in GameState.ships.ships:
		var tint := ship.interior_tint
		check(tint.r >= 0.6 and tint.g >= 0.6 and tint.b >= 0.6, "%s's tint is soft (not a dark or garish cast)" % ship.id)
		check(not seen.has(tint.to_html()), "%s's tint is its own" % ship.id)
		seen[tint.to_html()] = true
	check(GameState.ships.find("lazy_susan").interior_tint == Color.WHITE, "the Lazy Susan (your first rig) looks as it always has")
	check("uniform vec3 tint" in (load("res://shaders/prerendered_backdrop.gdshader") as Shader).code, "the painted rooms can take a tint")


func test_the_job_drop_off_is_pink_on_the_chart() -> void:
	check(CourseChart.JOB_COLOR != CourseChart.ROUTE_COLOR, "the job's route isn't the same color as other routes")
	check(HudWidget.JOB_PINK.r > 0.9 and HudWidget.JOB_PINK.b > 0.6, "the job's waypoint in flight is pink too")
