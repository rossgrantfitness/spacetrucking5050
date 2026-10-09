class_name RouteEvents
extends Node
## The route-events director: the things that happen on the long haul.
## As you drive it picks from res://data/events/route_events.tres (big
## ships, convoys, signs, junk, comm calls, DJ chatter, little hazards...)
## and makes it happen: 3D sights appear ahead of you, off to the side of
## the lane; calls come in on the comms; the radio crackles or goes quiet.
##
## The rules (from the design list, docs/ROUTE_EVENTS_LIST.md):
## - ZONES: how busy the road is depends on where you are. Deep space is
##   quiet (minutes of nothing but the radio), traffic lanes near stations
##   and border gates are busy, the station approach is busy and short,
##   orbit and storms are in between. Each event belongs to a zone (or
##   ANYWHERE).
## - Never more than one hazard at a time.
## - The same event doesn't come back for a few hauls (common: 3, uncommon:
##   10); legendary ones happen once per save; at most one rare or
##   legendary event per haul.
## - Inside a storm, weather events that don't match it are skipped.
## - Story events wait for the story; some events only happen at night.
##
## All the numbers are in tuning.tres under "Route events". Nothing happens
## at a crawl or while the docking autopilot has you.


## Asks the flight scene to show a banner on the HUD.
signal banner_requested(text: String, seconds: float)

const EVENTS: RouteEventList = preload("res://data/events/route_events.tres")
## How long a hazard counts as "going on" when it has no 3D thing or
## effect to watch (a call about a holding pattern), in seconds.
const HAZARD_DEFAULT_SECONDS: float = 40.0

var _ship: Ship
var _holder: Node3D
var _chatter: CommChatter
var _places: Dictionary = {}
var _current_system: Callable
var _active: Array[RoadsideThing] = []
## Seconds of driving until the next event.
var _wait: float = 0.0
var _zone: EventData.Zone = EventData.Zone.DEEP_SPACE
## The last few events (and kinds of 3D sight), so nothing repeats too soon.
var _recent_ids: Array[String] = []
var _recent_kinds: Array[int] = []
var _rare_this_haul: bool = false
## The hazard going on right now (a 3D thing, or seconds of an effect).
var _hazard_thing: RoadsideThing
var _hazard_left: float = 0.0
## The effect going on right now (see EventData.Effect).
var _effect: EventData.Effect = EventData.Effect.NONE
var _effect_left: float = 0.0
var _effect_length: float = 0.0
var _effect_clock: float = 0.0
var _effect_side := Vector3.RIGHT
var _rng := RandomNumberGenerator.new()
var _sound: AudioStreamPlayer


func _ready() -> void:
	_sound = AudioStreamPlayer.new()
	_sound.volume_db = -4.0
	add_child(_sound)


## `holder` is where spawned things go; `current_system` returns the id of
## the solar system the rig is in.
func start(ship: Ship, holder: Node3D, chatter: CommChatter, places: Dictionary, current_system: Callable) -> void:
	_ship = ship
	_holder = holder
	_chatter = chatter
	_places = places
	_current_system = current_system
	_rng.randomize()
	_zone = zone_here() if _ship != null else EventData.Zone.DEEP_SPACE
	_wait = _gap_for(_zone)


func _physics_process(delta: float) -> void:
	if _ship == null:
		return
	_clean_up()
	_update_effect(delta)
	_hazard_left = maxf(_hazard_left - delta, 0.0)
	var tuning := GameState.tuning
	if _ship.flight.speed() < tuning.event_min_speed or not _ship.autopilot_route.is_empty():
		return
	var zone := zone_here()
	if zone != _zone:
		# Into a busier zone: don't sit out a long deep-space wait.
		_zone = zone
		_wait = minf(_wait, _gap_range(zone).y)
	_wait -= delta
	if _wait > 0.0:
		return
	spawn_something()
	_wait = _gap_for(_zone)


# --- Where are we? ------------------------------------------------------------------

## Which zone the rig is in right now.
func zone_here() -> EventData.Zone:
	return zone_at(_ship.global_position, weather_here())


## Which zone a spot is in. `weather` is the weather there ("" = clear).
func zone_at(spot: Vector3, weather: String = "") -> EventData.Zone:
	var tuning := GameState.tuning
	var nearest := _nearest_place(spot)
	if nearest < tuning.event_approach_radius:
		return EventData.Zone.STATION_APPROACH
	if not weather.is_empty():
		return EventData.Zone.WEATHER
	if nearest < tuning.event_lane_radius:
		return EventData.Zone.TRAFFIC_LANES
	if is_inside_tree():
		for gate: Node3D in get_tree().get_nodes_in_group("border_gates"):
			if gate.global_position.distance_to(spot) < tuning.event_lane_radius:
				return EventData.Zone.TRAFFIC_LANES
		for body: SkyBody in get_tree().get_nodes_in_group("sky_bodies"):
			if not body.is_sun and body.true_position.distance_to(spot) - body.true_radius < tuning.event_orbit_altitude:
				return EventData.Zone.ORBIT
	return EventData.Zone.DEEP_SPACE


## The weather the rig is in ("" = clear skies).
func weather_here() -> String:
	if _ship != null and _ship.storm > 0.05:
		return "ion"
	return ""


## Whether a hazard is going on right now (only one at a time).
func hazard_active() -> bool:
	if _hazard_left > 0.0 or (is_instance_valid(_hazard_thing) and _hazard_thing in _active):
		return true
	return _ship != null and (_ship.storm > 0.05 or _ship.speed_trap > 0.05)


# --- Picking --------------------------------------------------------------------------

## Makes something happen, picked for the zone you're in. Returns what
## happened (or null if nothing fits right now). Public so the tests and
## the HUD demo can call it.
func spawn_something() -> EventData:
	var zone := zone_here() if _ship != null else EventData.Zone.DEEP_SPACE
	var weather := weather_here()
	var system_id: String = _current_system.call() if _current_system.is_valid() else "home"
	# Once in a long while (never twice in a haul): something rare.
	if not _rare_this_haul and _rng.randf() < GameState.tuning.event_rare_chance:
		var rare := pick(zone, weather, system_id, true)
		if rare != null and trigger(rare):
			_rare_this_haul = true
			return rare
	var picked := pick(zone, weather, system_id, false)
	if picked != null and trigger(picked):
		return picked
	return null


## Picks an event for a zone (by weight), or null if nothing fits. With
## `rare` on, only rare and legendary ones; otherwise only common and
## uncommon ones.
func pick(zone: EventData.Zone, weather: String, system_id: String, rare: bool) -> EventData:
	var options: Array[EventData] = []
	var weights: Array[float] = []
	var total := 0.0
	for event in EVENTS.events:
		if event == null or event.is_rare() != rare:
			continue
		var weight := odds(event, zone, weather, system_id)
		if weight <= 0.0:
			continue
		options.append(event)
		weights.append(weight)
		total += weight
	if options.is_empty():
		_recent_ids.clear()  # Everything's been seen lately: start over.
		return null
	var roll := _rng.randf() * total
	for i in options.size():
		roll -= weights[i]
		if roll <= 0.0:
			return options[i]
	return options[-1]


## How likely `event` is right here, right now (0 = it can't happen).
func odds(event: EventData, zone: EventData.Zone, weather: String, system_id: String) -> float:
	if not event.playable or event.weight <= 0.0 or not event.allowed_in(system_id):
		return 0.0
	var weight := event.weight
	if event.zone == EventData.Zone.WEATHER and zone in [EventData.Zone.DEEP_SPACE, EventData.Zone.ORBIT]:
		weight *= GameState.tuning.event_weather_outside  # A little weather of its own.
	elif event.zone != zone and event.zone != EventData.Zone.ANYWHERE:
		return 0.0
	if zone == EventData.Zone.WEATHER and not event.weather.is_empty() and event.weather != weather:
		return 0.0  # Not this storm's kind of weather.
	if event.night_only and not TimeOfDay.is_night():
		return 0.0
	if not event.story_flag.is_empty() and not GameState.has_flag(event.story_flag):
		return 0.0
	if on_cooldown(event):
		return 0.0
	if event.is_hazard() and hazard_active():
		return 0.0
	if event.id in _recent_ids:
		return 0.0
	if event.kind != EventData.Kind.NONE:
		if event.kind in _recent_kinds or _active.size() >= GameState.tuning.event_max_active:
			return 0.0
		if zone != EventData.Zone.STATION_APPROACH and _ship != null and _nearest_place(_ship.global_position) < GameState.tuning.event_keep_clear:
			return 0.0  # Keep 3D things clear of stations.
	return weight


## Whether `event` happened too recently to happen again.
func on_cooldown(event: EventData) -> bool:
	if not GameState.event_history.has(event.id):
		return false
	if event.rarity == EventData.Rarity.LEGENDARY:
		return true  # Once per save.
	var hauls := event.cooldown_hauls
	if hauls < 0:
		hauls = GameState.tuning.event_cooldown_common if event.rarity == EventData.Rarity.COMMON else GameState.tuning.event_cooldown_uncommon
	return GameState.hauls - int(GameState.event_history[event.id]) < hauls


# --- Making it happen ----------------------------------------------------------------

## Makes `event` happen: the 3D thing, the call, the radio, the banner, the
## effect. Returns false if nothing could happen (say, it's only a call and
## someone's already talking).
func trigger(event: EventData) -> bool:
	var said := false
	if event.speaker != null and not event.lines.is_empty() and _chatter != null:
		said = _chatter.say_line(event.speaker, _any(event.lines), event.replies)
	var talks_only := event.kind == EventData.Kind.NONE and event.effect == EventData.Effect.NONE and event.banner.is_empty()
	if talks_only and not said and (event.dj_lines.is_empty() or not Radio.powered):
		return false
	var thing: RoadsideThing
	if event.kind != EventData.Kind.NONE and _ship != null:
		thing = spawn(event)
	if not event.dj_lines.is_empty():
		Radio.announce(_any(event.dj_lines), event.radio_from)
	if event.sound != null and _sound != null:
		_sound.stream = event.sound
		_sound.pitch_scale = event.sound_pitch
		_sound.play()
	if not event.banner.is_empty():
		banner_requested.emit(event.banner, 4.0)
	if event.effect != EventData.Effect.NONE:
		_start_effect(event.effect, event.effect_seconds)
	if event.is_hazard():
		if thing != null:
			_hazard_thing = thing
		_hazard_left = event.effect_seconds if event.effect != EventData.Effect.NONE else (0.0 if thing != null else HAZARD_DEFAULT_SECONDS)
	_remember(event)
	return true


## Puts one particular sight ahead of the rig (several, for events with
## copies). Returns it.
func spawn(event: EventData) -> RoadsideThing:
	var travel := _ship.flight.velocity.normalized() if _ship.flight.speed() > 1.0 else _ship.flight.nose()
	var side := travel.cross(Vector3.UP).normalized()
	if side.is_zero_approx():
		side = Vector3.RIGHT
	var thing: RoadsideThing
	for copy in event.copies:
		thing = make(event)
		if thing == null:
			return null
		thing.setup(_ship, travel, _rng.randi())
		thing.log_id = event.log_id
		var sideways := _rng.randf_range(event.side_offset.x, event.side_offset.y) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var up := _rng.randf_range(event.height_offset.x, event.height_offset.y)
		var further := copy * _rng.randf_range(300.0, 900.0)
		thing.position = _ship.global_position + travel * (event.ahead + further) + side * sideways + Vector3.UP * up
		if event.kind == EventData.Kind.SIGN:
			thing.basis = Basis.looking_at(travel, Vector3.UP)  # Its front faces you.
		thing.scale = Vector3.ONE * event.size
		_holder.add_child(thing)
		thing.contact_radius *= event.size
		if event.ghost:
			_make_ghost(thing)
		_active.append(thing)
	return thing


## Builds the 3D thing for an event (not yet placed or added). Null for
## events with nothing to see.
func make(event: EventData) -> RoadsideThing:
	var tinted := event.tint.a > 0.0
	match event.kind:
		EventData.Kind.NONE:
			return null
		EventData.Kind.BIG_SHIP:
			var big := BigShipFlyby.new()
			big.names = event.ship_names
			big.speed_scale = event.speed_scale
			if tinted:
				big.hull_color = event.tint
			return big
		EventData.Kind.CONVOY:
			var convoy := Convoy.new()
			convoy.names = event.ship_names
			convoy.convoy_speed *= event.speed_scale
			if tinted:
				convoy.trail_tint = event.tint
			return convoy
		EventData.Kind.LONE_SHIP:
			var lone := PassingShip.new()
			lone.names = event.ship_names
			lone.drive_speed *= event.speed_scale
			lone.same_direction = event.same_direction
			lone.weaving = event.weaving
			if tinted:
				lone.trail = event.tint
			return lone
		EventData.Kind.WHALES:
			return WhalePod.new()
		EventData.Kind.JELLYFISH:
			return JellySwarm.new()
		EventData.Kind.COMET:
			return Comet.new()
		EventData.Kind.JUNK:
			return JunkCloud.new()
		EventData.Kind.ION_STORM:
			var storm := HazardZone.new()
			storm.kind = HazardZone.Kind.ION_STORM
			storm.radius = 1200.0
			if tinted:
				storm.tint = event.tint
			return storm
		EventData.Kind.SIGN:
			var board := RouteSign.new()
			var words := _any(event.texts).split("|") if not event.texts.is_empty() else PackedStringArray(["", ""])
			board.front_text = words[0]
			board.back_text = words[1] if words.size() > 1 else ""
			return board
		EventData.Kind.DERELICT, EventData.Kind.DUCK:
			var landmark := Landmark.new()
			landmark.kind = Landmark.Kind.DERELICT if event.kind == EventData.Kind.DERELICT else Landmark.Kind.DUCK
			if not event.texts.is_empty():
				landmark.label = _any(event.texts)
			return landmark
	var billboard := Billboard.new()
	if not event.texts.is_empty():
		var ad := _any(event.texts).split("|")
		billboard.headline = ad[0]
		billboard.tagline = ad[1] if ad.size() > 1 else ""
	return billboard


## Turns a sight see-through, ghostly and flickering. You fly right
## through it.
func _make_ghost(thing: RoadsideThing) -> void:
	var ghostly := StandardMaterial3D.new()
	ghostly.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghostly.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghostly.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ghostly.albedo_color = Color(0.45, 1.0, 0.9, 0.35)
	ghostly.cull_mode = BaseMaterial3D.CULL_DISABLED
	for part in thing.find_children("*", "GeometryInstance3D", true, false):
		(part as GeometryInstance3D).material_override = ghostly
	for body in thing.find_children("*", "CollisionObject3D", true, false):
		body.queue_free()  # You fly right through it.
	var flicker := Timer.new()
	flicker.wait_time = 0.15
	flicker.autostart = true
	flicker.timeout.connect(func() -> void: thing.visible = _rng.randf() > 0.12)
	thing.add_child(flicker)


# --- Effects --------------------------------------------------------------------------

func _start_effect(effect: EventData.Effect, seconds: float) -> void:
	_effect = effect
	_effect_left = maxf(seconds, 1.0)
	_effect_length = _effect_left
	_effect_clock = 0.0
	_effect_side = Vector3.RIGHT if _rng.randf() < 0.5 else Vector3.LEFT
	match effect:
		EventData.Effect.DEAD_AIR:
			Radio.dead_air(_effect_left)
		EventData.Effect.STATIC:
			Radio.interference(_effect_left)


## The effect going on right now (NONE = nothing).
func current_effect() -> EventData.Effect:
	return _effect


func _update_effect(delta: float) -> void:
	if _effect == EventData.Effect.NONE:
		return
	_effect_left -= delta
	if _effect_left <= 0.0:
		_effect = EventData.Effect.NONE
		return
	_effect_clock -= delta
	# Strongest in the middle, easing in and out.
	var envelope := sin(PI * clampf(1.0 - _effect_left / _effect_length, 0.0, 1.0))
	match _effect:
		EventData.Effect.PINGS:
			if _effect_clock <= 0.0:
				_effect_clock = _rng.randf_range(0.4, 1.3)
				_ship.knock(0.002, 0.0015, "pings")
		EventData.Effect.BUMPY:
			if _effect_clock <= 0.0:
				_effect_clock = _rng.randf_range(0.6, 1.5)
				_ship.knock(0.0, 0.003, "bumpy")
		EventData.Effect.NUDGE:
			# An invisible current: a sideways push (relative to the rig).
			var sideways := _ship.flight.orientation() * _effect_side
			_ship.flight.velocity += sideways * 5.0 * envelope * delta
		EventData.Effect.SWAY:
			_ship.flight.velocity.y += sin(_effect_length - _effect_left) * 4.0 * envelope * delta


# --- Bookkeeping ----------------------------------------------------------------------

func _remember(event: EventData) -> void:
	GameState.note_event(event.id)
	_recent_ids.append(event.id)
	while _recent_ids.size() > GameState.tuning.event_no_repeat:
		_recent_ids.pop_front()
	if event.kind != EventData.Kind.NONE:
		_recent_kinds.append(event.kind)
		while _recent_kinds.size() > GameState.tuning.event_no_repeat:
			_recent_kinds.pop_front()


## How many 3D sights are out there right now.
func active_count() -> int:
	return _active.size()


func _clean_up() -> void:
	var tuning := GameState.tuning
	var travel := _ship.flight.velocity.normalized()
	for thing: RoadsideThing in _active.duplicate():
		if not is_instance_valid(thing):
			_active.erase(thing)
			continue
		var offset: Vector3 = thing.global_position - _ship.global_position
		var far_behind: bool = offset.length() > tuning.event_despawn_distance and offset.dot(travel) < 0.0
		if thing.is_done() or far_behind or offset.length() > tuning.event_despawn_distance * 2.0:
			_active.erase(thing)
			thing.queue_free()


func _nearest_place(spot: Vector3) -> float:
	var nearest := INF
	for node: Node3D in _places.values():
		if is_instance_valid(node) and node.is_inside_tree():
			nearest = minf(nearest, node.global_position.distance_to(spot))
	return nearest


func _gap_range(zone: EventData.Zone) -> Vector2:
	var tuning := GameState.tuning
	match zone:
		EventData.Zone.TRAFFIC_LANES:
			return tuning.event_gap_traffic_lanes
		EventData.Zone.STATION_APPROACH:
			return tuning.event_gap_station_approach
		EventData.Zone.ORBIT:
			return tuning.event_gap_orbit
		EventData.Zone.WEATHER:
			return tuning.event_gap_weather
	return tuning.event_gap_deep_space


func _gap_for(zone: EventData.Zone) -> float:
	var gap := _gap_range(zone)
	return _rng.randf_range(gap.x, maxf(gap.y, gap.x))


func _any(words: PackedStringArray) -> String:
	return words[_rng.randi_range(0, words.size() - 1)]
