extends "res://tools/tests/TestSuite.gd"
## Checks for how you find your way around: the rig's rooms can take a color
## cast, and your job's drop-off stands out on the course chart.


func test_the_rig_interior_can_take_a_tint() -> void:
	check(GameState.ships.find("lazy_susan").interior_tint == Color.WHITE, "the Thumper (your rig) looks as it always has")
	check("uniform vec3 tint" in (load("res://shaders/prerendered_backdrop.gdshader") as Shader).code, "the painted rooms can take a tint")


func test_the_job_drop_off_is_pink_on_the_chart() -> void:
	check(CourseChart.JOB_COLOR != CourseChart.ROUTE_COLOR, "the job's route isn't the same color as other routes")
	check(HudWidget.JOB_PINK.r > 0.9 and HudWidget.JOB_PINK.b > 0.6, "the job's waypoint in flight is pink too")
