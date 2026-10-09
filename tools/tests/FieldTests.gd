extends "res://tools/tests/TestSuite.gd"
## Checks the asteroid and junk fields: rocks gather in clumps with gaps
## between them (never an even sprinkle), fields vary in how many rocks they
## have, and the traffic lanes through them stay clear.


func _field(clumpiness: float, seed_number: int) -> AsteroidField:
	var field := AsteroidField.new()
	field.clumpiness = clumpiness
	field.count_jitter = 0.0
	field.rock_count = 3000
	field.landmark_count = 0
	field.near_route_fraction = 0.0
	field.field_size = Vector3(3000.0, 3000.0, 3000.0)
	field.keep_clear_spots = PackedVector3Array()
	field.field_seed = seed_number
	field.position = Vector3(0.0, 90000.0, 0.0)
	return field


## How unevenly the rocks are spread: the spread of rock counts per cube of
## space (the inner part of the field), relative to the average count.
func _unevenness(field: AsteroidField) -> float:
	var counts := {}
	for center in field._rock_centers:
		var local := field.to_local(center)
		var cell := Vector3i((local / 400.0).floor())
		counts[cell] = int(counts.get(cell, 0)) + 1
	var cells := 0
	var total := 0.0
	for x in range(-2, 2):
		for y in range(-2, 2):
			for z in range(-2, 2):
				cells += 1
				total += float(counts.get(Vector3i(x, y, z), 0))
	var mean := total / cells
	var spread := 0.0
	for x in range(-2, 2):
		for y in range(-2, 2):
			for z in range(-2, 2):
				spread += pow(float(counts.get(Vector3i(x, y, z), 0)) - mean, 2.0)
	return sqrt(spread / cells) / maxf(mean, 0.001)


func test_rocks_clump_with_gaps_between() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var even := _field(0.0, 77)
	var clumpy := _field(0.7, 77)
	tree.root.add_child(even)
	tree.root.add_child(clumpy)
	var even_spread := _unevenness(even)
	var clumpy_spread := _unevenness(clumpy)
	check(clumpy_spread > even_spread * 1.6,
			"a clumpy field should be far patchier than an even one (%.2f vs %.2f)" % [clumpy_spread, even_spread])
	even.free()
	clumpy.free()


func test_fields_vary_in_how_many_rocks() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var counts := {}
	for seed_number in [1, 2, 3, 4, 5, 6]:
		var field := _field(0.7, seed_number)
		field.count_jitter = 0.35
		field.rock_count = 100
		tree.root.add_child(field)
		var count := field._rock_centers.size()
		check(count >= 65 and count <= 135, "a field asked for about 100 rocks has %d" % count)
		counts[count] = true
		field.free()
	check(counts.size() >= 3, "different fields should have different numbers of rocks")


func test_lanes_stay_clear_in_a_clumpy_field() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var field := _field(1.0, 9)
	field.lane_starts = PackedVector3Array([Vector3(0.0, 90000.0, -1600.0)])
	field.lane_ends = PackedVector3Array([Vector3(0.0, 90000.0, 1600.0)])
	field.lane_radius = 200.0
	tree.root.add_child(field)
	var inside := 0
	for i in field._rock_centers.size():
		var center := field._rock_centers[i]
		var nearest := Geometry3D.get_closest_point_to_segment(center, field.lane_starts[0], field.lane_ends[0])
		if center.distance_to(nearest) < field.lane_radius:
			inside += 1
	check(inside == 0, "%d rocks sit in the clear lane" % inside)
	field.free()
