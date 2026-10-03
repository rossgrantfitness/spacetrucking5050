extends Node3D
## M1's flight sandbox: just you, the rig, a field of tumbling rocks and a
## truck stop glowing in the distance. Fly around and see how it feels.
##
## This script wires the pieces together and handles the camera switch
## (chase cam <-> cockpit), the mouse, and the pause menu's buttons.


## The solar system we're in (its color tints the space dust).
@export var system: SystemData

@onready var _ship: Ship = $Ship
@onready var _chase_camera: ChaseCamera = $ChaseCamera
@onready var _cockpit_camera: Camera3D = $Ship/CockpitCamera
@onready var _cockpit_view: CanvasLayer = $CockpitView
@onready var _cockpit_frame: CockpitFrame = $CockpitView/CockpitFrame
@onready var _speed_lines: SpeedLines = $SpeedLinesLayer/SpeedLines
@onready var _dust: SpaceDust = $SpaceDust
@onready var _hud: FlightHUD = $FlightHUD
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _station: Node3D = $Station

var _start := Transform3D.IDENTITY
var _in_cockpit := false


func _ready() -> void:
	_start = _ship.global_transform
	_dust.ship = _ship
	_dust.tint = system.signature_color
	_cockpit_frame.ship = _ship
	_speed_lines.ship = _ship
	_hud.setup(_ship, _station)
	_pause_menu.resumed.connect(_capture_mouse)
	_pause_menu.back_to_start_pressed.connect(_back_to_start)
	_pause_menu.quit_to_title_pressed.connect(_quit_to_title)
	_set_cockpit_view(false)
	_capture_mouse()


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
	_cockpit_view.visible = in_cockpit
	_ship.set_model_visible(not in_cockpit)  # We're sitting inside it.
	_hud.set_cockpit_view(in_cockpit)


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
