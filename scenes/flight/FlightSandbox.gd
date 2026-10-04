extends Node
## Flying through space: the home system (the base, an asteroid field, the
## truck stop about 10 km out) and the long road out to the teal Tidewater
## system, about 60 km past the truck stop, with the Gas-N-Go about halfway.
##
## This script wires the pieces together:
## - LAUNCHING: the rig starts outside whichever place you boarded at
##   (GameState.launch_from), with its tanks, hull and cargo as you left them.
## - WHERE TO: the HUD points at your job's destination, or (with no job) at
##   the next place.
## - SOLAR SYSTEMS: each system's colors (space dust, haze, nebula, sunlight,
##   HUD frames) blend smoothly into the next as you fly between them, and a
##   banner says when you've crossed over.
## - DOCKING: fly through a place's glowing approach ring and the autopilot
##   takes over and flies you into the bay. What happens next depends on
##   the place's kind (see res://data/places/PlaceData.gd):
##     INTERIOR      - you climb out and walk around inside
##     DROP_OFF      - you stay in the cab: get paid, maybe take a load back,
##                     fill up, then launch again
##     DRIVE_THROUGH - you pull up under the canopy, use the counter, and the
##                     autopilot rolls you out the far side, still moving
## - THE COURSE CHART (M / Back): pick a destination and the cruise
##   autopilot drives (CruisePilot.gd). Grab the controls to take over.
## - HAZARDS: ion storms and speed traps (scenes/flight/events/HazardZone.gd)
##   tell the ship how strongly they're affecting it.
## - ROUTE EVENTS: random sights along the road (RouteEvents.gd).
## - The camera switch (chase cam <-> cockpit), the radio buttons, the HUD
##   buttons and the pause menu.
##
## Each place is a node under World/Places named after its id in
## res://data/places/ (like "truck_stop"), holding the station's model, a
## DockPoint, one or more approach rings and a LaunchPoint. Move them in the
## editor. Planets and suns are SkyBody nodes under World/SkyBodies; fixed
## sights along the road are under World/Roadside.
##
## The 3D world lives under "World". PSXScreen adds the PS1-style color and
## dither on top of it; the HUD and menus are drawn after that.


## The solar systems in this world. Their colors blend by how close you
## are to each one's center.
@export var systems: Array[SystemData] = []
## How fast the docking autopilot flies, in m/s.
@export var docking_speed: float = 45.0

## Place id -> its node under World/Places.
var _places: Dictionary = {}
var _destination_id: String = ""
var _docking_at: String = ""
## Rolling out of a drive-through (the autopilot still has the wheel).
var _leaving: bool = false
## Busy at a counter (menus up, rig parked).
var _at_counter: bool = false
## The charted course: the places still to visit, in order.
var _course := PackedStringArray()
var _in_cockpit := false
var _fade: ScreenFade
var _current_system: String = ""
var _route_events: RouteEvents
var _rng := RandomNumberGenerator.new()

@onready var _ship: Ship = $World/Ship
@onready var _chase_camera: ChaseCamera = $World/ChaseCamera
@onready var _cockpit_camera: Camera3D = $World/Ship/CockpitCamera
@onready var _speed_lines: SpeedLines = $SpeedLinesLayer/SpeedLines
@onready var _dust: SpaceDust = $World/SpaceDust
@onready var _environment: WorldEnvironment = $World/WorldEnvironment
@onready var _sun: DirectionalLight3D = $World/Sun
@onready var _hud: FlightHUD = $FlightHUD
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _nebula: MeshInstance3D = $World/SkyBackdrop/Nebula
@onready var _chatter: CommChatter = $CommChatter
@onready var _events_holder: Node3D = $World/Events


func _ready() -> void:
	_rng.randomize()
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
	_dust.ship = _ship
	_speed_lines.ship = _ship
	_hud.setup(_ship, null, "", Color.WHITE)
	_set_destination(_pick_destination())
	_chatter.start(_ship, _hud.comm, _places)
	_ship.autopilot_arrived.connect(_on_autopilot_arrived)
	_ship.cruise_released.connect(_on_cruise_released)
	_route_events = RouteEvents.new()
	add_child(_route_events)
	_route_events.start(_ship, _events_holder, _chatter, _places, current_system)
	_setup_haze()
	_blend_systems(true)
	_pause_menu.resumed.connect(_capture_mouse)
	_pause_menu.back_to_start_pressed.connect(_back_to_launch_point)
	_pause_menu.quit_to_title_pressed.connect(_quit_to_title)
	_pause_menu.dock_pressed.connect(func() -> void: _arrive("base"))
	_set_cockpit_view(false)
	_capture_mouse()
	Radio.set_context(Radio.Context.FLIGHT)
	_fade.fade_in()


func _process(_delta: float) -> void:
	_blend_systems(false)


func _physics_process(delta: float) -> void:
	if not GameState.active_job_id.is_empty() and _docking_at.is_empty():
		GameState.job_seconds += delta
	_feel_the_hazards(delta)
	# Storms weaken the radio; flying fast swells the ambient music.
	Radio.signal_strength = 1.0 - _ship.storm * 0.8
	Radio.intensity = clampf(_ship.speed_ratio(), 0.0, 1.0)
	if _ship.cruise != null and _ship.cruise.is_done() and _docking_at.is_empty():
		_ship.cruise = null  # Got there without docking (it's the pilot's turn).
		_hud.show_banner("AUTOPILOT OFF", 2.0)
	if _docking_at.is_empty():
		for id: String in _places:
			for ring in _rings(id):
				if ring.is_inside(_ship.global_position) and _ship.flight.velocity.dot(ring.through_direction()) > 1.0:
					_begin_docking(id, ring)
					return


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera"):
		_set_cockpit_view(not _in_cockpit)
	elif event.is_action_pressed("chart_course"):
		if _docking_at.is_empty():
			_open_course_chart()
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
			_route_events.spawn_something()
	elif event is InputEventMouseButton and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse()  # Clicking back into the window grabs the mouse again.


# --- Where to -----------------------------------------------------------------------

## Where the nav points: the job's destination, or the place you didn't
## launch from.
func _pick_destination() -> String:
	var job := GameState.active_job()
	if job != null and _places.has(job.to_place):
		return job.to_place
	for id: String in _places:
		if id != GameState.launch_from and GameState.places.find(id).kind != PlaceData.Kind.DRIVE_THROUGH:
			return id
	return GameState.launch_from


## Points the HUD and the cockpit's NAV screen at a place.
func _set_destination(id: String) -> void:
	_destination_id = id
	var dock := _dock_node(id)
	var place := GameState.places.find(id)
	var place_name := place.display_name if place != null else ""
	_hud.destination = dock
	_hud.destination_name = place_name
	_ship.cockpit.destination = dock
	_ship.cockpit.destination_name = place_name


# --- The course chart and the cruise autopilot --------------------------------------

func _open_course_chart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var job := GameState.active_job()
	var pick := await CourseChart.open(get_tree(), _ship, _places, approach_points,
			job.to_place if job != null else "", _ship.cruise != null)
	match pick["action"]:
		"go":
			engage_course(pick["stops"])
		"off":
			_course.clear()
			_ship.cruise = null
			_hud.show_banner("AUTOPILOT OFF", 2.0)
	_capture_mouse()


## Hands the wheel to the cruise autopilot, to visit `stops` (place ids) in
## order. Public so the tests can use it.
func engage_course(stops: PackedStringArray) -> void:
	_course = stops.duplicate()
	_aim_cruise()
	if _ship.cruise != null:
		_hud.show_banner("AUTOPILOT > " + GameState.places.find(_course[_course.size() - 1]).display_name, 3.0)


## Sets the cruise autopilot on its way to the next stop on the course.
func _aim_cruise() -> void:
	if _course.is_empty():
		_ship.cruise = null
		return
	var pilot := CruisePilot.new()
	pilot.waypoints = approach_points(_course[0], _ship.global_position)
	_ship.cruise = pilot
	_set_destination(_course[0])


## The spots to fly through to dock at place `id`, coming from `from`: a
## spot lined up outside the handiest approach ring, then through the ring
## (which starts the docking autopilot).
func approach_points(id: String, from: Vector3) -> Array[Vector3]:
	var best: ApproachRing = null
	var best_distance := INF
	for ring in _rings(id):
		var line_up := ring.global_position - ring.through_direction() * 700.0
		if from.distance_to(line_up) < best_distance:
			best_distance = from.distance_to(line_up)
			best = ring
	if best == null:
		var dock := _dock_node(id)
		return [dock.global_position] if dock != null else []
	return [best.global_position - best.through_direction() * 700.0, best.global_position + best.through_direction() * 150.0]


func _on_cruise_released() -> void:
	_course.clear()
	_hud.show_banner("MANUAL CONTROL", 2.0)


# --- Launching ----------------------------------------------------------------------

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


# --- Docking ------------------------------------------------------------------------

func _begin_docking(id: String, ring: ApproachRing) -> void:
	_docking_at = id
	if not _course.is_empty() and _course[0] == id:
		_course.remove_at(0)
	var dock := _dock_node(id)
	var route: Array[Vector3] = [ring.global_position + ring.through_direction() * 40.0, dock.global_position]
	_ship.fly_route(route, clampf(_ship.flight.speed(), 30.0, docking_speed))
	_ship.set_meta("docking_ring", ring.global_position)
	var place := GameState.places.find(id)
	_hud.show_banner("PULLING IN" if place.kind == PlaceData.Kind.DRIVE_THROUGH else "AUTOPILOT DOCKING", 0.0)
	_chatter.say(ChatterSet.Situation.DOCKING, id)


func _on_autopilot_arrived() -> void:
	if _leaving:
		_leaving = false
		_docking_at = ""
		_hud.show_banner("DRIVE SAFE", 2.0)
		_aim_cruise()
		if _ship.cruise == null:
			_set_destination(_pick_destination())
	elif not _docking_at.is_empty():
		_arrive(_docking_at)


## Docked at a place. What happens depends on its kind.
func _arrive(id: String) -> void:
	var place := GameState.places.find(id)
	if place == null:
		return
	match place.kind:
		PlaceData.Kind.DROP_OFF:
			await _drop_off(id, place)
		PlaceData.Kind.DRIVE_THROUGH:
			await _drive_through(id, place)
		_:
			await _climb_out(id, place)


## INTERIOR places: delivers a job headed here, fills up at the base, and
## walks inside.
func _climb_out(id: String, place: PlaceData) -> void:
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


## DROP_OFF places: you stay in the cab. The crane takes the load, you get
## paid, maybe take a load back and fill up, then launch again.
func _drop_off(id: String, place: PlaceData) -> void:
	var delivered := _deliver_here(id)
	await _greet(place, "DOCKED: " + place.display_name)
	await _counter(id, place, delivered)
	GameState.launch_from = id
	GameState.save_game()
	await _fade.fade_out()
	_ship.process_mode = Node.PROCESS_MODE_INHERIT
	_launch_from(id)
	_restore_rig()
	_docking_at = ""
	_chatter.restart()
	_course.clear()
	_ship.cruise = null
	_set_destination(_pick_destination())
	_hud.show_banner("", 0.1)
	_at_counter = false
	_capture_mouse()
	await _fade.fade_in()


## DRIVE_THROUGH places: pull up under the canopy, use the counter, then
## the autopilot rolls you out the far side and you carry on.
func _drive_through(id: String, place: PlaceData) -> void:
	_remember_rig()
	await _greet(place, place.display_name)
	await _counter(id, place, false)
	GameState.save_game()
	_ship.process_mode = Node.PROCESS_MODE_INHERIT
	_restore_rig()
	_at_counter = false
	_capture_mouse()
	# Out the far side: straight on from the ring we came in through.
	var dock := _dock_node(id).global_position
	var came_in: Vector3 = _ship.get_meta("docking_ring", dock + Vector3.BACK)
	var exit := dock + (dock - came_in).normalized() * 650.0
	var route: Array[Vector3] = [exit]
	_leaving = true
	_hud.show_banner("ROLLING OUT", 0.0)
	_ship.fly_route(route, 40.0, false)


## Delivers a load headed here, keeping the rig's numbers in sync.
func _deliver_here(id: String) -> bool:
	_remember_rig()
	return GameState.deliver_at(id)


## Parks the rig, says hello on the comms, and waits a moment.
func _greet(place: PlaceData, banner: String) -> void:
	_at_counter = true
	_ship.process_mode = Node.PROCESS_MODE_DISABLED  # Parked: hands off.
	_hud.show_banner(banner, 0.0)
	if place.host != null and not place.host_lines.is_empty():
		_hud.comm.call_in(place.host, place.host_lines[_rng.randi_range(0, place.host_lines.size() - 1)])
	await get_tree().create_timer(2.5).timeout


## The counter menu at a drop-off or drive-through: the payout card, then
## loads, fuel, and on your way.
func _counter(id: String, place: PlaceData, delivered: bool) -> void:
	var tree := get_tree()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	tree.paused = true
	if delivered:
		await HubServices.show_payout(tree)
	var pumps := place.display_name + " PUMPS"
	while true:
		var options: Array = []
		var actions: Array[String] = []
		if place.kind == PlaceData.Kind.DROP_OFF:
			options.append({"text": "LOOK FOR A LOAD", "description": "See what needs hauling from here."})
			actions.append("job_board")
		if "fuel" in place.services:
			options.append({"text": "FUEL UP", "description": "Main tank %d%%, boost %d%%." % [
					roundi(GameState.rig["fuel"] * 100.0), roundi(GameState.rig["boost_fuel"] * 100.0)]})
			actions.append("fuel")
		var leave := "LAUNCH" if place.kind == PlaceData.Kind.DROP_OFF else "ROLL ON OUT"
		options.append({"text": leave, "description": "Back on the road."})
		actions.append("leave")
		var choice := await MenuPanel.ask(tree, place.display_name, "You're parked. You've got %d %s." % [GameState.credits, GameState.names.currency_short], options)
		var action := actions[choice] if choice >= 0 else "leave"
		if action == "job_board":
			await HubServices.job_board(tree, id)
		elif action == "fuel":
			await HubServices.fuel(tree, pumps, "Come back... whenever.")
		else:
			break
	tree.paused = false


# --- Solar systems ------------------------------------------------------------------

## The id of the solar system the rig is in (the nearest one).
func current_system() -> String:
	var weights := system_weights(_ship.global_position)
	var best := 0
	for i in weights.size():
		if weights[i] > weights[best]:
			best = i
	return systems[best].id if not systems.is_empty() else ""


## How much each system's colors count at `spot` (adds up to 1). Close to
## a system's center it's all that system; halfway between two, half each.
func system_weights(spot: Vector3) -> PackedFloat32Array:
	var weights := PackedFloat32Array()
	var total := 0.0
	for system in systems:
		var weight := 1.0 / pow(maxf(spot.distance_to(system.center), 100.0) / 1000.0, 4.0)
		weights.append(weight)
		total += weight
	for i in weights.size():
		weights[i] /= total
	return weights


## Mixes the systems' colors by where the rig is, and aims the sunlight
## from the blend of the suns. On crossing into a new system, a banner.
func _blend_systems(first: bool) -> void:
	if systems.is_empty():
		return
	var weights := system_weights(_ship.global_position)
	var signature := Color(0, 0, 0)
	var haze := Color(0, 0, 0)
	var sun_color := Color(0, 0, 0)
	var ambient := Color(0, 0, 0)
	var sun_energy := 0.0
	var nebula_strength := 0.0
	var light_from := Vector3.ZERO
	var eye := _ship.global_position
	for i in systems.size():
		var system := systems[i]
		var weight := weights[i]
		signature += system.signature_color * weight
		haze += system.haze_color * weight
		sun_color += system.sun_color * weight
		ambient += system.ambient_color * weight
		sun_energy += system.sun_energy * weight
		nebula_strength += system.nebula_strength * weight
		for body: SkyBody in get_tree().get_nodes_in_group("sky_bodies"):
			if body.is_sun and body.system_id == system.id:
				light_from += body.direction_from(eye) * weight
	_dust.tint = signature
	_hud.tint = signature
	var environment := _environment.environment
	environment.fog_light_color = haze
	environment.ambient_light_color = ambient
	_sun.light_color = sun_color
	_sun.light_energy = sun_energy
	if not light_from.is_zero_approx():
		# A sun light shines along its -Z: from the sun toward us.
		var shine := -light_from.normalized()
		var up := Vector3.UP if absf(shine.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
		_sun.global_basis = Basis.looking_at(shine, up)
	var nebula := _nebula.mesh.surface_get_material(0) as ShaderMaterial
	nebula.set_shader_parameter("tint", signature)
	nebula.set_shader_parameter("strength", nebula_strength)
	var now := current_system()
	if now != _current_system:
		if not first:
			for system in systems:
				if system.id == now:
					_hud.show_banner("NOW ENTERING " + system.display_name.to_upper(), 4.0)
		_current_system = now


## The distance haze: faraway rocks and stations fade into the system's haze
## color (the classic PS1 fog). Deep space itself stays black.
func _setup_haze() -> void:
	var tuning := GameState.tuning
	var environment := _environment.environment
	environment.fog_enabled = tuning.haze_strength > 0.0
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_energy = 1.0
	environment.fog_density = tuning.haze_strength
	environment.fog_depth_begin = tuning.haze_start
	environment.fog_depth_end = tuning.haze_end
	environment.fog_sky_affect = 0.0


# --- Hazards ------------------------------------------------------------------------

## Asks every hazard zone how much it's affecting the rig (the HUD's STORM
## and COPS lights read the result). Storms give the odd jolt.
func _feel_the_hazards(delta: float) -> void:
	var storm := 0.0
	var trap := 0.0
	for zone: HazardZone in get_tree().get_nodes_in_group("hazard_zones"):
		if not zone.has_meta("watched"):
			zone.set_meta("watched", true)
			zone.caught_speeding.connect(_on_caught_speeding.bind(zone))
		var effect := zone.influence(_ship)
		storm = maxf(storm, effect.get("storm", 0.0))
		trap = maxf(trap, effect.get("speed_trap", 0.0))
	_ship.storm = storm
	_ship.speed_trap = trap
	if storm > 0.3 and _rng.randf() < delta * storm * 0.6:
		_ship.shake.add_trauma(0.12 + 0.1 * storm)


## A speed trap clocked you: a small fine and a word from the deputy.
func _on_caught_speeding(kmh: int, zone: HazardZone) -> void:
	var fine := mini(zone.fine, GameState.credits)
	GameState.spend(fine)
	_hud.show_banner("SPEEDING TICKET  %d KM/H  -%d %s" % [kmh, fine, GameState.names.currency_short], 4.0)
	_chatter.say(ChatterSet.Situation.SPEEDING)


# --- Bits and bobs ------------------------------------------------------------------

func _dock_node(id: String) -> Node3D:
	var place: Node3D = _places.get(id)
	return place.get_node("DockPoint") as Node3D if place != null else null


## A place's approach rings (most have one; drive-throughs have one at each
## end).
func _rings(id: String) -> Array[ApproachRing]:
	var found: Array[ApproachRing] = []
	var place: Node3D = _places.get(id)
	if place != null:
		for child in place.get_children():
			if child is ApproachRing:
				found.append(child)
	return found


func _set_cockpit_view(in_cockpit: bool) -> void:
	_in_cockpit = in_cockpit
	if in_cockpit:
		_cockpit_camera.make_current()
	else:
		_chase_camera.make_current()
	_ship.set_cockpit_view(in_cockpit)
	_hud.set_cockpit_view(in_cockpit)


## Hides the mouse and locks it to the window, so moving it steers the ship.
func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Pause menu: hop back to where you launched (tanks and cargo as they are).
func _back_to_launch_point() -> void:
	_remember_rig()
	_docking_at = ""
	_leaving = false
	_course.clear()
	_ship.cruise = null
	_launch_from(GameState.launch_from)
	_restore_rig()
	_capture_mouse()


func _quit_to_title() -> void:
	_remember_rig()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Radio.set_context(Radio.Context.OFF_AIR)
	get_tree().change_scene_to_file("res://scenes/boot/Boot.tscn")
