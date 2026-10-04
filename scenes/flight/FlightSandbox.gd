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


## The solar system we're in (its colors tint the space dust, the haze and
## the HUD's frames).
@export var system: SystemData
## The practice job riding along, so the HUD has cargo, pay and a rush timer
## to show. (The real job board arrives with M2.)
@export var practice_job: JobData
## Fly within this many meters of the docking bay to deliver the job.
@export var delivery_radius: float = 300.0
## Fly within this many meters of the truck stop and both fuel tanks top up.
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
@onready var _dock: Node3D = $World/Station/DockPoint
@onready var _chatter: CommChatter = $CommChatter
@onready var _nebula: MeshInstance3D = $World/SkyBackdrop/Nebula

var _start := Transform3D.IDENTITY
var _in_cockpit := false
var _haul: Haul


func _ready() -> void:
	_start = _ship.global_transform
	_dust.ship = _ship
	_dust.tint = system.signature_color
	_ship.cockpit.destination = _station
	_speed_lines.ship = _ship
	_haul = Haul.new(practice_job)
	_hud.setup(_ship, _dock, _haul, system.signature_color)
	_chatter.start(_ship, _hud.comm, _dock)
	_apply_system_colors()
	_pause_menu.resumed.connect(_capture_mouse)
	_pause_menu.back_to_start_pressed.connect(_back_to_start)
	_pause_menu.quit_to_title_pressed.connect(_quit_to_title)
	_pause_menu.dock_pressed.connect(_dock_at_base)
	_set_cockpit_view(false)
	_capture_mouse()


func _physics_process(delta: float) -> void:
	_haul.update(delta)
	if not _haul.delivered and _ship.global_position.distance_to(_dock.global_position) < delivery_radius:
		_haul.deliver(_ship.cargo_condition)
		_chatter.say(ChatterSet.Situation.DELIVERED)
	# The truck stop tops up both tanks and patches the hull while you're near.
	if _ship.global_position.distance_to(_station.global_position) < refuel_radius:
		var flight := _ship.flight
		flight.fuel = minf(flight.fuel + delta / refuel_seconds, 1.0)
		flight.boost_fuel = minf(flight.boost_fuel + delta / refuel_seconds, 1.0)
		_ship.repair(delta / repair_seconds)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera"):
		_set_cockpit_view(not _in_cockpit)
	elif event.is_action_pressed("radio_next"):
		Radio.next_station()
	elif event.is_action_pressed("radio_previous"):
		Radio.previous_station()
	elif event.is_action_pressed("toggle_hud"):
		Settings.set_show_hud(not Settings.show_hud)
	elif event.is_action_pressed("hud_demo"):
		_hud.demo = not _hud.demo
		if _hud.demo:
			_chatter.say(ChatterSet.Situation.IDLE)
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
	_ship.cargo_condition = 1.0
	_ship.odometer = 0.0
	# A fresh copy of the practice job, and dispatch calls again.
	_haul = Haul.new(practice_job)
	_hud.haul = _haul
	_chatter.restart()
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
