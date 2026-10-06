class_name HubServices
## What happens at the counters: the job board, the pumps, the garage, the
## jukebox, the vending machine, job offers and the payout card after a
## delivery. NPCs (through their conversations) and ServicePoints call
## open() with a menu's name.
##
## Prices are in res://data/tuning.tres under "Prices"; jobs and upgrades
## are in res://data/jobs/ and res://data/upgrades/.


## Opens a menu by name ("job_board", "fuel", "mechanic", "jukebox",
## "vending", "slots", "computer", "console", "bed") and waits until the player is done
## with it.
static func open(menu: String, tree: SceneTree, place_id: String) -> void:
	match menu:
		"computer":
			await DesktopPC.open(tree)
		"console":
			await TVConsole.open(tree)
		"bed":
			await sleep(tree)
		"job_board":
			await job_board(tree, place_id)
		"fuel":
			var place := GameState.places.find(place_id)
			if place == null or place_id == "truck_stop":
				await fuel(tree)  # Lily's.
			else:
				await fuel(tree, place.display_name + " PUMPS", "Safe travels.", place.fuel_price_factor)
		"mechanic":
			await mechanic(tree)
		"jukebox":
			await jukebox(tree)
		"vending":
			await vending(tree, place_id)
		"slots":
			await slots(tree)
	# Saved with everything else, except in flight (the flight saves itself
	# when you dock).
	if tree.current_scene == null or not tree.current_scene.scene_file_path.ends_with("FlightSandbox.tscn"):
		GameState.save_game()


## Sleeping in her bed while the rig's parked: lights out, and she wakes up
## the next morning (the date shows while it's dark).
## (In flight, the bed sleeps all the way to the next stop instead; see
## FlightSandbox.gd.)
static func sleep(tree: SceneTree) -> void:
	var night := CanvasLayer.new()
	night.layer = 45
	var dark := Control.new()
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shown := {"time": 0.0}
	dark.draw.connect(func() -> void:
		var t: float = shown["time"]
		var screen := dark.size
		var square := maxf(2.0, floorf(screen.y / 200.0))
		dark.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.01, 0.03, clampf(t / 0.6, 0.0, 1.0)))
		if t > 0.7:
			var z := "Z".repeat(1 + int(t * 2.0) % 3)
			PixelFont.draw_centered(dark, screen * 0.5 - Vector2(0.0, square * 12.0), z, square * 3.0, Color(0.7, 0.75, 1.0))
		if t > 1.6:
			DateCard.draw_date(dark, screen, clampf((t - 1.6) / 0.35, 0.0, 1.0)))
	night.add_child(dark)
	tree.root.add_child(night)
	var clock := 0.0
	while clock < 3.8:
		await tree.process_frame
		clock += tree.root.get_process_delta_time()
		if clock > 1.4 and shown["time"] <= 1.4:
			Economy.sleep_until_morning()  # One night. (The week's bills may come due.)
		shown["time"] = clock
		dark.queue_redraw()
	night.queue_free()
	await show_bills(tree)


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
	var taken := GameState.accept_job(job)
	if taken:
		Sfx.play("job_accept")  # (The dock crew loads it.)
	return taken


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
		options.append({"text": job.cargo_name.to_upper(), "detail": "%s%d %s" % [job_tags(job), job.base_pay, GameState.names.currency_short],
				"description": job_summary(job)})
	options.append({"text": "LEAVE", "description": "Maybe later."})
	var choice := await MenuPanel.ask(tree, "JOB BOARD", "Pick a load. One at a time.", options)
	if choice >= 0 and choice < jobs.size():
		await offer_job(tree, jobs[choice])


## The job's tier, for the job board: RUSH, FRAGILE, PERISHABLE, LIVE (or
## nothing for a standard job), and how long it takes.
static func job_tags(job: JobData) -> String:
	var tags := PackedStringArray()
	if job.is_rush():
		tags.append("RUSH")
	if job.is_fragile() and not job.care_kind in job.cargo_name.to_lower():
		tags.append(job.care_kind.to_upper())  # (Unless the cargo's name already says so.)
	var minutes := Economy.job_trip_minutes(job)
	if minutes > 0.0:
		tags.append("~%dD" % maxi(roundi(minutes / Economy.MINUTES_PER_DAY), 1) if minutes >= 720.0 else "<1D")
	return " ".join(tags) + "   "


## How the load will feel in the rig you're driving: "" (light), " (heavy
## for the Thumper)" or " (OVERLOADED for the Thumper)".
static func _heft_note(job: JobData) -> String:
	var rig := GameState.active_ship_data()
	if rig == null or rig.load_rating <= 0.0:
		return ""
	var share := job.weight / rig.load_rating
	var rig_name := rig.display_name.split(" (")[0]
	if share > 1.0:
		return " (OVERLOADED for %s: slow to stop!)" % rig_name
	if share >= 0.6:
		return " (heavy for %s)" % rig_name
	return ""


## A job in a few words: where to, pay, bonuses.
static func job_summary(job: JobData) -> String:
	var to := GameState.places.find(job.to_place)
	var currency := GameState.names.currency_short
	var minutes := Economy.job_trip_minutes(job)
	var road := ", about %s on the road" % Economy.span_text(minutes).to_lower() if minutes > 0.0 else ""
	var words := "%s wants it at %s%s. Pays %d %s. Weighs %s%s." % [job.client_name, to.display_name if to != null else "?",
			road, job.base_pay, currency, HudWidget.tons_text(job.weight, true), _heft_note(job)]
	if job.is_fragile():
		var kind := {"perishable": "PERISHABLE: up to +%d %s if it arrives fresh.", "live": "LIVE CARGO: up to +%d %s if they arrive happy."}
		words += " " + (kind.get(job.care_kind, "FRAGILE: up to +%d %s if it arrives without a scratch.") as String) % [job.care_bonus, currency]
	if job.is_rush():
		words += " RUSH: +%d %s if you make it in %s." % [job.rush_bonus, currency, HudWidget.clock(job.rush_seconds)]
	if not job.description.is_empty():
		words += "\n" + job.description
	return words


## The pumps: fill the fuel and boost tanks. (Lily's, at the truck stop,
## unless another place's pumps are named.)
static func fuel(tree: SceneTree, title: String = "LILY'S PUMPS", goodbye: String = "Drive safe, hon.", price_factor: float = 1.0) -> void:
	while true:
		var tuning := GameState.tuning
		var fuel_cost := ceili((1.0 - GameState.rig["fuel"]) * tuning.fuel_tank_price * price_factor)
		var boost_cost := ceili((1.0 - GameState.rig["boost_fuel"]) * tuning.boost_tank_price * price_factor)
		var currency := GameState.names.currency_short
		var options: Array = [
			{"text": "FILL FUEL", "detail": "%d %s" % [fuel_cost, currency], "disabled": fuel_cost <= 0,
				"description": "Main tank is at %d%%." % roundi(GameState.rig["fuel"] * 100.0)},
			{"text": "FILL BOOST", "detail": "%d %s" % [boost_cost, currency], "disabled": boost_cost <= 0,
				"description": "Boost tank is at %d%%." % roundi(GameState.rig["boost_fuel"] * 100.0)},
			{"text": "LEAVE", "description": goodbye}]
		var choice := await MenuPanel.ask(tree, title, "You've got %d %s." % [GameState.credits, currency], options)
		if choice == 0 and GameState.spend(fuel_cost):
			GameState.rig["fuel"] = 1.0
		elif choice == 1 and GameState.spend(boost_cost):
			GameState.rig["boost_fuel"] = 1.0
		elif choice in [0, 1]:
			Sfx.play("nope")
			await MenuPanel.ask(tree, "NOT ENOUGH", "The attendant squints at your wallet. \"Come back after a job.\"" if title != "LILY'S PUMPS" else "Lily squints at your wallet. \"Come back after a job, sugar.\"", [{"text": "OKAY"}])
		else:
			return


## Dusty's garage: hull repairs and rig upgrades.
static func mechanic(tree: SceneTree) -> void:
	while true:
		var currency := GameState.names.currency_short
		var repair_cost := Economy.repair_cost()
		var level := Economy.level_of()
		var insurance_text := "INSURED" if GameState.insured else "%d %s/WEEK" % [GameState.tuning.weekly_insurance, currency]
		var options: Array = [{"text": "PATCH THE HULL", "detail": "%d %s" % [repair_cost, currency], "disabled": repair_cost <= 0,
				"description": "Hull is at %d%%. Dusty bangs the dents out.%s" % [roundi(GameState.rig["hull"] * 100.0), " (Insurance pays half.)" if GameState.insured else ""]},
				{"text": "RIGS FOR SALE", "detail": "%d OWNED" % GameState.owned_ships.size(),
				"description": "New rigs, each with its own handling. Bigger holds pay more per job."},
				{"text": "PAINT SHOP", "detail": GameState.paints.find(GameState.paint).display_name,
				"description": "A fresh coat for the hull, and a matching engine trail."},
				{"text": "INSURANCE", "detail": insurance_text,
				"description": ("You're covered: repairs cost half. Pick this to cancel (no hard feelings)." if GameState.insured
					else "Rig insurance: %d %s a week with your bills, and every repair costs half." % [GameState.tuning.weekly_insurance, currency])}]
		var shelves := upgrade_shelves()
		for shelf: String in shelves:
			var ready_count := 0
			for upgrade in GameState.upgrades.in_category(shelf):
				if _can_buy_now(upgrade, level):
					ready_count += 1
			options.append({"text": shelves[shelf][0], "detail": "%d AVAILABLE" % ready_count if ready_count > 0 else "",
					"description": shelves[shelf][1]})
		options.append({"text": "LEAVE", "description": "\"Don't be a stranger.\""})
		var rig := GameState.active_ship_data()
		var xp_note := "%d XP to level %d" % [Economy.xp_to_next(), level + 1] if Economy.xp_to_next() > 0 else "top level"
		var choice := await MenuPanel.ask(tree, "DUSTY'S GARAGE", "You've got %d %s. %s: LEVEL %d (%s)." % [GameState.credits, currency, rig.display_name, level, xp_note], options)
		if choice == 0:
			if GameState.spend(repair_cost):
				GameState.rig["hull"] = 1.0
			else:
				await _too_poor(tree)
		elif choice == 1:
			await rig_dealer(tree)
		elif choice == 2:
			await paint_shop(tree)
		elif choice == 3:
			GameState.insured = not GameState.insured
			await MenuPanel.ask(tree, "INSURANCE", "You're covered. Repairs cost half, and it's on your weekly bills." if GameState.insured
					else "Cancelled. Dusty shrugs. \"Your rig, your call.\"", [{"text": "OKAY"}])
		elif choice > 3 and choice <= shelves.size() + 3:
			await upgrade_shelf(tree, shelves.keys()[choice - 4])
		else:
			return


## Dusty's shelves of upgrades: category -> [name, what's on it].
static func upgrade_shelves() -> Dictionary:
	return {
		"engine": ["ENGINE & HANDLING", "Go faster, turn sharper, burn less, carry more boost."],
		"hauling": ["HAULING", "Kinder to your cargo and your hull, and room for more in the hold."],
		"navigation": ["NAVIGATION", "See farther, and let the computer do the docking."],
		"cab": ["CAB EXTRAS", "Fun stuff for the cab."]}


## Whether `upgrade` could go on the rig right now (not owned, nothing
## missing, the rig's level enough).
static func _can_buy_now(upgrade: UpgradeData, level: int) -> bool:
	return not GameState.owns_upgrade(upgrade.id) and level >= upgrade.min_level \
			and (upgrade.requires_upgrade.is_empty() or GameState.owns_upgrade(upgrade.requires_upgrade))


## One shelf of upgrades at Dusty's: buy them (they're felt next flight).
static func upgrade_shelf(tree: SceneTree, category: String) -> void:
	while true:
		var currency := GameState.names.currency_short
		var level := Economy.level_of()
		var options: Array = []
		var shop: Array[UpgradeData] = []
		for upgrade in GameState.upgrades.in_category(category):
			var owned := GameState.owns_upgrade(upgrade.id)
			var locked := not upgrade.requires_upgrade.is_empty() and not GameState.owns_upgrade(upgrade.requires_upgrade)
			var too_green := level < upgrade.min_level
			var detail := "INSTALLED" if owned else ("LOCKED" if locked else ("LEVEL %d" % upgrade.min_level if too_green else "%d %s" % [upgrade.price, currency]))
			var why := ""
			if locked:
				why = "\n(Needs the %s first.)" % GameState.upgrades.find(upgrade.requires_upgrade).display_name
			elif too_green and not owned:
				why = "\n(Only fits a level %d rig. Yours is level %d: keep hauling.)" % [upgrade.min_level, level]
			options.append({"text": upgrade.display_name.to_upper(), "detail": detail, "disabled": owned or locked or too_green,
					"description": upgrade.description + why})
			shop.append(upgrade)
		options.append({"text": "BACK", "description": "Back to the counter."})
		var choice := await MenuPanel.ask(tree, upgrade_shelves()[category][0], "You've got %d %s." % [GameState.credits, currency], options)
		if choice < 0 or choice >= shop.size():
			return
		var upgrade := shop[choice]
		if GameState.spend(upgrade.price):
			GameState.owned_upgrades.append(upgrade.id)
			await MenuPanel.ask(tree, "INSTALLED!", "%s is on your rig. You'll feel it next time you fly." % upgrade.display_name, [{"text": "NICE"}])
		else:
			await _too_poor(tree)


## The rig dealer: buy a new rig, or switch to one you own. Every rig has
## its own handling; bigger holds pay more per delivery.
static func rig_dealer(tree: SceneTree) -> void:
	while true:
		var currency := GameState.names.currency_short
		var options: Array = []
		var rigs: Array[ShipData] = []
		for rig in GameState.ships.ships:
			if rig == null:
				continue
			var owned := rig.id in GameState.owned_ships
			var driving := rig.id == GameState.active_ship
			var detail := "DRIVING" if driving else ("OWNED" if owned else ("SPECIAL ORDER" if rig.special_order else "%d %s" % [rig.price, currency]))
			options.append({"text": rig.display_name.to_upper(), "detail": detail, "disabled": driving,
					"description": rig_summary(rig) + ("\nSpecial order only: %d %s. Start saving!" % [rig.price, currency] if rig.special_order else "")})
			rigs.append(rig)
		options.append({"text": "LEAVE", "description": "\"Take your time. They're not going anywhere. Neither am I.\""})
		var choice := await MenuPanel.ask(tree, "RIGS FOR SALE", "You've got %d %s. You're driving %s." % [GameState.credits, currency, GameState.active_ship_data().display_name], options)
		if choice < 0 or choice >= rigs.size():
			return
		var picked := rigs[choice]
		if picked.special_order:
			await MenuPanel.ask(tree, "SPECIAL ORDER", "Dusty laughs for a full minute. \"Come back with %d %s and a really big parking spot.\"" % [picked.price, currency], [{"text": "SOMEDAY"}])
		elif picked.id in GameState.owned_ships:
			GameState.active_ship = picked.id
			await MenuPanel.ask(tree, "SWITCHED RIGS", "You'll fly %s next time you board." % picked.display_name, [{"text": "OKAY"}])
		elif GameState.spend(picked.price):
			GameState.owned_ships.append(picked.id)
			GameState.active_ship = picked.id
			GameState.save_game()
			await MenuPanel.ask(tree, "SOLD!", "%s is yours. Dusty hands you the keys and a free air freshener. (You can switch back to any rig you own here.)" % picked.display_name, [{"text": "NICE"}])
		else:
			await _too_poor(tree)


## A rig in a few words: speed, handling, hold.
static func rig_summary(rig: ShipData) -> String:
	var handling := "turns like a bus" if rig.turn_rate < 25.0 else ("steady" if rig.turn_rate < 35.0 else "nimble")
	var feel := " Slides around." if rig.grip < 1.2 else (" Corners on rails." if rig.grip > 2.2 else "")
	var words := "%s Top speed %d km/h, %s.%s" % [rig.description, roundi(rig.max_speed * 3.6), handling, feel]
	if rig.pay_bonus > 1.0:
		words += " Pays +%d%% per job." % roundi((rig.pay_bonus - 1.0) * 100.0)
	return words


## The paint shop: a tint for the hull and a matching engine trail.
static func paint_shop(tree: SceneTree) -> void:
	var currency := GameState.names.currency_short
	var options: Array = []
	var jobs: Array[PaintJob] = []
	for paint in GameState.paints.paints:
		if paint == null:
			continue
		var current := paint.id == GameState.paint
		options.append({"text": paint.display_name, "detail": "ON YOUR RIG" if current else ("FREE" if paint.price == 0 else "%d %s" % [paint.price, currency]),
				"disabled": current, "description": "Hull and engine trail, done in %s." % paint.display_name.to_lower()})
		jobs.append(paint)
	options.append({"text": "LEAVE"})
	var choice := await MenuPanel.ask(tree, "PAINT SHOP", "You've got %d %s." % [GameState.credits, currency], options)
	if choice < 0 or choice >= jobs.size():
		return
	if GameState.spend(jobs[choice].price):
		GameState.paint = jobs[choice].id
		GameState.save_game()
		await MenuPanel.ask(tree, "FRESH PAINT", "Dusty sprays it on while you eat a pie. You'll see it next time you fly.", [{"text": "NICE"}])
	else:
		await _too_poor(tree)


## The jukebox plays the radio through the room's speakers.
static func jukebox(tree: SceneTree) -> void:
	var options: Array = []
	for station in Radio.lineup.stations:
		options.append({"text": "%s  %s" % [station.frequency, station.display_name], "detail": station.genre,
				"description": station.tagline + ("" if station.dj_name.is_empty() else "  (DJ: %s)" % station.dj_name)})
	options.append({"text": "SILENCE", "description": "Turn the radio off."})
	var choice := await MenuPanel.ask(tree, "JUKEBOX", "Now playing: %s" % Radio.now_playing(), options)
	if choice >= 0 and choice < Radio.lineup.stations.size():
		if not Radio.powered:
			Radio.toggle_power()
		Radio.tune_to(choice)
	elif choice == Radio.lineup.stations.size() and Radio.powered:
		Radio.toggle_power()


static func vending(tree: SceneTree, place_id: String) -> void:
	var currency := GameState.names.currency_short
	var stock := GameState.brands.stocked_at(place_id)
	var options: Array = []
	for product in stock:
		var brand := GameState.brands.find_brand(product.brand_id)
		var new := int(GameState.tasted.get(product.id, 0)) == 0
		var effect := {"steady": " (Steady hands next trip.)", "zoom": " (Tops up your boost.)"}.get(product.effect, "") as String
		options.append({"text": product.display_name.to_upper(), "detail": ("NEW!  " if new else "") + "%d %s" % [product.price, currency],
				"description": "%s: \"%s\"\n%s%s" % [brand.display_name if brand != null else "?", brand.slogan if brand != null else "", product.blurb, effect]})
	options.append({"text": "LEAVE", "description": "Maybe later."})
	var choice := await MenuPanel.ask(tree, "VENDING MACHINE", "It hums. You've tried %d of the %d snacks in the galaxy. Wallet: %d %s." % [
			Snack.tried_count(), GameState.brands.products.size(), GameState.credits, currency], options)
	if choice < 0 or choice >= stock.size():
		return
	var product := stock[choice]
	if not GameState.spend(product.price):
		await _too_poor(tree)
		return
	await Snack.enjoy(tree, product)


## The Lucky Molar, the slot machine at The High Roller: a little mini
## game. Each pull costs a few credits and spins three reels; matching
## symbols pay (prices in tuning.tres). Over time it keeps a bit more than
## it pays, like any slot machine. Pull as often as you like, or walk away.
static func slots(tree: SceneTree) -> void:
	var tuning := GameState.tuning
	var currency := GameState.names.currency_short
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var body := "Three reels. A crocodile painted on the side, grinning. %d %s a pull." % [tuning.slots_price, currency]
	while true:
		var choice := await MenuPanel.ask(tree, "THE LUCKY MOLAR", body + "\n\nWallet: %d %s" % [GameState.credits, currency], [
				{"text": "PULL", "detail": "%d %s" % [tuning.slots_price, currency], "description": "Two alike pays %d. Three alike pays %d. Three SEVENs pays %d." % [tuning.slots_pair_pays, tuning.slots_three_pays, tuning.slots_jackpot_pays]},
				{"text": "WALK AWAY", "description": "Quit while you're... wherever you are."}])
		if choice != 0:
			return
		if not GameState.spend(tuning.slots_price):
			await _too_poor(tree)
			return
		GameState.set_flag("played_slots")
		var reels := spin_reels(rng)
		var won := slots_payout(reels, tuning)
		if won > 0:
			GameState.add_credits(won)
		body = "[ %s | %s | %s ]\n%s" % [reels[0], reels[1], reels[2], _slots_words(won, tuning, rng)]


## The symbols on the Lucky Molar's reels.
const SLOT_SYMBOLS: Array[String] = ["CHERRY", "BELL", "BAR", "SEVEN", "CROC"]


## Three random symbols.
static func spin_reels(rng: RandomNumberGenerator) -> PackedStringArray:
	var reels := PackedStringArray()
	for i in 3:
		reels.append(SLOT_SYMBOLS[rng.randi_range(0, SLOT_SYMBOLS.size() - 1)])
	return reels


## What a spin pays: three SEVENs, three of a kind, two of a kind, or nothing.
static func slots_payout(reels: PackedStringArray, tuning: Tuning) -> int:
	if reels[0] == reels[1] and reels[1] == reels[2]:
		return tuning.slots_jackpot_pays if reels[0] == "SEVEN" else tuning.slots_three_pays
	if reels[0] == reels[1] or reels[1] == reels[2] or reels[0] == reels[2]:
		return tuning.slots_pair_pays
	return 0


static func _slots_words(won: int, tuning: Tuning, rng: RandomNumberGenerator) -> String:
	var currency := GameState.names.currency_short
	if won >= tuning.slots_jackpot_pays:
		return "JACKPOT! +%d %s. Lights, bells, a recording of Sal yelling CHAMP!" % [won, currency]
	if won >= tuning.slots_three_pays:
		return "Three of a kind! +%d %s. She allows herself one (1) small smile." % [won, currency]
	if won > 0:
		return "Two alike. +%d %s. Not quite your money back." % [won, currency]
	var shrugs := ["Nothing. The croc keeps grinning.", "Nope.", "The machine plays a sad little tune.", "So close. (Not close.)"]
	return shrugs[rng.randi_range(0, shrugs.size() - 1)]


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
	if int(pay.get("hold", 0)) > 0:
		lines.append("Big hold bonus:  +%d %s" % [pay["hold"], currency])
	lines.append("")
	lines.append("TOTAL:  +%d %s" % [pay["total"], currency])
	if int(pay.get("tab_paid", 0)) > 0:
		lines.append("Paid off your tab:  -%d %s" % [pay["tab_paid"], currency])
	lines.append("")
	if pay.has("road_minutes"):
		lines.append("%s on the road. It's %s, %s." % [Economy.span_text(float(pay["road_minutes"])), Economy.date_text(), Economy.clock_text()])
		var rig_name := GameState.active_ship_data().display_name
		if int(pay.get("levels", 0)) > 0:
			lines.append("+%d XP. %s is now LEVEL %d!" % [pay["xp"], rig_name, pay["level"]])
		else:
			lines.append("+%d XP for %s (level %d)." % [pay["xp"], rig_name, pay["level"]])
	if GameState.pending_bills.is_empty():
		lines.append("Wallet: %d %s" % [GameState.credits, currency])  # (Otherwise it's on the bills card.)
	if int(pay.get("levels", 0)) > 0:
		Sfx.play("pickup")
	await MenuPanel.ask(tree, "DELIVERED!", "\n".join(lines), [{"text": "NICE"}])
	await show_bills(tree)


## The weekly bills card, if bills came due (GameState.pending_bills).
static func show_bills(tree: SceneTree) -> void:
	var bill := GameState.pending_bills
	if bill.is_empty():
		return
	GameState.pending_bills = {}
	var currency := GameState.names.currency_short
	var lines := PackedStringArray()
	var weeks := int(bill["weeks"])
	lines.append("%s for %d week%s on %s's books." % ["Berth and dispatch fee", weeks, "s" if weeks > 1 else "", GameState.names.company_name])
	lines.append("")
	lines.append("Berth and dispatch:  %d %s" % [bill["dispatch"], currency])
	if int(bill["insurance"]) > 0:
		lines.append("Insurance:  %d %s" % [bill["insurance"], currency])
	lines.append("")
	lines.append("Paid:  %d %s" % [bill["paid"], currency])
	if int(bill["on_tab"]) > 0:
		lines.append("On your tab:  %d %s (paid off from your next delivery, no rush)" % [bill["on_tab"], currency])
	lines.append("Wallet: %d %s" % [GameState.credits, currency])
	await MenuPanel.ask(tree, "WEEKLY BILLS", "\n".join(lines), [{"text": "SIGH. OKAY"}])


static func _too_poor(tree: SceneTree) -> void:
	Sfx.play("nope")
	await MenuPanel.ask(tree, "NOT ENOUGH", "You check your wallet. Then you check it again. Nope.", [{"text": "OKAY"}])
