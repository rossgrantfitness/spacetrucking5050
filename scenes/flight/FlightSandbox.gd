extends Node
## Flying around the home system: the base (where you live), an asteroid
## field, and the truck stop about 10 km out, with traffic in between.
##
## This script wires the pieces together:
## - LAUNCHING: the rig starts outside whichever place you boarded at
##   (GameState.launch_from), with its tanks, hull and cargo as you left them.
## - WHERE TO: the HUD points at your job's destination, or (with no job) at
##   the other place.
## - DOCKING: fly through a place's glowing approach ring and the autopilot
##   takes over and flies you into the bay. Then you climb out inside: a job
##   for that place gets delivered and paid, and the base's own pumps fill
##   you up for free.
## - The camera switch (chase cam <-> cockpit), the radio buttons, the HUD
##   buttons and the pause menu.
##
## Each place is a node under World/Places named after its id in
## res://data/places/ (like "truck_stop"), holding the station's model, a
## DockPoint, an ApproachRing and a LaunchPoint. Move them in the editor.
##
## The 3D world lives under "World". PSXScreen adds the PS1-style color and
## dither on top of it; the HUD and menus are drawn after that.


## The solar system we're in (its colors tint the space dust, the haze and
## the HUD's frames).
@export var system: SystemData
## How fast the docking autopilot flies, in m/s.
@export var docking_speed: float = 45.0

## Place id -> its node under World/Places.
var _places: Dictionary = {}
var _destination_id: String = ""
var _docking_at: String = ""
var _in_cockpit := false
var _fade: ScreenFade

@onready var _ship: Ship = $World/Ship
@onready var _chase_camera: ChaseCamera = $World/ChaseCamera
@onready var _cockpit_camera: Camera3D = $World/Ship/CockpitCamera
@onready var _speed_lines: SpeedLines = $SpeedLinesLayer/SpeedLines
@onready var _dust: SpaceDust = $World/SpaceDust
@onready var _environment: WorldEnvironment = $World/WorldEnvironment
@onready var _hud: FlightHUD = $FlightHUD
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _nebula: MeshInstance3D = $World/SkyBackdrop/Nebula
@onready var _chatter: CommChatter = $CommChatter


func _ready() -> void:
	_fade = ScreenFade.new()
	add_child(_fade)
	_fade.cover()
	# The rig, with every upgrade you've bought.
	_ship.ship_data = GameState.upgraded_ship(_ship.ship_data)
	for node in $World/Places.get_children():
		if GameState.places.find(node.name) != null:
			_places[node.name] = node
	_launch_from(GameState.launch_from)
	_restore_rig()
	_destination_id = _pick_destination()
	var dock := _dock_node(_destination_id)
	_dust.ship = _ship
	_dust.tint = system.signature_color
	_ship.cockpit.destination = dock
	_speed_lines.ship = _ship
	_hud.setup(_ship, dock, GameState.places.find(_destination_id).display_name, system.signature_color)
	_chatter.start(_ship, _hud.comm, _places)
	_ship.autopilot_arrived.connect(_on_autopilot_arrived)
	_apply_system_colors()
	_pause_menu.resumed.connect(_capture_mouse)
	_pause_menu.back_to_start_pressed.connect(_back_to_launch_point)
	_pause_menu.quit_to_title_pressed.connect(_quit_to_title)
	_pause_menu.dock_pressed.connect(func() -> void: _arrive("base"))
	_set_cockpit_view(false)
	_capture_mouse()
	Radio.set_context(Radio.Context.FLIGHT)
	_fade.fade_in()


func _physics_process(delta: float) -> void:
	if not GameState.active_job_id.is_empty() and _docking_at.is_empty():
		GameState.job_seconds += delta
	# Storms (M5) weaken the radio; flying fast swells the ambient music.
	Radio.signal_strength = 1.0 - _ship.storm * 0.8
	Radio.intensity = clampf(_ship.speed_ratio(), 0.0, 1.0)
	if _docking_at.is_empty():
		for id: String in _places:
			var ring := _ring(id)
			if ring != null and ring.is_inside(_ship.global_position) \
					and _ship.flight.velocity.dot(ring.through_direction()) > 1.0:
				_begin_docking(id)
				break


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera"):
		_set_cockpit_view(not _in_cockpit)
	elif event.is_action_pressed("radio_next"):
		Radio.next_station()
	elif event.is_action_pressed("radio_previous"):
		Radio.previous_station()
	elif event.is_action_pressed("radio_power"):
		Radio.toggle_power()
		_hud.show_banner("RADIO ON" if Radio.powered else "RADIO OFF", 1.5)
	elif event.is_action_pressed("toggle_hud"):
		Settings.set_show_hud(not Settings.show_hud)
	elif event.is_action_pressed("hud_demo"):
		_hud.demo = not _hud.demo
		if _hud.demo:
			_chatter.say(ChatterSet.Situation.IDLE)
	elif event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse()  # Clicking back into the window grabs the mouse again.


## Where the nav points: the job's destination, or the place you didn't
## launch from.
func _pick_destination() -> String:
	var job := GameState.active_job()
	if job != null and _places.has(job.to_place):
		return job.to_place
	for id: String in _places:
		if id != GameState.launch_from:
			return id
	return GameState.launch_from


## Puts the rig at a place's launch point, nose out, engines idle.
func _launch_from(id: String) -> void:
	var place: Node3D = _places.get(id, _places.get("base"))
	if place == null:
		return
	var launch := place.get_node("LaunchPoint") as Node3D
	_ship.teleport(launch.global_transform)
	_chase_camera.snap_behind_target()


## Puts the tanks, hull and cargo back the way they were when you docked.
func _restore_rig() -> void:
	var rig := GameState.rig
	_ship.flight.fuel = rig.get("fuel", 1.0)
	_ship.flight.boost_fuel = rig.get("boost_fuel", 1.0)
	_ship.hull = rig.get("hull", 1.0)
	_ship.cargo_condition = rig.get("cargo", 1.0)


func _remember_rig() -> void:
	GameState.rig = {"fuel": _ship.flight.fuel, "boost_fuel": _ship.flight.boost_fuel,
			"hull": _ship.hull, "cargo": _ship.cargo_condition}


func _begin_docking(id: String) -> void:
	_docking_at = id
	var ring := _ring(id)
	var dock := _dock_node(id)
	var route: Array[Vector3] = [ring.global_position + ring.through_direction() * 40.0, dock.global_position]
	_ship.fly_route(route, clampf(_ship.flight.speed(), 30.0, docking_speed))
	_hud.show_banner("AUTOPILOT DOCKING", 0.0)
	_chatter.say(ChatterSet.Situation.DOCKING, id)


func _on_autopilot_arrived() -> void:
	if not _docking_at.is_empty():
		_arrive(_docking_at)


## Climbs out at a place: delivers a job headed here, fills up at the base,
## and walks inside.
func _arrive(id: String) -> void:
	var place := GameState.places.find(id)
	if place == null:
		return
	_remember_rig()
	GameState.deliver_at(id)
	if place.free_fuel:
		GameState.rig["fuel"] = 1.0
		GameState.rig["boost_fuel"] = 1.0
	GameState.launch_from = id
	GameState.next_spawn = place.arrival_spawn
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _fade.fade_out()
	Radio.set_context(Radio.Context.OFF_AIR)
	get_tree().change_scene_to_file(place.interior_scene)


func _dock_node(id: String) -> Node3D:
	var place: Node3D = _places.get(id)
	return place.get_node("DockPoint") as Node3D if place != null else null


func _ring(id: String) -> ApproachRing:
	var place: Node3D = _places.get(id)
	return place.get_node_or_null("ApproachRing") as ApproachRing if place != null else null


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


## Pause menu: hop back to where you launched (tanks and cargo as they are).
func _back_to_launch_point() -> void:
	_remember_rig()
	_docking_at = ""
	_launch_from(GameState.launch_from)
	_restore_rig()
	_capture_mouse()


func _quit_to_title() -> void:
	_remember_rig()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Radio.set_context(Radio.Context.OFF_AIR)
	get_tree().change_scene_to_file("res://scenes/boot/Boot.tscn")
