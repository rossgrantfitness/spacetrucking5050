class_name RouteEvents
extends Node
## The random sights of the long haul. Every few kilometers you drive, it
## picks something from res://data/events/route_events.tres (a big ship
## crossing, a convoy, a billboard, whales in Tidewater...) and puts it
## ahead of you, off to the side of the lane, so you pass it. Things that
## fall far behind are cleaned up.
##
## How often sights appear and how many at once are in tuning.tres under
## "Route events". Nothing appears near stations, at a crawl, or while the
## docking autopilot has you.


const EVENTS: RouteEventList = preload("res://data/events/route_events.tres")

var _ship: Ship
var _holder: Node3D
var _chatter: CommChatter
var _places: Dictionary = {}
var _current_system: Callable
var _active: Array[RoadsideThing] = []
var _travelled: float = 0.0
var _next_gap: float = 0.0
var _last_kind: int = -1
var _rng := RandomNumberGenerator.new()


## `holder` is where spawned things go; `current_system` returns the id of
## the solar system the rig is in.
func start(ship: Ship, holder: Node3D, chatter: CommChatter, places: Dictionary, current_system: Callable) -> void:
	_ship = ship
	_holder = holder
	_chatter = chatter
	_places = places
	_current_system = current_system
	_rng.randomize()
	_pick_next_gap()


func _physics_process(delta: float) -> void:
	if _ship == null:
		return
	_clean_up()
	var tuning := GameState.tuning
	var speed := _ship.flight.speed()
	if speed < tuning.event_min_speed or not _ship.autopilot_route.is_empty():
		return
	_travelled += speed * delta
	if _travelled < _next_gap or _active.size() >= tuning.event_max_active or _near_a_place():
		return
	spawn_something()
	_travelled = 0.0
	_pick_next_gap()


## Puts a random sight ahead of the rig. Returns it (or null). Public so the
## tests and the HUD demo can call it.
func spawn_something() -> RoadsideThing:
	var system_id: String = _current_system.call() if _current_system.is_valid() else "home"
	var options: Array[EventData] = []
	var total := 0.0
	for event in EVENTS.events:
		if event != null and event.allowed_in(system_id) and event.kind != _last_kind and event.weight > 0.0:
			options.append(event)
			total += event.weight
	if options.is_empty():
		return null
	var roll := _rng.randf() * total
	var picked := options[0]
	for event in options:
		roll -= event.weight
		if roll <= 0.0:
			picked = event
			break
	return spawn(picked)


## Puts one particular sight ahead of the rig.
func spawn(event: EventData) -> RoadsideThing:
	var travel := _ship.flight.velocity.normalized() if _ship.flight.speed() > 1.0 else _ship.flight.nose()
	var side := travel.cross(Vector3.UP).normalized()
	if side.is_zero_approx():
		side = Vector3.RIGHT
	var thing := make(event)
	thing.setup(_ship, travel, _rng.randi())
	var sideways := _rng.randf_range(event.side_offset.x, event.side_offset.y) * (1.0 if _rng.randf() < 0.5 else -1.0)
	var up := _rng.randf_range(event.height_offset.x, event.height_offset.y)
	thing.position = _ship.global_position + travel * event.ahead + side * sideways + Vector3.UP * up
	_holder.add_child(thing)
	_active.append(thing)
	_last_kind = event.kind
	if event.speaker != null and not event.lines.is_empty() and _chatter != null:
		_chatter.say_line(event.speaker, event.lines[_rng.randi_range(0, event.lines.size() - 1)])
	return thing


## Builds the thing for an event (not yet placed or added).
func make(event: EventData) -> RoadsideThing:
	match event.kind:
		EventData.Kind.BIG_SHIP:
			return BigShipFlyby.new()
		EventData.Kind.CONVOY:
			return Convoy.new()
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
			return storm
		EventData.Kind.DERELICT, EventData.Kind.DUCK:
			var landmark := Landmark.new()
			landmark.kind = Landmark.Kind.DERELICT if event.kind == EventData.Kind.DERELICT else Landmark.Kind.DUCK
			if not event.texts.is_empty():
				landmark.label = event.texts[_rng.randi_range(0, event.texts.size() - 1)]
			return landmark
	var billboard := Billboard.new()
	if not event.texts.is_empty():
		var ad := event.texts[_rng.randi_range(0, event.texts.size() - 1)].split("|")
		billboard.headline = ad[0]
		billboard.tagline = ad[1] if ad.size() > 1 else ""
	return billboard


## How many sights are out there right now.
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


func _near_a_place() -> bool:
	for node: Node3D in _places.values():
		if node.global_position.distance_to(_ship.global_position) < GameState.tuning.event_keep_clear:
			return true
	return false


func _pick_next_gap() -> void:
	var tuning := GameState.tuning
	_next_gap = _rng.randf_range(tuning.event_gap_min, maxf(tuning.event_gap_max, tuning.event_gap_min))
