extends "res://tools/tests/TestSuite.gd"
## Checks for the vending machines and the galaxy's brands
## (res://data/brands/brands.tres, scenes/hub/Snack.gd): every snack has a
## real brand, every machine has plenty in it, local treats stay local, the
## brands match the radio ads, and a snack does what it says.

const SCRATCH_SAVE: String = "user://self_test_save.json"


func test_every_snack_has_a_brand() -> void:
	var catalog := GameState.brands
	var brand_ids := {}
	for brand in catalog.brands:
		check(not brand_ids.has(brand.id), "brand %s is listed once" % brand.id)
		brand_ids[brand.id] = true
		check(not brand.slogan.is_empty() and not brand.story.is_empty(), "%s has a slogan and a story" % brand.id)
	var product_ids := {}
	for product in catalog.products:
		check(not product_ids.has(product.id), "snack %s is listed once" % product.id)
		product_ids[product.id] = true
		check(brand_ids.has(product.brand_id), "%s's brand exists" % product.id)
		check(not product.taste_lines.is_empty(), "%s has something for her to say" % product.id)
		check(product.price > 0 and product.price <= 20, "%s costs pocket change" % product.id)


func test_every_machine_is_stocked() -> void:
	for place in ["truck_stop", "tidewater", "high_roller", "base"]:
		check(GameState.brands.stocked_at(place).size() >= 15, "a machine at %s has plenty in it" % place)
	var at_truck_stop := GameState.brands.stocked_at("truck_stop")
	check(not at_truck_stop.has(GameState.brands.find_product("canned_starfish")), "Tidewater's starfish stays at Tidewater")
	check(GameState.brands.stocked_at("tidewater").has(GameState.brands.find_product("canned_starfish")), "and you can get it there")
	check(at_truck_stop.has(GameState.brands.find_product("nebula_pie")), "Marge's pie is in the truck stop machine")


func test_the_brands_are_on_the_radio_too() -> void:
	var ads := ""
	for station in Radio.lineup.stations:
		ads += " ".join(station.ads) + " "
	for name in ["MOON MILK", "ZOOM JUICE", "STAR-STOP RAMEN", "NEON SODA", "GALAXY GUMBALLS", "COZY COIL COCOA", "OLD ORBIT SPACE JERKY", "MOCHI MOONS"]:
		check(name in ads, "%s is advertised on the radio" % name)


func test_snacks_do_what_they_say() -> void:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	GameState.rig["boost_fuel"] = 0.5
	check(Snack.apply_effect(Engine.get_main_loop() as SceneTree, GameState.brands.find_product("zoom_juice")) != "", "Zoom Juice says what it did")
	check(is_equal_approx(float(GameState.rig["boost_fuel"]), 0.75), "Zoom Juice tops up the boost tank")
	Snack.apply_effect(Engine.get_main_loop() as SceneTree, GameState.brands.find_product("star_stop_ramen"))
	check(float(GameState.rig["snack"]) > 0.0, "ramen steadies her hands for the next trip")
	GameState.tasted["moon_milk"] = 1
	check(Snack.tried_brand("moon_milk") and not Snack.tried_brand("zoom"), "she remembers which brands she's tried")
	var saved := JSON.parse_string(JSON.stringify(GameState.to_save_data())) as Dictionary
	GameState.new_game()
	GameState.apply_save_data(saved)
	check(int(GameState.tasted.get("moon_milk", 0)) == 1 and Snack.tried_count() == 1, "what she's tasted is saved")
	GameState.apply_save_data(before)
	SaveSystem.save_path = "user://save.json"


func test_every_packet_can_be_held() -> void:
	for product in GameState.brands.products:
		var held := Snack.build(product, GameState.brands.find_brand(product.brand_id))
		check(held.find_children("*", "MeshInstance3D", true, false).size() >= 2, "%s's %s has a shape" % [product.id, product.package])
		held.free()
