extends Node
## M1's flight sandbox: just you, the rig, a field of tumbling rocks and a
## truck stop glowing in the distance. Fly around and see how it feels.
##
## This script wires the pieces together and handles the camera switch
## (chase cam <-> cockpit), the mouse, and the pause menu's buttons.
##
## The whole 3D world lives inside PSXView (PSXView/Viewport/World), which
## draws it like a PS1 game. The HUD, cockpit frame and menus sit outside it
## so they stay crisp.


## The solar system we're in (its colors tint the space dust and the haze).
@export var system: SystemData
## Fly within this many meters of the truck stop and your boost fuel tops up.
## (A sandbox stand-in: buying fuel for credits arrives in M2.)
@export var refuel_radius: float = 900.0
## Seconds for a full boost-fuel top-up at the truck stop.
@export var refuel_seconds: float = 4.0

@onready var _view: PSXView = $PSXView
@onready var _ship: Ship = $PSXView/Viewport/World/Ship
@onready var _chase_camera: ChaseCamera = $PSXView/Viewport/World/ChaseCamera
@onready var _cockpit_camera: Camera3D = $PSXView/Viewport/World/Ship/CockpitCamera
@onready var _cockpit_view: CanvasLayer = $CockpitView
@onready var _cockpit_frame: CockpitFrame = $CockpitView/CockpitFrame
@onready var _speed_lines: SpeedLines = $SpeedLinesLayer/SpeedLines
@onready var _dust: SpaceDust = $PSXView/Viewport/World/SpaceDust
@onready var _environment: WorldEnvironment = $PSXView/Viewport/World/WorldEnvironment
@onready var _hud: FlightHUD = $FlightHUD
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _station: Node3D = $PSXView/Viewport/World/Station

var _start := Transform3D.IDENTITY
var _in_cockpit := false


func _ready() -> void:
	_start = _ship.global_transform
	_dust.ship = _ship
	_dust.tint = system.signature_color
	_cockpit_frame.ship = _ship
	_speed_lines.ship = _ship
	_hud.setup(_ship, _station, _view)
	_apply_haze()
	_pause_menu.resumed.connect(_capture_mouse)
	_pause_menu.back_to_start_pressed.connect(_back_to_start)
	_pause_menu.quit_to_title_pressed.connect(_quit_to_title)
	_set_cockpit_view(false)
	_capture_mouse()


func _physics_process(delta: float) -> void:
	var near_station := _ship.global_position.distance_to(_station.global_position) < refuel_radius
	var refueling := near_station and _ship.flight.boost_fuel < 1.0
	if refueling:
		_ship.flight.boost_fuel = minf(_ship.flight.boost_fuel + delta / refuel_seconds, 1.0)
	_hud.set_refueling(refueling)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_ship.controls.push_mouse_motion(event as InputEventMouseMotion)
	elif event.is_action_pressed("toggle_camera"):
		_set_cockpit_view(not _in_cockpit)
	elif event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse()  # Clicking back into the window grabs the mouse again.


func _set_cockpit_view(in_cockpit: bool) -> void:
	_in_cockpit = in_cockpit
	if in_cockpit:
		_cockpit_camera.make_current()
	else:
		_chase_camera.make_current()
	_cockpit_view.visible = in_cockpit
	_ship.set_model_visible(not in_cockpit)  # We're sitting inside it.
	_hud.set_cockpit_view(in_cockpit)


## The system's colored distance haze: faraway rocks and stations fade into
## its haze color, the classic PS1 fog. Deep space itself stays black.
func _apply_haze() -> void:
	var tuning := GameState.tuning
	var environment := _environment.environment
	environment.fog_enabled = tuning.haze_strength > 0.0
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = system.haze_color
	environment.fog_light_energy = 1.0
	environment.fog_density = tuning.haze_strength
	environment.fog_depth_begin = tuning.haze_start
	environment.fog_depth_end = tuning.haze_end
	environment.fog_sky_affect = 0.0


## Hides the mouse and locks it to the window, so moving it steers the ship.
func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _back_to_start() -> void:
	_ship.teleport(_start)
	_chase_camera.snap_behind_target()
	_capture_mouse()


func _quit_to_title() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/boot/Boot.tscn")
