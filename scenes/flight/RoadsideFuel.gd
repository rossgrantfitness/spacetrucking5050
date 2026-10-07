class_name RoadsideFuel
extends Node
## Gas-N-Go roadside: run the tank dry and the engines die (see
## empty_tank_thrust in tuning.tres), so you drift. A few seconds later
## someone calls to say a tanker's coming; it takes a while to reach you,
## then puts in a little fuel and bills you, a call-out fee plus the fuel at
## a steep markup. Can't afford it? The rest goes on the tab.
##
## Never stranded, but it costs time and money: that's why you watch the
## gauge. All the numbers are under "ROADSIDE FUEL" in tuning.tres.

## Says something on screen for a moment (FlightHUD.show_banner).
signal banner_requested(text: String, seconds: float)

## Whether the tanker can come right now (not mid-docking, not in a wreck).
var allowed: Callable = func() -> bool: return true

var _ship: Ship
var _chatter: CommChatter
## How long the tank's been dry, and how long until the tanker arrives
## (below 0 = nobody's been called yet).
var _dry_time := 0.0
var _tanker_eta := -1.0


func start(ship: Ship, chatter: CommChatter) -> void:
	_ship = ship
	_chatter = chatter


## Whether a tanker's on its way right now.
func tanker_coming() -> bool:
	return _tanker_eta >= 0.0


## Seconds until the tanker gets here (0 if none is coming).
func seconds_to_tanker() -> float:
	return maxf(_tanker_eta, 0.0)


## What the tanker charges: the call-out fee plus its fuel at the markup.
static func price(tuning: Tuning) -> int:
	return tuning.roadside_callout_fee + ceili(tuning.roadside_fuel * tuning.fuel_tank_price * tuning.roadside_price_factor)


func _physics_process(delta: float) -> void:
	if _ship == null:
		return
	var tuning := GameState.tuning
	if _ship.flight.fuel > 0.0 or not allowed.call():
		_dry_time = 0.0
		return
	_dry_time += delta
	if _tanker_eta < 0.0:
		if _dry_time >= tuning.roadside_call_seconds:
			_call_the_tanker(tuning)
		return
	_tanker_eta -= delta
	if _tanker_eta <= 0.0:
		_fill_up(tuning)


func _call_the_tanker(tuning: Tuning) -> void:
	_tanker_eta = tuning.roadside_wait_seconds
	Sfx.play("autopilot_off", -2.0, 0.7)  # The engines cough and die.
	banner_requested.emit("OUT OF FUEL - GAS-N-GO TANKER ON THE WAY", 4.0)
	if _chatter != null:
		_chatter.say(ChatterSet.Situation.OUT_OF_FUEL)


func _fill_up(tuning: Tuning) -> void:
	_tanker_eta = -1.0
	_dry_time = 0.0
	var bill := price(tuning)
	var paid := mini(bill, GameState.credits)
	if paid > 0:
		GameState.spend(paid)
	GameState.tab += bill - paid
	if bill > paid:
		GameState.set_flag("ran_a_tab")
	_ship.flight.fuel = minf(_ship.flight.fuel + tuning.roadside_fuel, 1.0)
	# On the PC's invoice list (as money going out).
	GameState.invoices.append({"cargo": "ROADSIDE FUEL", "client": "Gas-N-Go", "to": "", "total": -bill, "day": GameState.day})
	if GameState.invoices.size() > GameState.INVOICE_LIMIT:
		GameState.invoices.remove_at(0)
	GameState.set_flag("roadside_tanker")
	Sfx.play("clunk")
	var currency := GameState.names.currency_short
	var note := "-%d %s" % [bill, currency] if paid == bill else "%d %s ON THE TAB" % [bill - paid, currency]
	banner_requested.emit("TANKER: +%d%% FUEL  %s" % [roundi(tuning.roadside_fuel * 100.0), note], 4.0)
	if _chatter != null:
		_chatter.say(ChatterSet.Situation.TANKER)
