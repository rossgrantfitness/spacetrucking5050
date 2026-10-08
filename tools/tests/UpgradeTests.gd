extends "res://tools/tests/TestSuite.gd"
## Checks for the M7 ship upgrades: every upgrade is on one of Dusty's
## shelves, their effects reach the rig, the parts you can see have
## builders, and the docking computer and horn switch on.

const SCRATCH_SAVE: String = "user://self_test_save.json"


func test_every_upgrade_is_on_a_shelf() -> void:
	var shelves := HubServices.upgrade_shelves()
	var shelved := 0
	for shelf: String in shelves:
		shelved += GameState.upgrades.in_category(shelf).size()
	check(shelved == GameState.upgrades.upgrades.size(), "every upgrade sits on one of Dusty's shelves")
	for upgrade in GameState.upgrades.upgrades:
		check(upgrade.requires_upgrade.is_empty() or GameState.upgrades.find(upgrade.requires_upgrade) != null, "%s needs an upgrade that exists" % upgrade.id)


func test_hauling_and_navigation_upgrades_are_felt() -> void:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	var base := GameState.active_ship_data()
	var stock := GameState.upgraded_ship(base)
	GameState.owned_upgrades = ["cargo_cradles", "bumper_bars", "eco_injectors", "stacking_racks", "long_range_radar", "docking_computer", "air_horn"] as Array[String]
	var kitted := GameState.upgraded_ship(base)
	check(kitted.cargo_care < stock.cargo_care and kitted.hull_care < stock.hull_care, "cradles and bumpers soften the knocks")
	check(kitted.fuel_tank_seconds > stock.fuel_tank_seconds, "eco injectors make the tank last longer")
	check(kitted.pay_bonus > stock.pay_bonus, "stacking racks pay more")
	check(kitted.radar_reach > stock.radar_reach, "the radar dish sees farther")
	check(kitted.docking_computer and kitted.air_horn and not stock.docking_computer and not stock.air_horn, "the docking computer and the horn switch on")
	check(base.cargo_care == 1.0 and not base.docking_computer, "the rig's own data file isn't changed")
	var parts := GameState.owned_add_ons()
	check("bumpers" in parts and "radar_dish" in parts and "horns" in parts and "racks" in parts, "the parts you can see come with them")
	GameState.apply_save_data(before)
	SaveSystem.save_path = "user://save.json"


func test_every_visible_part_has_a_builder() -> void:
	var code := (load("res://scenes/flight/RigAddOns.gd") as GDScript).source_code
	for upgrade in GameState.upgrades.upgrades:
		if upgrade.add_on != "none":
			check(("\"%s\":" % upgrade.add_on) in code, "%s's part (%s) gets built" % [upgrade.id, upgrade.add_on])


func test_rig_add_ons_fit_a_rig() -> void:
	var pivot := Node3D.new()
	pivot.add_child((load("res://scenes/flight/RigLoadVisual.tscn") as PackedScene).instantiate())
	RigAddOns.fit(pivot, PackedStringArray(["bumpers", "radar_dish", "horns", "light_bar", "racks", "solar_fins", "stacks"]))
	var holder := pivot.get_node_or_null("AddOns")
	check(holder != null and holder.get_child_count() > 20, "all the bolt-on parts are fitted")
	var hull := RigAddOns.hull_box(pivot)
	var everything := hull
	for node in holder.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		everything = everything.merge(RigAddOns._local_to(pivot, part) * part.get_aabb())
	check(everything.size.length() < hull.size.length() * 1.6, "and they stay close to the hull (nothing flung off into space)")
	pivot.free()


func test_the_waltz_and_horn_exist() -> void:
	check(ResourceLoader.exists("res://audio/generated/docking_waltz.wav"), "the docking computer has its waltz")
	check(ResourceLoader.exists("res://audio/generated/cue_horn.wav"), "the air horn has its BWAAAMP")
	check((load("res://audio/generated/docking_waltz.wav") as AudioStreamWAV).loop_mode != AudioStreamWAV.LOOP_DISABLED, "the waltz loops")
