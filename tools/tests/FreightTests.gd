extends "res://tools/tests/TestSuite.gd"
## Checks the FREIGHT MARKET (data/freight/): every board posts everyday
## loads around the story jobs, paid by distance, weight and urgency; the
## boards only reach places you've opened up; taking a haul takes it off
## the board; and a haul in the back survives a save.


const SCRATCH_SAVE: String = "user://test_freight_save.json"


func _fresh() -> Dictionary:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	return before


func _restore(before: Dictionary) -> void:
	GameState.apply_save_data(before)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_SAVE))
	SaveSystem.save_path = "user://save.json"


func test_every_cargo_kind_makes_sense() -> void:
	var market := GameState.freight
	check(market.cargo_types.size() >= 12, "the market should have plenty of kinds of freight")
	for kind in market.cargo_types:
		check(not kind.names.is_empty() and not kind.clients.is_empty(), "%s needs names and clients" % kind.id)
		check(kind.weight_range.x > 0.0 and kind.weight_range.y >= kind.weight_range.x, "%s's weights should go from light to heavy" % kind.id)
		for place_id in kind.sources + kind.destinations:
			check(GameState.places.find(place_id) != null, "%s ships from or to a real place (%s)" % [kind.id, place_id])


func test_boards_fill_up_once_the_road_opens() -> void:
	var before := _fresh()
	check(GameState.freight_board("truck_stop").is_empty(), "before the first mission, there's no freight yet")
	GameState.set_flag("first_mission_done")
	var board := GameState.freight_board("truck_stop")
	check(board.size() == GameState.freight.loads_per_board, "the truck stop should post a full board of freight")
	for job in board:
		check(job.to_place in ["tidewater", "gas_n_go"], "freight only goes where the road's open (%s)" % job.to_place)
		check(job.base_pay > 0 and job.weight > 0.0, "every haul pays and weighs something")
	var again := GameState.freight_board("truck_stop")
	check(again.size() == board.size() and again[0].id == board[0].id and again[0].base_pay == board[0].base_pay, "looking twice shows the same board")
	GameState.set_flag("glimmer_open")
	GameState.set_flag("frostline_open")
	var places := {}
	for period in 20:
		for job in GameState.freight.board("truck_stop", period, GameState.market_seed):
			places[job.to_place] = true
	check(places.has("high_roller") and places.has("creamery"), "opened systems get freight too")
	check(not places.has("salvage_yard"), "a system you haven't opened gets none")
	GameState.day += GameState.freight.refresh_days
	var tomorrow := GameState.freight_board("truck_stop")
	check(tomorrow[0].id != board[0].id, "the board changes when the period's up")
	_restore(before)


func test_pay_follows_distance_weight_and_the_road() -> void:
	var market := GameState.freight
	check(market.pay_for(100.0, 1e9, 1.0) > market.pay_for(30.0, 1e9, 1.0), "longer hauls pay more")
	check(market.pay_for(60.0, 3e9, 1.0) > market.pay_for(60.0, 3e8, 1.0), "heavier loads pay more")
	check(market.pay_for(60.0, 1e9, 1.5) > market.pay_for(60.0, 1e9, 1.0), "steep frontier roads pay more")
	# In the same ballpark as the hand-written jobs on the same road.
	var to_tidewater := market.pay_for(GameState.places.find("truck_stop").map_position.distance_to(GameState.places.find("tidewater").map_position) / 1000.0, 1e9, 1.0)
	check(to_tidewater > 800 and to_tidewater < 1800, "a haul to Tidewater should pay like the jobs there (%d)" % to_tidewater)


func test_taking_freight_takes_it_off_the_board_and_survives_a_save() -> void:
	var before := _fresh()
	GameState.set_flag("first_mission_done")
	GameState.launch_from = "truck_stop"
	var board := GameState.board_jobs("truck_stop")
	var haul: JobData = null
	for job in board:
		if FreightMarket.is_freight_id(job.id):
			haul = job
			break
	check(haul != null, "the truck stop's board should include freight")
	if haul == null:
		_restore(before)
		return
	check(GameState.accept_job(haul), "freight can be taken")
	check(GameState.active_job() == haul, "it's what's in the back")
	check(not GameState.freight_board("truck_stop").any(func(job: JobData) -> bool: return job.id == haul.id), "a taken haul leaves the board")
	check(not GameState.board_jobs("base").is_empty(), "dispatch aboard shows the freight where you're parked")
	GameState.save_game()
	GameState.new_game()
	check(GameState.load_game(), "the save should haul")
	var hauling := GameState.active_job()
	check(hauling != null and hauling.id == haul.id and hauling.to_place == haul.to_place and hauling.base_pay == haul.base_pay
			and is_equal_approx(hauling.weight, haul.weight), "a freight haul in the back survives a save")
	check(GameState.deliver_at(haul.to_place), "it can be delivered")
	check(GameState.freight_delivered == 1 and GameState.active_job() == null, "delivered and counted")
	check(not GameState.has_flag(haul.id + "_arrived_perfect"), "everyday freight doesn't litter the story flags")
	_restore(before)


func test_jobs_have_a_look() -> void:
	for job in GameState.jobs.jobs:
		check(job.look() in ["container", "reefer", "tank", "crates", "livestock", "machinery"], "%s should have a cargo look" % job.id)
