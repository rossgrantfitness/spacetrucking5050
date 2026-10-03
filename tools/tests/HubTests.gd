extends "res://tools/tests/TestSuite.gd"
## Checks for walking around the base: camera-relative steering, camera
## zones, names in dialogue, the pixel font and the room scenes' wiring.


const ROOMS: Array[String] = ["res://scenes/hub/Apartment.tscn", "res://scenes/hub/Hallway.tscn", "res://scenes/hub/Dispatch.tscn"]


func test_stick_up_walks_away_from_the_camera() -> void:
	for camera_yaw: float in [0.0, 0.8, -2.0, PI]:
		# A camera turned by camera_yaw and tilted down, like the room cameras.
		var camera_basis := Basis.from_euler(Vector3(-0.5, camera_yaw, 0.0))
		var heading := HubPlayer.camera_heading(camera_basis)
		var walk := Basis(Vector3.UP, heading) * Vector3(0.0, 0.0, -1.0)  # Stick pushed up.
		var away := -camera_basis.z
		away.y = 0.0
		check(walk.dot(away.normalized()) > 0.999, "pushing up should walk straight away from the camera (yaw %.1f)" % camera_yaw)


func test_camera_zones_contain_the_right_spots() -> void:
	var shot := RoomShot.new()
	var zone := Area3D.new()
	zone.name = "Zone"
	var shape := CollisionShape3D.new()
	shape.name = "Shape"
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 2.0, 2.0)
	shape.shape = box
	shape.position = Vector3(10.0, 1.0, 0.0)
	zone.add_child(shape)
	shot.add_child(zone)
	zone.position = Vector3(0.0, 0.0, -5.0)
	check(shot.contains_local(Vector3(10.0, 0.5, -5.0)), "a spot in the middle of the zone is inside it")
	check(shot.contains_local(Vector3(11.9, 1.5, -4.1)), "a spot near the zone's corner is inside it")
	check(not shot.contains_local(Vector3(12.5, 1.0, -5.0)), "a spot past the zone's edge is outside it")
	check(not shot.contains_local(Vector3(10.0, 1.0, 0.0)), "a spot outside the moved zone is outside it")
	shot.free()


func test_names_fill_into_dialogue() -> void:
	var names := WorldNames.new()
	names.bunny_name = "Juniper"
	names.base_name = "Haul Station"
	check(names.fill_in("Morning, {bunny}! Welcome to {base}.") == "Morning, Juniper! Welcome to Haul Station.", "dialogue should fill in the names")
	check(GameState.names != null, "the world names file should load")


func test_pixel_font_letters_are_well_formed() -> void:
	for character: String in PixelFont.GLYPHS:
		var glyph: Array = PixelFont.GLYPHS[character]
		check(glyph.size() == PixelFont.HEIGHT, "letter '%s' should be %d rows tall" % [character, PixelFont.HEIGHT])
		for row: String in glyph:
			check(row.length() == (glyph[0] as String).length(), "every row of letter '%s' should be the same width" % character)
	check(PixelFont.width("AB", 2.0) == (5 + 1 + 5) * 2.0, "two letters are their widths plus one space apart")


func test_rooms_have_cameras_spawns_and_doors() -> void:
	for path in ROOMS:
		var room := (load(path) as PackedScene).instantiate()
		var shots := room.get_node("Shots").get_children()
		check(not shots.is_empty(), "%s needs at least one camera shot" % path)
		for shot in shots:
			check(shot is RoomShot and shot.get_node_or_null("Camera") is Camera3D and shot.get_node_or_null("Zone/Shape") is CollisionShape3D,
					"%s: shot %s needs a Camera and a Zone/Shape" % [path, shot.name])
		check(room.get_node("Spawns").get_child_count() > 0, "%s needs a spawn spot" % path)
		for exit in room.get_node("Exits").get_children():
			var target: String = exit.get("target_scene")
			check(ResourceLoader.exists(target), "%s: door %s leads to a missing scene %s" % [path, exit.name, target])
			var spawn: String = exit.get("target_spawn")
			if target.begins_with("res://scenes/hub/") and not spawn.is_empty():
				var other := (load(target) as PackedScene).instantiate()
				check(other.has_node("Spawns/" + spawn), "%s: door %s arrives at spawn '%s', which %s doesn't have" % [path, exit.name, spawn, target])
				other.free()
		room.free()
