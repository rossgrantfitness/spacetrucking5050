extends "res://tools/tests/TestSuite.gd"
## Checks for the round-10 route events: the whole design list is in the
## data, every playable event does something, and the director follows its
## rules (zones, cooldowns, one hazard at a time, one rare per haul,
## weather, story and night-only events).


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _find(id: String) -> EventData:
	for event in RouteEvents.EVENTS.events:
		if event != null and event.id == id:
			return event
	return null


## Keeps the parts of the game state these tests change, to put back after.
func _keep() -> Dictionary:
	return {"hauls": GameState.hauls, "history": GameState.event_history.duplicate(), "flags": GameState.flags.duplicate(),
			"rare": GameState.tuning.event_rare_chance}


func _restore(kept: Dictionary) -> void:
	GameState.hauls = kept["hauls"]
	GameState.event_history = kept["history"]
	GameState.flags = kept["flags"]
	GameState.tuning.event_rare_chance = kept["rare"]


func test_the_whole_design_list_is_in_the_data() -> void:
	var numbers := {}
	var ids := {}
	for event in RouteEvents.EVENTS.events:
		check(event != null, "no empty slots in the route events list")
		if event == null:
			continue
		check(not ids.has(event.id), "route event ids are unique (%s)" % event.id)
		ids[event.id] = true
		if event.number > 0:
			check(not numbers.has(event.number), "each number from the list is there once (#%d)" % event.number)
			numbers[event.number] = true
		check(not event.title.is_empty() and not event.summary.is_empty(), "%s has a title and a summary" % event.id)
		if not event.playable:
			check(not event.needs.is_empty(), "%s (not built yet) says what it needs" % event.id)
	for number in range(1, 168):
		check(numbers.has(number), "event #%d from the list is in the data" % number)
	var twin := _find("the_twin_rig")
	check(twin != null and twin.rarity == EventData.Rarity.LEGENDARY and not twin.story_flag.is_empty(), "the twin rig is a legendary story event")


func test_every_playable_event_does_something() -> void:
	var director := RouteEvents.new()
	var playable := 0
	for event in RouteEvents.EVENTS.events:
		if event == null or not event.playable:
			continue
		playable += 1
		var does := event.kind != EventData.Kind.NONE or not event.lines.is_empty() or not event.dj_lines.is_empty() \
				or not event.banner.is_empty() or event.effect != EventData.Effect.NONE or event.sound != null
		check(does, "%s does something when it happens" % event.id)
		check(event.lines.is_empty() or event.speaker != null, "%s has someone to say its lines" % event.id)
		check(event.effect == EventData.Effect.NONE or event.effect_seconds > 0.0, "%s's effect lasts a while" % event.id)
		var thing := director.make(event)
		check((thing != null) == (event.kind != EventData.Kind.NONE), "%s builds its 3D thing (if it has one)" % event.id)
		if thing != null:
			thing.free()
	director.free()
	check(playable >= 50, "lots of the list is playable now (%d)" % playable)
	var whales := _find("whales")
	check(whales != null and whales.allowed_in("tidewater") and not whales.allowed_in("home"), "whales only swim in Tidewater")


func test_zones_depend_on_where_you_are() -> void:
	var director := RouteEvents.new()
	var station := Node3D.new()
	_tree().root.add_child(director)
	_tree().root.add_child(station)
	director.start(null, null, null, {"somewhere": station}, Callable())
	var tuning := GameState.tuning
	check(director.zone_at(Vector3(0.0, 0.0, tuning.event_approach_radius * 0.5)) == EventData.Zone.STATION_APPROACH, "close to a station is the approach")
	var lanes := (tuning.event_approach_radius + tuning.event_lane_radius) * 0.5
	check(director.zone_at(Vector3(0.0, 0.0, lanes)) == EventData.Zone.TRAFFIC_LANES, "near a station are the traffic lanes")
	check(director.zone_at(Vector3(0.0, 0.0, lanes), "ion") == EventData.Zone.WEATHER, "inside a storm is a weather zone")
	check(director.zone_at(Vector3(0.0, 0.0, 500000.0)) == EventData.Zone.DEEP_SPACE, "far from everything is deep space")
	var planet := SkyBody.new()
	planet.true_position = Vector3(0.0, 0.0, 900000.0)
	planet.true_radius = 20000.0
	_tree().root.add_child(planet)
	check(director.zone_at(Vector3(0.0, 0.0, 900000.0 - 25000.0)) == EventData.Zone.ORBIT, "just above a planet is orbit")
	planet.free()
	station.free()
	director.free()


func test_events_happen_in_their_own_zones() -> void:
	var director := RouteEvents.new()
	var holding := _find("holding_pattern")
	var big_ship := _find("big_ship")
	check(director.odds(holding, EventData.Zone.STATION_APPROACH, "", "home") > 0.0, "a holding pattern happens on the approach")
	check(director.odds(holding, EventData.Zone.DEEP_SPACE, "", "home") == 0.0, "...not in deep space")
	check(director.odds(big_ship, EventData.Zone.TRAFFIC_LANES, "", "home") > 0.0, "big ships cross in the traffic lanes")
	var billboard := _find("billboard")
	check(director.odds(billboard, EventData.Zone.DEEP_SPACE, "", "home") > 0.0 and director.odds(billboard, EventData.Zone.ORBIT, "", "home") > 0.0,
			"billboards (ANYWHERE) show up everywhere")
	var tuning := GameState.tuning
	check(tuning.event_gap_deep_space.x >= 120.0, "deep space has long quiet stretches")
	check(tuning.event_gap_traffic_lanes.y <= 90.0, "traffic lanes are busy")
	check(director.odds(_find("waving_spacesuit"), EventData.Zone.DEEP_SPACE, "", "home") == 0.0, "events that aren't built yet never happen")
	director.free()


func test_cooldowns_count_hauls() -> void:
	var kept := _keep()
	var director := RouteEvents.new()
	var common := _find("micrometeoroid_sprinkle")
	var uncommon := _find("gravity_tide")
	GameState.hauls = 5
	GameState.note_event(common.id)
	GameState.note_event(uncommon.id)
	GameState.hauls = 7
	check(director.on_cooldown(common), "a common event waits 3 hauls")
	GameState.hauls = 8
	check(not director.on_cooldown(common), "...and then it can come back")
	check(director.on_cooldown(uncommon), "an uncommon one waits longer")
	GameState.hauls = 15
	check(not director.on_cooldown(uncommon), "...10 hauls")
	var billboard := _find("billboard")
	GameState.note_event(billboard.id)
	check(not director.on_cooldown(billboard), "everyday sights (cooldown 0) can come back any time")
	var twin := _find("the_twin_rig")
	GameState.note_event(twin.id)
	GameState.hauls = 500
	check(director.on_cooldown(twin), "a legendary event happens once per save")
	director.free()
	_restore(kept)


func test_one_hazard_at_a_time() -> void:
	var kept := _keep()
	var director := RouteEvents.new()
	var eddy := _find("gravity_eddy")
	var hail := _find("ice_hail")
	check(eddy.is_hazard() and hail.is_hazard(), "eddies and hail are hazards")
	check(director.odds(hail, EventData.Zone.WEATHER, "ice", "home") > 0.0, "hail can happen in an icy storm")
	director.trigger(eddy)
	check(director.hazard_active(), "a gravity eddy is a hazard going on")
	check(director.odds(hail, EventData.Zone.WEATHER, "ice", "home") == 0.0, "no second hazard while one is going on")
	check(director.current_effect() == EventData.Effect.NUDGE, "the eddy nudges the rig")
	director.free()
	_restore(kept)


func test_weather_story_and_night_rules() -> void:
	var kept := _keep()
	var director := RouteEvents.new()
	var hail := _find("ice_hail")
	check(director.odds(hail, EventData.Zone.WEATHER, "ion", "home") == 0.0, "an ion storm skips hail (different weather)")
	var outside := director.odds(hail, EventData.Zone.DEEP_SPACE, "", "home")
	check(outside > 0.0 and outside < hail.weight, "weather events can happen out in the open too, less often")
	var twin := _find("the_twin_rig")
	check(director.odds(twin, EventData.Zone.DEEP_SPACE, "", "home") == 0.0, "story events wait for the story")
	GameState.set_flag(twin.story_flag)
	check(director.odds(twin, EventData.Zone.DEEP_SPACE, "", "home") > 0.0, "...and happen once it gets there")
	var sleepy := _find("sleepy_controller")
	check(sleepy.night_only, "the sleepy controller works nights")
	check((director.odds(sleepy, EventData.Zone.STATION_APPROACH, "", "home") > 0.0) == TimeOfDay.is_night(), "night-only events only happen at night")
	director.free()
	_restore(kept)


func test_rare_events_at_most_once_per_haul() -> void:
	var kept := _keep()
	GameState.tuning.event_rare_chance = 1.0
	GameState.event_history = {}
	var director := RouteEvents.new()
	var first := director.spawn_something()
	check(first != null and first.is_rare(), "with the rare chance at 100%%, the first event is rare")
	var second := director.spawn_something()
	check(second == null or not second.is_rare(), "but never two rare events in one haul")
	director.free()
	Radio.set("_dead_air", 0.0)  # In case it picked dead air.
	Radio.set("_interference", 0.0)
	_restore(kept)


func test_hauls_and_event_history_are_saved() -> void:
	var before := GameState.to_save_data()
	GameState.hauls = 41
	GameState.start_haul()
	GameState.note_event("dead_air")
	var data := GameState.to_save_data()
	GameState.hauls = 0
	GameState.event_history = {}
	GameState.apply_save_data(JSON.parse_string(JSON.stringify(data)))
	check(GameState.hauls == 42, "the haul count is saved")
	check(int(GameState.event_history.get("dead_air", -1)) == 42, "what happened on which haul is saved")
	GameState.apply_save_data(before)


func test_radio_moments() -> void:
	Radio.dead_air(3.0)
	check(Radio.is_dead_air(), "dead air silences the radio")
	Radio.set("_dead_air", 0.0)
	Radio.interference(0.1)
	check(not Radio.is_dead_air(), "static isn't silence")
