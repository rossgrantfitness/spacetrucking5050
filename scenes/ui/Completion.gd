class_name Completion
extends RefCounted
## The completion percentage (like Stardew Valley's "perfection"): how much
## of everything there is to do, you've done. Shown in the pause menu and
## the company office. Each part has a weight (how much of the 100% it's
## worth); they're in PARTS below, and everything counted comes from the
## data files, so new jobs, rigs and sights count automatically.


## [what, weight]. The weights add up to 100.
const PARTS: Array[Array] = [
	["Buying the company", 20.0],
	["Different loads delivered", 15.0],
	["Story deliveries", 10.0],
	["Sights in the logbook", 15.0],
	["Upgrades", 10.0],
	["Rigs", 10.0],
	["Places visited", 10.0],
	["Snacks tasted", 10.0],
]


## The whole thing, 0 to 100 (rounded down, so 100% means everything).
static func percent() -> int:
	var total := 0.0
	for part in breakdown():
		total += float(part[3])
	return mini(floori(total + 0.0001), 100)


## Each part: [what, done, out of, points earned].
static func breakdown() -> Array:
	var counts := _counts()
	var parts: Array = []
	for part in PARTS:
		var count: Vector2i = counts.get(part[0], Vector2i.ZERO)
		var share := float(count.x) / float(count.y) if count.y > 0 else 0.0
		parts.append([part[0], count.x, count.y, float(part[1]) * clampf(share, 0.0, 1.0)])
	return parts


## [done, out of] for each part.
static func _counts() -> Dictionary:
	var delivered := 0
	var story_done := 0
	var story_total := 0
	for job in GameState.jobs.jobs:
		if job == null:
			continue
		var done := _delivered(job.id)
		delivered += 1 if done else 0
		if not job.repeatable:
			story_total += 1
			story_done += 1 if done else 0
	var places_total := 0
	var places_seen := 0
	for place in GameState.places.places:
		if place != null and place.on_the_map:
			places_total += 1
			places_seen += 1 if int(GameState.visits.get(place.id, 0)) > 0 else 0
	return {
		"Buying the company": Vector2i(1 if GameState.has_flag("owns_company") else 0, 1),
		"Different loads delivered": Vector2i(delivered, GameState.jobs.jobs.size()),
		"Story deliveries": Vector2i(story_done, story_total),
		"Sights in the logbook": Vector2i(GameState.logbook.size(), GameState.sights.entries.size()),
		"Upgrades": Vector2i(GameState.owned_upgrades.size(), GameState.upgrades.upgrades.size()),
		"Places visited": Vector2i(places_seen, places_total),
		"Snacks tasted": Vector2i(Snack.tried_count(), GameState.brands.products.size()),
	}


## Whether a job has ever been delivered (it leaves a flag saying how it
## arrived).
static func _delivered(job_id: String) -> bool:
	for how in ["_arrived_perfect", "_arrived_bumpy", "_arrived_rough"]:
		if GameState.has_flag(job_id + how):
			return true
	return false
