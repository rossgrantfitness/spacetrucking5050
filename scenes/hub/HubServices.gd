class_name HubServices
## What happens at the counters: the job board, the pumps, the garage, the
## jukebox, the vending machine, job offers and the payout card after a
## delivery. NPCs (through their conversations) and ServicePoints call
## open() with a menu's name.
##
## Prices are in res://data/tuning.tres under "Prices"; jobs and upgrades
## are in res://data/jobs/ and res://data/upgrades/.


## Opens a menu by name ("job_board", "fuel", "mechanic", "jukebox",
## "vending") and waits until the player is done with it.
static func open(menu: String, tree: SceneTree, place_id: String) -> void:
	match menu:
		"job_board":
			await job_board(tree, place_id)
		"fuel":
			await fuel(tree)
		"mechanic":
			await mechanic(tree)
		"jukebox":
			await jukebox(tree)
		"vending":
			await vending(tree)
	GameState.save_game()


## "Take the job?" Returns whether the player took it.
static func offer_job(tree: SceneTree, job: JobData) -> bool:
	if not GameState.active_job_id.is_empty():
		await MenuPanel.ask(tree, "ALREADY HAULING", "You've already got a load in the back. Deliver it first.", [{"text": "OKAY"}])
		return false
	var choice := await MenuPanel.ask(tree, job.cargo_name.to_upper(), job_summary(job), [
		{"text": "TAKE THE JOB", "description": "It'll be loaded on your rig. Head for the airlock when you're ready."},
		{"text": "NOT RIGHT NOW", "description": "No rush. It'll keep."}])
	if choice != 0:
		return false
	return GameState.accept_job(job)


## The job board at a place: every job you can take from here.
static func job_board(tree: SceneTree, place_id: String) -> void:
	var active := GameState.active_job()
	if active != null:
		var to := GameState.places.find(active.to_place)
		await MenuPanel.ask(tree, "JOB BOARD", "You're hauling %s to %s. Deliver it, then come back for more." % [active.cargo_name, to.display_name if to != null else "?"], [{"text": "OKAY"}])
		return
	var jobs := GameState.board_jobs(place_id)
	if jobs.is_empty():
		await MenuPanel.ask(tree, "JOB BOARD", "Nothing posted here yet. Maybe ask around.", [{"text": "OKAY"}])
		return
	var options: Array = []
	for job in jobs:
		options.append({"text": job.cargo_name.to_upper(), "detail": "%d %s" % [job.base_pay, GameState.names.currency_short], "description": job_summary(job)})
	options.append({"text": "LEAVE", "description": "Maybe later."})
	var choice := await MenuPanel.ask(tree, "JOB BOARD", "Pick a load. One at a time.", options)
	if choice >= 0 and choice < jobs.size():
		await offer_job(tree, jobs[choice])


## A job in a few words: where to, pay, bonuses.
static func job_summary(job: JobData) -> String:
	var to := GameState.places.find(job.to_place)
	var currency := GameState.names.currency_short
	var words := "%s wants it at %s. Pays %d %s." % [job.client_name, to.display_name if to != null else "?", job.base_pay, currency]
	if job.is_fragile():
		words += " FRAGILE: up to +%d %s if it arrives without a scratch." % [job.care_bonus, currency]
	if job.is_rush():
		words += " RUSH: +%d %s if you make it in %s." % [job.rush_bonus, currency, HudWidget.clock(job.rush_seconds)]
	if not job.description.is_empty():
		words += "\n" + job.description
	return words


## Lily's pumps: fill the fuel and boost tanks.
static func fuel(tree: SceneTree) -> void:
	while true:
		var tuning := GameState.tuning
		var fuel_cost := ceili((1.0 - GameState.rig["fuel"]) * tuning.fuel_tank_price)
		var boost_cost := ceili((1.0 - GameState.rig["boost_fuel"]) * tuning.boost_tank_price)
		var currency := GameState.names.currency_short
		var options: Array = [
			{"text": "FILL FUEL", "detail": "%d %s" % [fuel_cost, currency], "disabled": fuel_cost <= 0,
				"description": "Main tank is at %d%%." % roundi(GameState.rig["fuel"] * 100.0)},
			{"text": "FILL BOOST", "detail": "%d %s" % [boost_cost, currency], "disabled": boost_cost <= 0,
				"description": "Boost tank is at %d%%." % roundi(GameState.rig["boost_fuel"] * 100.0)},
			{"text": "LEAVE", "description": "Drive safe, hon."}]
		var choice := await MenuPanel.ask(tree, "LILY'S PUMPS", "You've got %d %s." % [GameState.credits, currency], options)
		if choice == 0 and GameState.spend(fuel_cost):
			GameState.rig["fuel"] = 1.0
		elif choice == 1 and GameState.spend(boost_cost):
			GameState.rig["boost_fuel"] = 1.0
		elif choice in [0, 1]:
			await MenuPanel.ask(tree, "NOT ENOUGH", "Lily squints at your wallet. \"Come back after a job, sugar.\"", [{"text": "OKAY"}])
		else:
			return


## Dusty's garage: hull repairs and rig upgrades.
static func mechanic(tree: SceneTree) -> void:
	while true:
		var currency := GameState.names.currency_short
		var repair_cost := ceili((1.0 - GameState.rig["hull"]) * GameState.tuning.hull_repair_price)
		var options: Array = [{"text": "PATCH THE HULL", "detail": "%d %s" % [repair_cost, currency], "disabled": repair_cost <= 0,
				"description": "Hull is at %d%%. Dusty bangs the dents out." % roundi(GameState.rig["hull"] * 100.0)}]
		var shop: Array[UpgradeData] = []
		for upgrade in GameState.upgrades.upgrades:
			if upgrade == null:
				continue
			var owned := GameState.owns_upgrade(upgrade.id)
			var locked := not upgrade.requires_upgrade.is_empty() and not GameState.owns_upgrade(upgrade.requires_upgrade)
			var detail := "INSTALLED" if owned else ("LOCKED" if locked else "%d %s" % [upgrade.price, currency])
			options.append({"text": upgrade.display_name.to_upper(), "detail": detail, "disabled": owned or locked,
					"description": upgrade.description + ("\n(Needs the %s first.)" % GameState.upgrades.find(upgrade.requires_upgrade).display_name if locked else "")})
			shop.append(upgrade)
		options.append({"text": "LEAVE", "description": "\"Don't be a stranger.\""})
		var choice := await MenuPanel.ask(tree, "DUSTY'S GARAGE", "You've got %d %s." % [GameState.credits, currency], options)
		if choice == 0:
			if GameState.spend(repair_cost):
				GameState.rig["hull"] = 1.0
			else:
				await _too_poor(tree)
		elif choice > 0 and choice <= shop.size():
			var upgrade := shop[choice - 1]
			if GameState.spend(upgrade.price):
				GameState.owned_upgrades.append(upgrade.id)
				await MenuPanel.ask(tree, "INSTALLED!", "%s is on your rig. You'll feel it next time you fly." % upgrade.display_name, [{"text": "NICE"}])
			else:
				await _too_poor(tree)
		else:
			return


## The jukebox plays the radio through the room's speakers.
static func jukebox(tree: SceneTree) -> void:
	var options: Array = []
	for station in Radio.lineup.stations:
		options.append({"text": "%s  %s" % [station.frequency, station.display_name], "detail": station.genre})
	options.append({"text": "SILENCE", "description": "Turn the radio off."})
	var choice := await MenuPanel.ask(tree, "JUKEBOX", "Now playing: %s" % Radio.now_playing(), options)
	if choice >= 0 and choice < Radio.lineup.stations.size():
		if not Radio.powered:
			Radio.toggle_power()
		Radio.tune_to(choice)
	elif choice == Radio.lineup.stations.size() and Radio.powered:
		Radio.toggle_power()


static func vending(tree: SceneTree) -> void:
	var price := GameState.tuning.soda_price
	var currency := GameState.names.currency_short
	var choice := await MenuPanel.ask(tree, "VENDING MACHINE", "It hums. One button is labeled NEON.", [
			{"text": "NEON SODA", "detail": "%d %s" % [price, currency], "description": "Tastes like a sunset. Glows a bit."},
			{"text": "LEAVE"}])
	if choice == 0:
		if GameState.spend(price):
			await Dialogue.say(GameState.names.bunny_name, ["*clunk* ...it's lukewarm. Perfect."], 0.85)
		else:
			await _too_poor(tree)


## The card after a delivery: what it paid, bonus by bonus.
static func show_payout(tree: SceneTree) -> void:
	var pay := GameState.pending_payout
	if pay.is_empty():
		return
	GameState.pending_payout = {}
	var currency := GameState.names.currency_short
	var lines := PackedStringArray()
	lines.append("%s for %s, %d%% intact." % [pay["cargo_name"], pay["client_name"], roundi(float(pay["condition"]) * 100.0)])
	lines.append("")
	lines.append("Base pay:  %d %s" % [pay["base"], currency])
	if int(pay["care"]) > 0:
		lines.append("Care bonus:  +%d %s" % [pay["care"], currency])
	if int(pay["rush"]) > 0:
		lines.append("Rush bonus:  +%d %s" % [pay["rush"], currency])
	lines.append("")
	lines.append("TOTAL:  +%d %s        Wallet: %d %s" % [pay["total"], currency, GameState.credits, currency])
	await MenuPanel.ask(tree, "DELIVERED!", "\n".join(lines), [{"text": "NICE"}])


static func _too_poor(tree: SceneTree) -> void:
	await MenuPanel.ask(tree, "NOT ENOUGH", "You check your wallet. Then you check it again. Nope.", [{"text": "OKAY"}])
