extends Node
## M1's flight sandbox: just you, the rig, a field of tumbling rocks and a
## truck stop glowing in the distance. Fly around and see how it feels.
##
## This script wires the pieces together and handles the camera switch
## (chase cam <-> cockpit), the mouse, and the pause menu's buttons.
##
## The 3D world lives under "World". PSXScreen adds the PS1-style color and
## dither on top of it; the HUD, cockpit frame and menus are drawn after that,
## so they stay crisp.


## The solar system we're in (its colors tint the space dust and the haze).
@export var system: SystemData
## Fly within this many meters of the truck stop and your boost fuel tops up.
## (A sandbox stand-in: buying fuel for credits arrives in M2.)
@export var refuel_radius: float = 900.0
## Seconds for a full boost-fuel top-up at the truck stop.
@export var refuel_seconds: float = 4.0
## Seconds to patch a fully battered hull at the truck stop. (Also a sandbox
## stand-in: repairs at the hangar, for credits, come later.)
@export var repair_seconds: float = 8.0

@onready var _ship: Ship = $World/Ship
@onready var _chase_camera: ChaseCamera = $World/ChaseCamera
@onready var _cockpit_camera: Camera3D = $World/Ship/CockpitCamera
@onready var _speed_lines: SpeedLines = $SpeedLinesLayer/SpeedLines
@onready var _dust: SpaceDust = $World/SpaceDust
@onready var _environment: WorldEnvironment = $World/WorldEnvironment
@onready var _hud: FlightHUD = $FlightHUD
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _station: Node3D = $World/Station
@onready var _nebula: MeshInstance3D = $World/SkyBackdrop/Nebula

var _start := Transform3D.IDENTITY
var _in_cockpit := false


func _ready() -> void:
	_start = _ship.global_transform
	_dust.ship = _ship
	_dust.tint = system.signature_color
	_ship.cockpit.destination = _station
	_speed_lines.ship = _ship
	_hud.setup(_ship, _station)
	_apply_system_colors()
	_pause_menu.resumed.connect(_capture_mouse)
	_pause_menu.back_to_start_pressed.connect(_back_to_start)
	_pause_menu.quit_to_title_pressed.connect(_quit_to_title)
	_pause_menu.dock_pressed.connect(_dock_at_base)
	_set_cockpit_view(false)
	_capture_mouse()


func _physics_process(delta: float) -> void:
	var near_station := _ship.global_position.distance_to(_station.global_position) < refuel_radius
	var refueling := near_station and _ship.flight.boost_fuel < 1.0
	var repairing := near_station and _ship.hull < 1.0
	if refueling:
		_ship.flight.boost_fuel = minf(_ship.flight.boost_fuel + delta / refuel_seconds, 1.0)
	if repairing:
		_ship.repair(delta / repair_seconds)
	_hud.set_truck_stop_service(refueling, repairing)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera"):
		_set_cockpit_view(not _in_cockpit)
	elif event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse()  # Clicking back into the window grabs the mouse again.


func _set_cockpit_view(in_cockpit: bool) -> void:
	_in_cockpit = in_cockpit
	if in_cockpit:
		_cockpit_camera.make_current()
	else:
		_chase_camera.make_current()
	_ship.set_cockpit_view(in_cockpit)
	_hud.set_cockpit_view(in_cockpit)


## The system's colors: faraway rocks and stations fade into its haze color
## (the classic PS1 fog), and the nebula clouds in the sky are tinted with its
## signature color. Deep space itself stays black.
func _apply_system_colors() -> void:
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
	# The faint nebula clouds across the sky share the system's signature color.
	var nebula := _nebula.mesh.surface_get_material(0) as ShaderMaterial
	nebula.set_shader_parameter("tint", system.signature_color)


## Hides the mouse and locks it to the window, so moving it steers the ship.
func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _back_to_start() -> void:
	_ship.teleport(_start)
	_ship.repair(1.0)
	_chase_camera.snap_behind_target()
	_capture_mouse()


## Docks at the base: you climb out at the top of the dispatch stairs.
func _dock_at_base() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.next_spawn = "FromShip"
	get_tree().change_scene_to_file("res://scenes/hub/Dispatch.tscn")


func _quit_to_title() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/boot/Boot.tscn")
