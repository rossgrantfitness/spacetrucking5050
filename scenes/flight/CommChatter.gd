class_name CommChatter
extends Node
## Decides who calls you on the comms while you fly, and when. The lines
## live in res://data/dialogue/flight_chatter.tres; the HUD's comm portrait
## shows them.
##
## - Someone calls a few seconds after launch (who depends on the story).
## - Somebody makes small talk every minute or two when nothing's happening.
## - A place's traffic control calls as you get close, and again when the
##   docking autopilot takes over.
## - Bonks and boosts sometimes get a comment (only if the comms are free).
## - Rattling the cargo around (rough flying with a load) gets ONE comment
##   per trip. After that, nobody nags.
## - Low fuel and speeding tickets always get a call (they wait their turn).
## Every timing is in tuning.tres under "Comms chatter".


const CHATTER: FlightChatter = preload("res://data/dialogue/flight_chatter.tres")
## These always get said, even if they have to wait for the comms to free up.
const IMPORTANT := [ChatterSet.Situation.TAKEOFF, ChatterSet.Situation.APPROACH, ChatterSet.Situation.LOW_FUEL,
		ChatterSet.Situation.DOCKING, ChatterSet.Situation.SPEEDING]

## A place's traffic control calls when you're this close to it.
## (Far enough out that they call before you reach the rocks round it.)
@export var approach_call_distance: float = 4000.0

var _ship: Ship
var _comm: CommPortrait
## Place id -> its node in the flight scene.
var _places: Dictionary = {}
# Calls waiting their turn: [situation, place id].
var _waiting: Array[Array] = []
# Places whose approach call has happened (or, for the place you launched
# from, that you haven't flown far enough from yet).
var _approach_called: Dictionary = {}
var _quiet: float = 999.0  # Seconds since the last call ended.
var _idle_timer: float = 0.0
var _takeoff_timer: float = 0.0
var _boost_cooldown: float = 0.0
var _bonk_cooldown: float = 0.0
var _rough_said: bool = false
var _rough_time: float = 0.0  # Seconds the cargo has been rattling.
var _was_low_fuel: bool = false
var _was_boosting: bool = false
var _last_line: String = ""
var _rng := RandomNumberGenerator.new()


func start(ship: Ship, comm: CommPortrait, places: Dictionary) -> void:
	_ship = ship
	_comm = comm
	_places = places
	_rng.randomize()
	_ship.bonked.connect(_on_bonked)
	_comm.finished.connect(func() -> void: _quiet = 0.0)
	restart()


## A fresh trip: dispatch will call again after takeoff.
func restart() -> void:
	_waiting.clear()
	_takeoff_timer = GameState.tuning.comm_first_call_seconds
	_approach_called = {GameState.launch_from: true}
	_was_low_fuel = false
	_rough_said = false
	_reset_idle_timer()


## Something happened that someone might comment on (at `place`, a place
## id, if it's about a place).
func say(situation: ChatterSet.Situation, place: String = "") -> void:
	if situation in IMPORTANT:
		if not [situation, place] in _waiting:
			_waiting.append([situation, place])
	elif not _comm.is_busy() and _quiet >= GameState.tuning.comm_quiet_seconds:
		_play(situation, place)


func _process(delta: float) -> void:
	if _ship == null:
		return
	var tuning := GameState.tuning
	_quiet += delta
	_idle_timer -= delta
	_boost_cooldown -= delta
	_bonk_cooldown -= delta
	_watch_the_cargo(delta)
	if _takeoff_timer > 0.0:
		_takeoff_timer -= delta
		if _takeoff_timer <= 0.0:
			say(ChatterSet.Situation.TAKEOFF, GameState.launch_from)
	_watch_the_flight()
	if _comm.is_busy() or _quiet < tuning.comm_quiet_seconds:
		return
	if not _waiting.is_empty():
		var next: Array = _waiting.pop_front()
		_play(next[0], next[1])
	elif _idle_timer <= 0.0:
		_play(ChatterSet.Situation.IDLE)


## Notices low fuel, boosting and getting close to the destination.
func _watch_the_flight() -> void:
	var low := _ship.flight.fuel < GameState.tuning.low_fuel_warning
	if low and not _was_low_fuel:
		say(ChatterSet.Situation.LOW_FUEL)
	_was_low_fuel = low
	if _ship.flight.boosting and not _was_boosting and _boost_cooldown <= 0.0 and _rng.randf() < 0.5:
		_boost_cooldown = 45.0
		say(ChatterSet.Situation.BOOST)
	_was_boosting = _ship.flight.boosting
	for id: String in _places:
		var distance := _ship.global_position.distance_to((_places[id] as Node3D).global_position)
		if _approach_called.get(id, false):
			if id == GameState.launch_from and distance > approach_call_distance * 1.5:
				_approach_called[id] = false  # Far enough out: coming back counts.
			continue
		if distance < approach_call_distance:
			_approach_called[id] = true
			say(ChatterSet.Situation.APPROACH, id)


## Rough flying with a load in the back: someone notices.
func _watch_the_cargo(delta: float) -> void:
	if _ship.cargo_stress > 0.55 and not GameState.active_job_id.is_empty():
		_rough_time += delta
	else:
		_rough_time = 0.0
	# Said once per trip, then it's up to you: nobody nags.
	if _rough_time > 1.5 and not _rough_said:
		_rough_said = true
		say(ChatterSet.Situation.ROUGH)


func _on_bonked(_strength: float, _where: Vector3) -> void:
	if _bonk_cooldown > 0.0 or _rng.randf() > GameState.tuning.comm_bonk_chance:
		return
	_bonk_cooldown = 20.0
	say(ChatterSet.Situation.BONK)


## Someone comments on something (like a sight on the road), if the
## comms are free. Not important: skipped if somebody's already talking.
## `replies` are what Jacki can say back (empty = her usual one-liners).
## Returns whether the call went through.
func say_line(speaker: NPCData, line: String, replies: PackedStringArray = PackedStringArray()) -> bool:
	if _comm.is_busy() or _quiet < GameState.tuning.comm_quiet_seconds:
		return false
	_last_line = line
	_reset_idle_timer()
	_comm.call_in(speaker, line, ChatterSet.Situation.IDLE, true, replies)
	return true


## Picks a line for the situation (not the one just used) and calls in.
func _play(situation: ChatterSet.Situation, place: String = "") -> void:
	var options := CHATTER.lines_for(situation, place).filter(func(pair: Array) -> bool: return pair[1] != _last_line)
	_reset_idle_timer()
	if options.is_empty():
		return
	var pick: Array = options[_rng.randi_range(0, options.size() - 1)]
	_last_line = pick[1]
	_comm.call_in(pick[0], pick[1], situation)


func _reset_idle_timer() -> void:
	var tuning := GameState.tuning
	_idle_timer = _rng.randf_range(tuning.comm_idle_min_seconds, maxf(tuning.comm_idle_max_seconds, tuning.comm_idle_min_seconds))
