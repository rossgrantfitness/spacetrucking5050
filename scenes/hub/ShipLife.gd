class_name ShipLife
extends RefCounted
## Life aboard the rig, Animal Crossing style: where each crew member is,
## what they're doing and what they say, and the little things that happen
## aboard (ship events).
##
## HOW IT CHANGES: everything is picked from a "moment": the day, the trip
## (each haul) and whether you're flying or parked. So it stays the same
## while you walk between rooms, but every new trip and every new day the
## crew have moved on to something else. About two moments in five, a ship
## event happens (card night, a broken coffee machine, a lost wrench...).
##
## WHAT THEY SAY: the first chat of the day starts with a greeting (and
## counts as a day of friendship), then a line about what they're up to,
## then a bit of small talk they haven't said in a while. Some small talk
## only comes out once you've chatted on enough different days.
##
## The crew, their activities and lines, and the events are all data, in
## res://data/crew/crew.tres. Nothing here needs changing to add more.


const Situation := CrewActivity.Situation
## How often a moment has a ship event (0 = never, 1 = always).
const EVENT_CHANCE: float = 0.4

## Whether the rig's flying right now (FlightSandbox sets it while you're
## up and about in flight).
static var in_flight: bool = false


## The current moment (see above).
static func moment() -> int:
	return GameState.day * 1000 + GameState.hauls * 2 + (1 if in_flight else 0)


## Whether something with this situation and story flag can happen now.
static func fits(situation: Situation, needs_flag: String) -> bool:
	if not needs_flag.is_empty() and not GameState.has_flag(needs_flag):
		return false
	match situation:
		Situation.IN_FLIGHT:
			return in_flight
		Situation.PARKED:
			return not in_flight
		Situation.NIGHT:
			return TimeOfDay.is_night()
		Situation.DAY:
			return not TimeOfDay.is_night()
		Situation.HAS_JOB:
			return not GameState.active_job_id.is_empty()
		Situation.NO_JOB:
			return GameState.active_job_id.is_empty()
		Situation.JUST_PAID:
			return not GameState.invoices.is_empty() and int(GameState.invoices[-1]["day"]) == GameState.day
	return true


## The ship event happening right now, or null.
static func current_event() -> ShipEvent:
	var rng := _rng("event")
	if rng.randf() > EVENT_CHANCE:
		return null
	var options: Array = []
	for event in GameState.crew.events:
		if event != null and fits(event.situation, event.needs_flag):
			options.append(event)
	return _pick(options, rng) as ShipEvent


## What `member` is up to right now.
static func activity_for(member: CrewMember) -> CrewActivity:
	var event := current_event()
	if event != null:
		for role in event.roles:
			if role != null and role.crew == member.id:
				return role
	var options: Array = []
	for activity in member.activities:
		if activity != null and fits(activity.situation, activity.needs_flag):
			options.append(activity)
	return _pick(options, _rng(member.id)) as CrewActivity


## Who's in the room at `room_path` right now: [{"member", "activity"}].
static func crew_in(room_path: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for member in GameState.crew.crew:
		if member == null:
			continue
		var activity := activity_for(member)
		if activity != null and activity.room == room_path:
			found.append({"member": member, "activity": activity})
	return found


## What `member` says when you talk to them while they're doing `activity`.
## Talking counts: once a day it's a day of friendship, small talk is
## remembered so it doesn't repeat, and lost things get handed back.
static func conversation(member: CrewMember, activity: CrewActivity) -> PackedStringArray:
	var memory := GameState.crew_memory
	var said := PackedStringArray()
	var talked: Dictionary = memory.get_or_add("talked_day", {})
	if int(talked.get(member.id, 0)) != GameState.day:
		talked[member.id] = GameState.day
		var friends: Dictionary = memory.get_or_add("friendship", {})
		friends[member.id] = int(friends.get(member.id, 0)) + 1
		if not member.greetings.is_empty():
			said.append(member.greetings[_rng(member.id + " greeting").randi_range(0, member.greetings.size() - 1)])
	# Bringing back something they lost?
	var event := current_event()
	if event != null and event.find_owner == member.id and has_found(event) and not _was_returned(event):
		var returned: Dictionary = memory.get_or_add("returned", {})
		returned[event.id] = moment()
		said.append_array(event.find_thanks)
		if event.find_reward > 0:
			GameState.add_credits(event.find_reward)
			said.append("(+%d %s)" % [event.find_reward, GameState.names.currency_short])
		return _filled(said)
	if activity != null:
		said.append_array(activity.lines)
	var chat := _small_talk(member)
	if chat != null:
		said.append_array(chat.lines)
		if not chat.sets_flag.is_empty():
			GameState.set_flag(chat.sets_flag)
	return _filled(said)


## How many different days you've chatted with `member`.
static func friendship(member_id: String) -> int:
	var friends: Dictionary = GameState.crew_memory.get("friendship", {})
	return int(friends.get(member_id, 0))


## Whether this moment's lost thing has been found (picked up).
static func has_found(event: ShipEvent) -> bool:
	var found: Dictionary = GameState.crew_memory.get("found", {})
	return int(found.get(event.id, -1)) == moment()


## Picks up this moment's lost thing.
static func pick_up(event: ShipEvent) -> void:
	var found: Dictionary = GameState.crew_memory.get_or_add("found", {})
	found[event.id] = moment()


## Whether the event's title has been shown yet this moment (and marks it shown).
static func first_look(event: ShipEvent) -> bool:
	var seen: Dictionary = GameState.crew_memory.get_or_add("event_seen", {})
	if int(seen.get(event.id, -1)) == moment():
		return false
	seen[event.id] = moment()
	return true


static func _was_returned(event: ShipEvent) -> bool:
	var returned: Dictionary = GameState.crew_memory.get("returned", {})
	return int(returned.get(event.id, -1)) == moment()


## The small talk they haven't said for the longest (ties: a random one).
static func _small_talk(member: CrewMember) -> CrewLine:
	var memory := GameState.crew_memory
	var heard: Dictionary = memory.get_or_add("heard", {})
	var clock := int(memory.get("clock", 0)) + 1
	memory["clock"] = clock
	var best: CrewLine = null
	var best_key := ""
	var oldest := INF
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s %d" % [member.id, clock])
	for i in member.small_talk.size():
		var line := member.small_talk[i]
		if line == null or not fits(line.situation, line.needs_flag) or friendship(member.id) < line.min_friendship:
			continue
		var key := "%s:%d" % [member.id, i]
		var last := float(heard.get(key, -1)) + rng.randf() * 0.5
		if last < oldest:
			oldest = last
			best = line
			best_key = key
	if best != null:
		heard[best_key] = clock
	return best


static func _filled(lines: PackedStringArray) -> PackedStringArray:
	var job := GameState.active_job()
	var place := GameState.places.find(GameState.launch_from)
	var out := PackedStringArray()
	for line in lines:
		var text := GameState.names.fill_in(line)
		text = text.replace("{cargo}", job.cargo_name.to_lower() if job != null else "nothing")
		text = text.replace("{place}", place.display_name if place != null else "out here")
		out.append(text)
	return out


## A random pick by weight (each item has a `weight`).
static func _pick(items: Array, rng: RandomNumberGenerator) -> Resource:
	var total := 0.0
	for item: Resource in items:
		total += float(item.get("weight"))
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for item: Resource in items:
		roll -= float(item.get("weight"))
		if roll <= 0.0:
			return item
	return items[-1]


static func _rng(salt: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d %s" % [moment(), salt])
	return rng
