extends "res://tools/tests/TestSuite.gd"
## Checks for the rigs at Dusty's (data/ships/ and scenes/flight/rigs/,
## built by tools/build_rigs.gd): every rig has a model with engines to
## hang flames on, and its own feel.


func test_every_rig_has_a_model_with_engines() -> void:
	var ids := {}
	for rig in GameState.ships.ships:
		check(not ids.has(rig.id), "rig ids should be unique (%s)" % rig.id)
		ids[rig.id] = true
		if rig.visual_scene == null:
			continue  # The Lazy Susan uses the default model.
		var model := rig.visual_scene.instantiate() as Node3D
		var nozzles := model.find_children("Nozzle*", "Marker3D", true, false)
		check(not nozzles.is_empty(), "%s needs engine nozzles (for its flames and trails)" % rig.id)
		for nozzle: Node3D in nozzles:
			check(nozzle.position.z > 5.0, "%s's nozzles should be at the back (+Z)" % rig.id)
		model.free()


func test_the_design_sheet_rigs_are_for_sale() -> void:
	for id in ["stack_ship", "bulk_ore", "tanker", "catamaran", "omega_crawler", "ore_crawler", "ice_tug", "hab_brick", "garbage_scow"]:
		var rig := GameState.ships.find(id)
		check(rig != null, "%s should be at the dealer" % id)
		if rig != null:
			check(rig.price > 0 and not rig.special_order, "%s should have a price you can pay" % id)
			check(rig.pay_bonus >= 1.0, "%s never pays less than the base rate" % id)


func test_rigs_feel_different() -> void:
	var feels := {}
	for rig in GameState.ships.ships:
		feels["%s %s %s %s" % [rig.max_speed, rig.turn_rate, rig.grip, rig.acceleration]] = rig.id
	check(feels.size() == GameState.ships.ships.size(), "no two rigs should handle exactly the same")
