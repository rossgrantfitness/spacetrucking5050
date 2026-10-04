class_name JunkCloud
extends RoadsideThing
## A small drifting cloud of space junk: somebody's spilled load, an old
## satellite that came apart. Bonkable, so steer around it (or don't).


func _ready() -> void:
	var field := AsteroidField.new()
	field.junk = true
	field.rock_count = rng.randi_range(50, 90)
	field.field_size = Vector3(600.0, 260.0, 800.0)
	field.rock_radius_range = Vector2(2.0, 14.0)
	field.landmark_count = 0
	field.near_route_fraction = 0.0
	field.keep_clear_spots = PackedVector3Array()
	field.field_seed = rng.randi()
	add_child(field)
	show_on_radar("SPACE JUNK (SOMEBODY'S LOAD)", 300.0)
