class_name FlightChatter
extends Resource
## All the comm chatter you can hear while flying. Add lines by editing the
## sets in res://data/dialogue/flight_chatter.tres, or add a whole new set
## (a new person, a new situation, a new place or part of the story).


@export var sets: Array[ChatterSet] = []


## Every [speaker, line] pair that fits a situation right now. Sets made for
## this exact moment (a place, a job, story flags) win over general ones.
func lines_for(situation: ChatterSet.Situation, at_place: String = "") -> Array:
	var specific := []
	var general := []
	for chatter_set in sets:
		if chatter_set == null or chatter_set.situation != situation or chatter_set.speaker == null:
			continue
		if not chatter_set.matches(at_place):
			continue
		var picky := not chatter_set.place.is_empty() or not chatter_set.needs_flags.is_empty() \
				or not chatter_set.blocked_by_flags.is_empty() or not chatter_set.needs_active_job.is_empty() \
				or chatter_set.needs_no_job
		for line in chatter_set.lines:
			(specific if picky else general).append([chatter_set.speaker, line])
	return specific if not specific.is_empty() else general
