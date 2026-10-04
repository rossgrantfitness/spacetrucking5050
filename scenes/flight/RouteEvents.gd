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
## The kinds of the last few sights (so nothing repeats too soon).
var _recent_kinds: Array[int] = []
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
	# Once in a long while: something rare.
	if _rng.randf() < GameState.tuning.event_rare_chance:
		var rares: Array[EventData] = []
		for event in EVENTS.events:
			if event != null and event.rare and event.allowed_in(system_id):
				rares.append(event)
		if not rares.is_empty():
			return spawn(rares[_rng.randi_range(0, rares.size() - 1)])
	var options: Array[EventData] = []
	var total := 0.0
	for event in EVENTS.events:
		if event != null and not event.rare and event.allowed_in(system_id) and not event.kind in _recent_kinds and event.weight > 0.0:
			options.append(event)
			total += event.weight
	if options.is_empty():
		_recent_kinds.clear()
		return null
	var roll := _rng.randf() * total
	var picked := options[0]
	for event in options:
		roll -= event.weight
		if roll <= 0.0:
			picked = event
			break
	return spawn(picked)


## Puts one particular sight ahead of the rig (several, for events with
## copies).
func spawn(event: EventData) -> RoadsideThing:
	var travel := _ship.flight.velocity.normalized() if _ship.flight.speed() > 1.0 else _ship.flight.nose()
	var side := travel.cross(Vector3.UP).normalized()
	if side.is_zero_approx():
		side = Vector3.RIGHT
	var thing: RoadsideThing
	for copy in event.copies:
		thing = make(event)
		thing.setup(_ship, travel, _rng.randi())
		thing.log_id = event.log_id
		var sideways := _rng.randf_range(event.side_offset.x, event.side_offset.y) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var up := _rng.randf_range(event.height_offset.x, event.height_offset.y)
		var further := copy * _rng.randf_range(300.0, 900.0)
		thing.position = _ship.global_position + travel * (event.ahead + further) + side * sideways + Vector3.UP * up
		thing.scale = Vector3.ONE * event.size
		_holder.add_child(thing)
		thing.contact_radius *= event.size
		if event.ghost:
			_make_ghost(thing)
		_active.append(thing)
	_recent_kinds.append(event.kind)
	while _recent_kinds.size() > GameState.tuning.event_no_repeat:
		_recent_kinds.pop_front()
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
