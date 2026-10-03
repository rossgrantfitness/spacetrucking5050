class_name Cockpit
extends Node3D
## Brings the cab to life. Everything in here reacts to what you're doing:
## - the fuzzy steering wheel turns with your steering, the throttle lever
##   moves with your thrust, and the boost button lights up and sinks in;
## - the speed and hull needles move, and two little screens show the ship's
##   status and a nav radar with the truck stop and passing traffic;
## - the fuzzy dice, the air freshener and the alien bobblehead swing and
##   wobble when you speed up, slow down, turn or bonk into something;
## - the red alarm light flashes after a bonk and when the hull is battered.
##
## The cab's shapes live in CockpitInterior.tscn (built by
## tools/build_placeholder_models.gd). This script finds its moving parts by
## name, so a hand-made cockpit just needs parts with the same names.


const SCREEN_PIXELS := Vector2i(248, 128)
const LED_COLORS: Array[Color] = [Color(0.3, 1.0, 0.45), Color(1.0, 0.7, 0.2), Color(0.35, 0.9, 1.0), Color(1.0, 0.3, 0.3)]

## Where the nav screen points (the truck stop, for now). Set by the flight scene.
var destination: Node3D

var _ship: Ship
var _status_screen: CockpitScreen
var _nav_screen: CockpitScreen
var _leds: Array[MeshInstance3D] = []
var _rng := RandomNumberGenerator.new()
var _led_timer := 0.0
var _alarm_time := 0.0  # Seconds the alarm keeps flashing after a bonk.
var _time := 0.0
var _lever_angle := 0.0
# The dangly toys (dice, air freshener) share one swinging motion; the
# bobblehead has its own, springier one. x = sideways, y = front-to-back.
var _swing := Vector2.ZERO
var _swing_speed := Vector2.ZERO
var _bobble := Vector2.ZERO
var _bobble_speed := Vector2.ZERO
var _last_velocity := Vector3.ZERO
var _boost_material := _glow_material(Color(1.0, 0.45, 0.1))
var _alarm_material := _glow_material(Color(1.0, 0.15, 0.1))

@onready var _wheel: Node3D = $WheelColumn/Wheel
@onready var _column: Node3D = $WheelColumn
@onready var _lever: Node3D = $ThrottleLever
@onready var _boost_button: MeshInstance3D = $BoostButton
@onready var _speed_needle: Node3D = $Instruments/SpeedDial/Needle
@onready var _hull_needle: Node3D = $Instruments/HullDial/Needle
@onready var _alarm: MeshInstance3D = $AlarmLight
@onready var _dice: Node3D = $Dice
@onready var _freshener: Node3D = $Freshener
@onready var _bobble_head: Node3D = $Bobblehead/Head


func _ready() -> void:
	_ship = _find_ship()
	if _ship != null:
		_ship.bonked.connect(_on_bonked)
	_status_screen = _make_screen($Instruments/StatusScreen, CockpitScreen.Mode.STATUS)
	_nav_screen = _make_screen($Instruments/NavScreen, CockpitScreen.Mode.NAV)
	_boost_button.material_override = _boost_material
	_alarm.material_override = _alarm_material
	for child in get_children():
		if child.name.begins_with("Led"):
			var led := child as MeshInstance3D
			led.material_override = _glow_material(LED_COLORS[_rng.randi_range(0, LED_COLORS.size() - 1)])
			_leds.append(led)


func _process(delta: float) -> void:
	if _ship == null or not is_visible_in_tree():
		return
	_time += delta
	var steer := _ship.controls.current_steer()
	var flight := _ship.flight

	# The wheel turns with the steering and tips a little with nose up/down.
	_wheel.rotation.y = -steer.x * 1.7
	_column.rotation.x = 0.96 + steer.y * 0.12
	# The throttle lever eases toward the thrust you're giving.
	_lever_angle = lerpf(_lever_angle, -flight.thrust * 0.55, 1.0 - exp(-12.0 * delta))
	_lever.rotation.x = _lever_angle
	# The boost button sinks in and blazes while boosting, and glows softly
	# while there's boost fuel to burn.
	_boost_button.position.y = -0.485 if flight.boosting else -0.47
	var ready_glow := (0.3 + 0.2 * sin(_time * 3.0)) if flight.boost_fuel > 0.0 else 0.0
	_boost_material.emission_energy_multiplier = 2.0 if flight.boosting else ready_glow
	# Needles: speed up to full boost speed, hull from empty to full.
	var top := FlightModel.boosted_top_speed(_ship.ship_data)
	_speed_needle.rotation.y = lerpf(2.2, -2.2, clampf(flight.speed() / top, 0.0, 1.0))
	_hull_needle.rotation.y = lerpf(2.2, -2.2, _ship.hull)
	# The alarm flashes after a bonk, and keeps flashing on a battered hull.
	_alarm_time = maxf(_alarm_time - delta, 0.0)
	var alarming := _alarm_time > 0.0 or _ship.hull < 0.33
	_alarm_material.emission_energy_multiplier = (2.2 if fposmod(_time, 0.5) < 0.25 else 0.2) if alarming else 0.0
	_twinkle_leds(delta)
	_swing_toys(delta)
	_status_screen.queue_redraw()
	_nav_screen.queue_redraw()


## The ship we're sitting in (for the screens).
func ship() -> Ship:
	return _ship


func _on_bonked(strength: float, _where: Vector3) -> void:
	_alarm_time = 1.5
	# Knock the toys around, and make the screens flicker.
	var knock := Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)).normalized() * (2.0 + 6.0 * strength)
	_swing_speed += knock
	_bobble_speed += knock * 2.0
	_status_screen.flicker = 1.0
	_nav_screen.flicker = 1.0


## Swings the dice and air freshener like pendulums and wobbles the
## bobblehead on its spring. They lean against the way the cab speeds up or
## turns, like loose things do in a real truck.
func _swing_toys(delta: float) -> void:
	if delta <= 0.0:
		return
	var tuning := GameState.tuning
	var velocity := _ship.flight.velocity
	var acceleration := (velocity - _last_velocity) / delta
	_last_velocity = velocity
	var local := _ship.global_basis.inverse() * acceleration
	# Turning swings things outward too, even before the path catches up.
	var push := Vector2(-local.x - _ship.flight.turn_speed * 6.0, local.z) * 0.05 * tuning.cockpit_toy_swing
	push = push.limit_length(25.0)  # Boost is huge; don't fling them into orbit.
	_swing_speed += (push - _swing * 14.0 - _swing_speed * 1.1) * delta
	_swing = (_swing + _swing_speed * delta).clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))
	_bobble_speed += (push * 2.0 - _bobble * 70.0 - _bobble_speed * 3.0) * delta
	_bobble = (_bobble + _bobble_speed * delta).clamp(Vector2(-0.6, -0.6), Vector2(0.6, 0.6))
	for toy in [_dice, _freshener]:
		(toy as Node3D).rotation = Vector3(_swing.y, 0.0, _swing.x)
	_bobble_head.rotation = Vector3(_bobble.y, 0.0, _bobble.x)


## A few of the overhead lights change color now and then, just to look busy.
func _twinkle_leds(delta: float) -> void:
	_led_timer -= delta
	if _leds.is_empty() or _led_timer > 0.0:
		return
	_led_timer = _rng.randf_range(0.1, 0.35)
	var led := _leds[_rng.randi_range(0, _leds.size() - 1)]
	var material := led.material_override as StandardMaterial3D
	material.emission = LED_COLORS[_rng.randi_range(0, LED_COLORS.size() - 1)]
	material.emission_energy_multiplier = 0.0 if _rng.randf() < 0.25 else 1.6


## Gives one of the screen surfaces a little screen of its own to show.
func _make_screen(surface: MeshInstance3D, mode: CockpitScreen.Mode) -> CockpitScreen:
	var viewport := SubViewport.new()
	viewport.size = SCREEN_PIXELS
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen := CockpitScreen.new()
	screen.mode = mode
	screen.cockpit = self
	screen.size = Vector2(SCREEN_PIXELS)
	viewport.add_child(screen)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	surface.material_override = material
	return screen


func _glow_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color * 0.35
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.0
	return material


func _find_ship() -> Ship:
	var node := get_parent()
	while node != null and not node is Ship:
		node = node.get_parent()
	return node as Ship
