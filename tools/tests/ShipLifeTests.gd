extends "res://tools/tests/TestSuite.gd"
## Checks for life aboard the rig (scenes/hub/ShipLife.gd and
## data/crew/crew.tres): the crew data points at real rooms and spots, the
## crew stay put within a moment but move on between trips, talking builds
## friendship without repeating small talk, and lost things can be returned.
## Every test puts GameState back the way it found it.

const SCRATCH_SAVE: String = "user://self_test_save.json"


func _fresh() -> Dictionary:
	SaveSystem.save_path = SCRATCH_SAVE
	var before := GameState.to_save_data()
	GameState.new_game()
	ShipLife.in_flight = false
	return before


func _restore(before: Dictionary) -> void:
	GameState.apply_save_data(before)
	ShipLife.in_flight = false
	SaveSystem.save_path = "user://save.json"


## Whether `room_path` has a CrewSpots marker called `spot`.
func _has_spot(room_path: String, spot: String) -> bool:
	if not ResourceLoader.exists(room_path):
		return false
	var room := (load(room_path) as PackedScene).instantiate()
	var found := room.has_node("CrewSpots/" + spot)
	room.free()
	return found


func test_crew_data_points_at_real_rooms_and_spots() -> void:
	var roster := GameState.crew
	check(roster != null and roster.crew.size() >= 3, "the rig should have a crew")
	var ids := {}
	for member in roster.crew:
		check(not ids.has(member.id), "crew ids should be unique (%s)" % member.id)
		ids[member.id] = true
		check(member.npc != null and member.visual != null, "%s needs a name/voice and a model" % member.id)
		check(not member.activities.is_empty() and not member.small_talk.is_empty(), "%s needs things to do and say" % member.id)
		for activity in member.activities:
			check(_has_spot(activity.room, activity.spot), "%s's '%s' needs spot %s in %s" % [member.id, activity.id, activity.spot, activity.room])
			check(activity.pose in ["stand", "sit", "sleep", "work", "eat", "read", "dance", "wave", "lean"], "%s's '%s' has an unknown pose" % [member.id, activity.id])
			check(activity.prop.is_empty() or CrewNPC.PROP_COLORS.has(activity.prop), "%s's '%s' has an unknown prop" % [member.id, activity.id])
	for event in roster.events:
		for role in event.roles:
			check(ids.has(role.crew), "event %s gives a part to unknown crew %s" % [event.id, role.crew])
			check(_has_spot(role.room, role.spot), "event %s puts %s at a missing spot %s" % [event.id, role.crew, role.spot])
		if not event.find_item.is_empty():
			check(_has_spot(event.find_room, event.find_spot), "event %s hides its %s at a missing spot" % [event.id, event.find_item])
			check(ids.has(event.find_owner), "event %s's lost thing needs an owner" % event.id)


func test_crew_stay_put_within_a_moment_and_move_on_later() -> void:
	var before := _fresh()
	var dottie := GameState.crew.find("dottie")
	var first := ShipLife.activity_for(dottie)
	check(ShipLife.activity_for(dottie) == first, "asking twice in the same moment gives the same activity")
	var seen := {}
	var events := {}
	for day in range(1, 60):
		GameState.day = day
		seen[ShipLife.activity_for(dottie).id] = true
		var event := ShipLife.current_event()
		events[event.id if event != null else ""] = true
	check(seen.size() >= 3, "over a couple of months Dottie should get up to at least 3 different things (got %d)" % seen.size())
	check(events.size() >= 3 and events.has(""), "some days have ship events and some are quiet")
	_restore(before)


func test_everyone_is_somewhere_exactly_once() -> void:
	var before := _fresh()
	for day in range(1, 30):
		GameState.day = day
		var counted := {}
		for room in ["Apartment", "Hallway", "Dispatch", "Galley", "EngineRoom", "CargoBay"]:
			for entry in ShipLife.crew_in("res://scenes/hub/%s.tscn" % room):
				var id: String = (entry["member"] as CrewMember).id
				check(not counted.has(id), "day %d: %s should only be in one room" % [day, id])
				counted[id] = true
		check(counted.size() == GameState.crew.crew.size(), "day %d: every crew member should be somewhere aboard" % day)
	_restore(before)


func test_talking_builds_friendship_and_varies_small_talk() -> void:
	var before := _fresh()
	var digby := GameState.crew.find("digby")
	var activity := ShipLife.activity_for(digby)
	var first := ShipLife.conversation(digby, activity)
	check(not first.is_empty(), "Digby should have something to say")
	check(ShipLife.friendship("digby") == 1, "the first chat of the day counts as a day of friendship")
	var second := ShipLife.conversation(digby, activity)
	check(ShipLife.friendship("digby") == 1, "chatting again the same day doesn't count twice")
	check(first != second, "the second chat of the day says something new")
	for line in first:
		check(not "{" in line, "names and places get filled in: %s" % line)
	GameState.day += 1
	ShipLife.conversation(digby, ShipLife.activity_for(digby))
	check(ShipLife.friendship("digby") == 2, "a chat on a new day is another day of friendship")
	_restore(before)


func test_lost_things_can_be_returned_once() -> void:
	var before := _fresh()
	var lost: ShipEvent = null
	for day in range(1, 400):
		GameState.day = day
		var event := ShipLife.current_event()
		if event != null and not event.find_item.is_empty():
			lost = event
			break
	check(lost != null, "some day should have a lost thing to find")
	if lost != null:
		var owner := GameState.crew.find(lost.find_owner)
		var credits := GameState.credits
		ShipLife.conversation(owner, ShipLife.activity_for(owner))
		check(GameState.credits == credits, "no reward before it's found")
		ShipLife.pick_up(lost)
		check(ShipLife.has_found(lost), "picked up")
		var thanks := ShipLife.conversation(owner, ShipLife.activity_for(owner))
		check(GameState.credits == credits + lost.find_reward, "handing it back pays the reward")
		check(thanks.has(lost.find_thanks[0]), "they thank you for it")
		ShipLife.conversation(owner, ShipLife.activity_for(owner))
		check(GameState.credits == credits + lost.find_reward, "the reward is only paid once")
	_restore(before)


func test_crew_memory_survives_saving() -> void:
	var before := _fresh()
	var dottie := GameState.crew.find("dottie")
	ShipLife.conversation(dottie, ShipLife.activity_for(dottie))
	var saved := JSON.parse_string(JSON.stringify(GameState.to_save_data())) as Dictionary
	GameState.new_game()
	check(ShipLife.friendship("dottie") == 0, "a new game forgets the crew")
	GameState.apply_save_data(saved)
	check(ShipLife.friendship("dottie") == 1, "loading a save remembers chatting with Dottie")
	_restore(before)
