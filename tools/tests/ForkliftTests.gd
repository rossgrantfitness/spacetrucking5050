extends "res://tools/tests/TestSuite.gd"
## Checks for the forklift loading minigame (scenes/ui/forklift/): a simple
## robot driver can load every pallet, bumps never fail it, and a job's
## pallet count stays sensible.


## Drives `rules` like a careful player: to the nearest pallet on the dock,
## lift, into the hold, set it in the farthest free spot. Returns the
## seconds it took (or INF if it got stuck).
func _robot(rules: ForkliftRules, limit: float) -> float:
	var delta := 1.0 / 60.0
	var time := 0.0
	while not rules.done and time < limit:
		time += delta
		var target := _target(rules)
		var point := rules.fork_tip() if rules.carrying < 0 else (rules.pallets[rules.carrying]["at"] as Vector2)
		# Line up from the open side of the hold before driving in.
		var aim := target
		if rules.carrying >= 0 and rules.position.x < ForkliftRules.HOLD.position.x - 4.0 and absf(rules.position.y - target.y) > 4.0:
			aim = Vector2(ForkliftRules.HOLD.position.x - 18.0, target.y)
		var diff := wrapf((aim - rules.position).angle() - rules.heading, -PI, PI)
		var close := point.distance_to(target) < (6.0 if rules.carrying < 0 else 3.0)
		if close:
			rules.use_forks()
			continue
		rules.step(delta, 1.0 if absf(diff) < 0.35 else 0.15, clampf(diff * 3.0, -1.0, 1.0))
	return time if rules.done else INF


func _target(rules: ForkliftRules) -> Vector2:
	if rules.carrying < 0:
		var best := Vector2.ZERO
		var best_distance := INF
		for pallet in rules.pallets:
			if int(pallet["slot"]) < 0 and rules.position.distance_to(pallet["at"]) < best_distance:
				best_distance = rules.position.distance_to(pallet["at"])
				best = pallet["at"]
		return best
	# The farthest free spot first (so the near ones don't block the way).
	var spot := Vector2(-INF, 0.0)
	for i in rules.slots.size():
		var taken := false
		for pallet in rules.pallets:
			if int(pallet["slot"]) == i:
				taken = true
		if not taken and rules.slots[i].x > spot.x:
			spot = rules.slots[i]
	return spot


func test_a_careful_driver_loads_everything() -> void:
	for count in [3, 4, 6]:
		var rules := ForkliftRules.new(count)
		var seconds := _robot(rules, 240.0)
		check(rules.done and rules.loaded() == count, "%d pallets can all be loaded (took %.0f s)" % [count, seconds])


func test_bumps_are_only_bumps() -> void:
	var rules := ForkliftRules.new(3)
	var bumped := false
	for i in 300:
		bumped = rules.step(1.0 / 60.0, 1.0, 0.0) == "bump" or bumped  # Full speed into the dock wall.
	check(bumped and rules.bumps > 0 and not rules.done, "driving into a wall is a bump, nothing worse")
	check(rules.position.x >= ForkliftRules.BODY_RADIUS - 0.01, "and the forklift stays on the floor")


func test_pallets_for_jobs() -> void:
	for job in GameState.jobs.jobs:
		var count := HubServices.pallets_for(job)
		check(count >= 3 and count <= 6, "%s is 3 to 6 pallets" % job.id)
