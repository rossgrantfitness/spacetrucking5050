class_name CommChatter
extends Node
## Decides who calls you on the comms while you fly, and when. The lines
## live in res://data/dialogue/flight_chatter.tres; the HUD's comm portrait
## shows them.
##
## - Dispatch calls a few seconds after takeoff.
## - Somebody makes small talk every minute or two when nothing's happening.
## - Truck stop control calls as you get close.
## - Bonks and boosts sometimes get a comment (only if the comms are free).
## - Low fuel and deliveries always get a call (they wait their turn).
## Every timing is in tuning.tres under "Comms chatter".


const CHATTER: FlightChatter = preload("res://data/dialogue/flight_chatter.tres")
## These always get said, even if they have to wait for the comms to free up.
const IMPORTANT := [ChatterSet.Situation.TAKEOFF, ChatterSet.Situation.APPROACH, ChatterSet.Situation.LOW_FUEL, ChatterSet.Situation.DELIVERED]

## Truck stop control calls when you're this close to the destination.
@export var approach_call_distance: float = 2500.0

var _ship: Ship
var _comm: CommPortrait
var _destination: Node3D
var _waiting: Array[ChatterSet.Situation] = []
var _quiet: float = 999.0  # Seconds since the last call ended.
var _idle_timer: float = 0.0
var _takeoff_timer: float = 0.0
var _boost_cooldown: float = 0.0
var _bonk_cooldown: float = 0.0
var _approach_called: bool = false
var _was_low_fuel: bool = false
var _was_boosting: bool = false
var _last_line: String = ""
var _rng := RandomNumberGenerator.new()


func start(ship: Ship, comm: CommPortrait, destination: Node3D) -> void:
	_ship = ship
	_comm = comm
	_destination = destination
	_rng.randomize()
	_ship.bonked.connect(_on_bonked)
	_comm.finished.connect(func() -> void: _quiet = 0.0)
	restart()


## A fresh trip: dispatch will call again after takeoff.
func restart() -> void:
	_waiting.clear()
	_takeoff_timer = GameState.tuning.comm_first_call_seconds
	_approach_called = false
	_was_low_fuel = false
	_reset_idle_timer()


## Something happened that someone might comment on.
func say(situation: ChatterSet.Situation) -> void:
	if situation in IMPORTANT:
		if not situation in _waiting:
			_waiting.append(situation)
	elif not _comm.is_busy() and _quiet >= GameState.tuning.comm_quiet_seconds:
		_play(situation)


func _process(delta: float) -> void:
	if _ship == null:
		return
	var tuning := GameState.tuning
	_quiet += delta
	_idle_timer -= delta
	_boost_cooldown -= delta
	_bonk_cooldown -= delta
	if _takeoff_timer > 0.0:
		_takeoff_timer -= delta
		if _takeoff_timer <= 0.0:
			say(ChatterSet.Situation.TAKEOFF)
	_watch_the_flight()
	if _comm.is_busy() or _quiet < tuning.comm_quiet_seconds:
		return
	if not _waiting.is_empty():
		_play(_waiting.pop_front())
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
	if _destination != null and not _approach_called \
			and _ship.global_position.distance_to(_destination.global_position) < approach_call_distance:
		_approach_called = true
		say(ChatterSet.Situation.APPROACH)


func _on_bonked(_strength: float, _where: Vector3) -> void:
	if _bonk_cooldown > 0.0 or _rng.randf() > GameState.tuning.comm_bonk_chance:
		return
	_bonk_cooldown = 20.0
	say(ChatterSet.Situation.BONK)


## Picks a line for the situation (not the one just used) and calls in.
func _play(situation: ChatterSet.Situation) -> void:
	var options := CHATTER.lines_for(situation).filter(func(pair: Array) -> bool: return pair[1] != _last_line)
	_reset_idle_timer()
	if options.is_empty():
		return
	var pick: Array = options[_rng.randi_range(0, options.size() - 1)]
	_last_line = pick[1]
	_comm.call_in(pick[0], pick[1])


func _reset_idle_timer() -> void:
	var tuning := GameState.tuning
	_idle_timer = _rng.randf_range(tuning.comm_idle_min_seconds, maxf(tuning.comm_idle_max_seconds, tuning.comm_idle_min_seconds))
