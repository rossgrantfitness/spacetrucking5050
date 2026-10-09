extends "res://tools/tests/TestSuite.gd"
## Checks for the one rig you drive, the Thumper (data/ships/starter_rig.tres
## and its look, scenes/flight/RigLoadVisual.tscn, built by
## tools/build_player_rig.gd): it's the only rig, it has engines to hang
## flames on, and its load shows: empty deck, then bigger and bigger piles.


func test_the_thumper_is_the_only_rig() -> void:
	check(GameState.ships.ships.size() == 1, "there's only one rig for now")
	var rig := GameState.ships.ships[0]
	check(rig.id == "lazy_susan" and rig.price == 0, "it's the rig she inherited")
	check(rig.visual_scene != null and rig.visual_scene.resource_path.ends_with("RigLoadVisual.tscn"), "it uses the developer's models")


func test_the_rig_has_engines_at_the_back() -> void:
	var look := (load("res://scenes/flight/RigLoadVisual.tscn") as PackedScene).instantiate() as Node3D
	var nozzles := look.find_children("Nozzle*", "Marker3D", true, false)
	check(nozzles.size() == 4, "four engine nozzles (for its flames and trails)")
	for nozzle: Node3D in nozzles:
		check(nozzle.position.z > 10.0, "the nozzles are at the back (+Z)")
	look.free()


func test_the_load_shows_on_the_rig() -> void:
	var look := (load("res://scenes/flight/RigLoadVisual.tscn") as PackedScene).instantiate() as RigLoadVisual
	for i in 5:
		check(look.get_node_or_null("Load%d" % i) != null, "load model %d is there" % i)
	look.show_load(false, 0.0)
	check(look.stage == 0 and look.get_node("Load0").visible and not look.get_node("Load4").visible, "no job: the empty deck")
	look.show_load(true, 0.1)
	check(look.stage == 1, "a light load: a few crates")
	look.show_load(true, 0.5)
	check(look.stage == 2, "half a load: more")
	look.show_load(true, 0.9)
	check(look.stage == 3, "a full load: piled up")
	look.show_load(true, 1.5)
	check(look.stage == 4 and look.get_node("Load4").visible and not look.get_node("Load0").visible, "overloaded: the big heap, alone")
	look.free()
