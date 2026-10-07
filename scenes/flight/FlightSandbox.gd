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
## - THE RIG'S INSIDE (F / X on autopilot): get out of the seat and walk
##   around your home, which is the inside of the rig: down the cockpit
##   stairs into dispatch, the hallway, your apartment (each room shown in a
##   SubViewport while the flight keeps going). The cockpit door at the top
##   of the stairs puts you back in the seat. Napping on the apartment's
##   bed fast-forwards the trip until you arrive.
## - THE CINEMATIC CAMERA (V / R3 on autopilot): a film director picks
##   shots of the rig (CinemaCamera.gd); touch the stick and you hold the
##   camera yourself. V again goes back to the chase cam.
## - HAZARDS: ion storms and speed traps (scenes/flight/events/HazardZone.gd)
##   tell the ship how strongly they're affecting it.
## - ROUTE EVENTS: what happens along the road: sights, calls, little
##   hazards, radio moments (RouteEvents.gd).
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
## are to each one's center. Empty = every system in
## res://data/systems/systems.tres.
@export var systems: Array[SystemData] = []
## How fast the docking autopilot flies, in m/s.
@export var docking_speed: float = 45.0

## Place id -> its node under World/Places.
var _places: Dictionary = {}
## Place id -> the ball of rocks around it (only places that have one).
var _shells: Dictionary = {}
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
var _roadside: RoadsideFuel
## Pro docking (Settings.pro_docking): the bay you're parking in, and the
## ring you came in through (or null / none).
var _pro_dock: ProDocking = null
## Courses can include routes (toll lanes, shortcuts, scenic lanes) as
## "route:<id>" stops.
const ROUTE_PREFIX: String = "route:"
## The toll lane you're on (already paid), and the scenic lanes you've
## enjoyed this trip.
var _on_toll: String = ""
var _toll_heading := Vector3.FORWARD
var _enjoyed: Dictionary = {}
var _in_belt: String = ""
var _pro_dock_ring: ApproachRing = null
## Walking around the cabin (out of the seat).
var _in_cabin: bool = false
## Whether the "hold to take the wheel" hint is showing for this push.
var _grab_hinted: bool = false
var _cabin_layer: CanvasLayer
## The cinematic camera and its black film bars (made in _ready).
var _cinema: CinemaCamera
var _letterbox: CanvasLayer
var _cabin_view: SubViewport
## Partway through walking into another room of the rig (fading).
var _changing_room: bool = false
var _cabin_room: HubRoom
## The view out of the rig's nose, for the apartment window (see
## _load_cabin_room): a little camera riding the ship.
var _window_view: SubViewport
var _window_camera: Camera3D
## Napping: time runs fast until you wake up or arrive.
var _napping: bool = false
var _nap_screen: CanvasLayer

## Getting up from the seat, you come down the cockpit stairs into dispatch.
const CABIN_SCENE: String = "res://scenes/hub/Dispatch.tscn"
const CABIN_SPAWN: String = "FromShip"
## The window view: how many pixels (small, for the PSX crunch), and where
## its camera sits on the rig (just past the nose, looking ahead).
const WINDOW_PIXELS := Vector2i(320, 180)
const WINDOW_CAMERA_SPOT := Vector3(0.0, 1.5, -16.0)
## The worried calls while you push past boost's top speed (overdrive).
const OVERDRIVE_CALLS: OverdriveCallList = preload("res://data/dialogue/overdrive_calls.tres")
var _overdrive_called: Dictionary = {}
var _overdrive_pending: OverdriveCall = null
var _overdrive_banner_clock: float = 0.0
## A new game starts here, out past the company HQ (which sits at the
## origin), cruising down the road toward the truck stop.
const OPEN_SPACE_SPOT := Vector3(0.0, 60.0, -1700.0)
const OPEN_SPACE_FACING := Vector3(0.0, 0.0, -1.0)
## The opening's first comm call: who, what, and how long after taking the wheel.
const OPENING_CALLER: String = "res://data/npcs/dispatch_morning.tres"
const OPENING_CALL_LINE: String = "Drop's done, hon. Fizzwick signed for the kitty litter. Pull into the truck stop: {boss} has your check, and he hates waiting. Follow the yellow diamond, fly slow through the ring."
const OPENING_CALL_DELAY: float = 2.5
## Prices at the Gas-N-Go counter.
const JERKY_PRICE: int = 15
const KEYCHAIN_PRICE: int = 5
var _rng := RandomNumberGenerator.new()
var _in_storm: bool = false
## Sights already logged this flight (by node), and a clock for checking.
var _logged: Dictionary = {}
var _log_clock: float = 0.0
## How close you have to get to a sight for it to go in the logbook.
const LOG_DISTANCE: float = 3000.0

@onready var _ship: Ship = $World/Ship
@onready var _chase_camera: ChaseCamera = $World/ChaseCamera
@onready var _cockpit_camera: Camera3D = $World/Ship/CockpitCamera
@onready var _speed_lines: SpeedLines = $SpeedLinesLayer/SpeedLines
@onready var _dust: SpaceDust = $World/SpaceDust
@onready var _motes: SpaceDust = $World/Motes
@onready var _environment: WorldEnvironment = $World/WorldEnvironment
@onready var _sun: DirectionalLight3D = $World/Sun
@onready var _hud: FlightHUD = $FlightHUD
@onready var _pause_menu: PauseMenu = $PauseMenu
@onready var _nebula: MeshInstance3D = $World/SkyBackdrop/Nebula
@onready var _chatter: CommChatter = $CommChatter
@onready var _events_holder: Node3D = $World/Events


func _ready() -> void:
	if systems.is_empty():
		systems = GameState.systems.systems
	_rng.randomize()
	_fade = ScreenFade.new()
	add_child(_fade)
	_fade.cover()
	# The rig you drive, with every upgrade you've bought, in its paint job.
	_ship.ship_data = GameState.upgraded_ship(GameState.active_ship_data())
	_ship.apply_look(GameState.paints.find(GameState.paint))
	_build_rest_stops()
	_build_routes()
	for node in $World/Places.get_children():
		if GameState.places.find(node.name) != null:
			_places[node.name] = node
			_surround_with_rocks(node as Node3D, GameState.places.find(node.name))
	_launch_from(GameState.launch_from)
	_restore_rig()
	_dust.ship = _ship
	_motes.ship = _ship
	_speed_lines.ship = _ship
	_hud.setup(_ship, null, "", Color.WHITE)
	_hud.places = _places  # So the HUD can name stations as you get near.
	_set_destination(_pick_destination())
	_chatter.start(_ship, _hud.comm, _places)
	_chatter.story_allowed = func() -> bool: return _docking_at.is_empty() and not _napping
	_chatter.story_banner.connect(func(text: String) -> void: _hud.show_banner(text, 3.0))
	_ship.autopilot_arrived.connect(_on_autopilot_arrived)
	_ship.lost_control.connect(_on_lost_control)
	_ship.exploded.connect(_on_exploded)
	_ship.cruise_released.connect(_on_cruise_released)
	_ship.flight_assist_switched.connect(_on_flight_assist_switched)
	GameState.start_haul()  # Every trip out on the road is a new haul.
	if GameState.in_opening():
		_opening_call()
	_route_events = RouteEvents.new()
	add_child(_route_events)
	_route_events.start(_ship, _events_holder, _chatter, _places, current_system)
	_route_events.banner_requested.connect(_hud.show_banner)
	_roadside = RoadsideFuel.new()
	add_child(_roadside)
	_roadside.start(_ship, _chatter)
	_roadside.allowed = func() -> bool: return _docking_at.is_empty() and not _ship.out_of_control
	_roadside.banner_requested.connect(_hud.show_banner)
	_setup_haze()
	_blend_systems(true)
	_pause_menu.resumed.connect(func() -> void:
		if not _in_cabin:
			_capture_mouse())
	_pause_menu.back_to_start_pressed.connect(func() -> void:
		_close_cabin()
		_back_to_launch_point())
	_pause_menu.quit_to_title_pressed.connect(func() -> void:
		_close_cabin()
		_quit_to_title())
	_pause_menu.dock_pressed.connect(func() -> void:
		_close_cabin()
		_arrive("truck_stop"))
	_make_cinema()
	_set_cockpit_view(false)
	_capture_mouse()
	Radio.set_context(Radio.Context.FLIGHT)
	# Bills come due on the road too (the calendar runs while you fly).
	Economy.bills_paid.connect(_on_bills_paid)
	_fade.fade_in()
	if GameState.show_date_card:
		GameState.show_date_card = false
		DateCard.pop_up(get_tree())
	if not GameState.debug_jump.is_empty():
		debug_jump()


## The opening: a new game starts just after a delivery. Raccoony calls:
## pull into the truck stop, the boss has your check. (Once.)
func _opening_call() -> void:
	if GameState.has_flag("opening_called"):
		return
	GameState.set_flag("opening_called")
	_chatter.skip_takeoff_call()  # Raccoony's call is the takeoff call this time.
	await get_tree().create_timer(OPENING_CALL_DELAY).timeout
	if not is_inside_tree():
		return
	var raccoony := load(OPENING_CALLER) as NPCData
	_hud.comm.call_in(raccoony, OPENING_CALL_LINE, ChatterSet.Situation.TAKEOFF, true, PackedStringArray(), true)


func _process(delta: float) -> void:
	_blend_systems(false)
	_log_clock -= delta
	if _log_clock <= 0.0:
		_log_clock = 0.5
		_spot_sights()
	if _nap_screen != null:
		_nap_screen.get_child(0).queue_redraw()
	_follow_with_window_camera()


func _exit_tree() -> void:
	Engine.time_scale = 1.0  # Never leave the game stuck in a nap's fast-forward.
	Radio.duck = 0.0  # Nor the radio turned down for the docking waltz.


func _physics_process(delta: float) -> void:
	if not GameState.active_job_id.is_empty() and _docking_at.is_empty():
		GameState.job_seconds += delta
	_feel_the_hazards(delta)
	_ride_routes(delta)
	_watch_overdrive(delta)
	_ship.flight.rest_pitch = _road_pitch()
	# Storms weaken the radio; flying fast swells the ambient music.
	Radio.signal_strength = 1.0 - _ship.storm * 0.8
	Radio.listener_position = _ship.global_position
	Radio.intensity = clampf(_ship.speed_ratio(), 0.0, 1.0)
	_show_grab_hint()
	if _ship.cruise != null and _ship.cruise.is_done() and _docking_at.is_empty() and _caught_by_the_ring():
		return
	if _ship.cruise != null and _ship.cruise.is_done() and _docking_at.is_empty():
		if _docking_computer_on:
			_stop_docking_computer()
		_ship.cruise = null  # Got there without docking (it's the pilot's turn).
		_hud.show_banner("AUTOPILOT OFF", 2.0)
		Sfx.play("autopilot_off")
	if _ship.cruise == null and _docking_at.is_empty():
		# Nobody's driving: wake up, get back in the seat, eyes on the road.
		if in_cinema():
			_end_cinema()
		if _napping:
			_wake_up()
		if _in_cabin:
			_back_to_seat()
	_run_docking_computer()
	_horn_cooldown = maxf(_horn_cooldown - delta, 0.0)
	if _pro_dock != null:
		_watch_pro_docking()
	if _docking_at.is_empty():
		for id: String in _places:
			for ring in _rings(id):
				if ring.is_inside(_ship.global_position) and _ship.flight.velocity.dot(ring.through_direction()) > 1.0:
					if _wants_pro_docking(id):
						if _pro_dock == null or _pro_dock.place_id != id:
							_start_pro_docking(id, ring)
						continue
					_begin_docking(id, ring)
					return


func _unhandled_input(event: InputEvent) -> void:
	if _ship.out_of_control:
		return  # Nothing answers now. Hold on.
	if _napping:
		# Any button wakes her, but not the very press that put her to bed
		# (the cabin hands it on to us too): only once she's been down a moment.
		if event.is_pressed() and not event.is_echo() and Time.get_ticks_msec() - _nap_started_msec > NAP_WAKE_GRACE_MSEC:
			_wake_up()
		return
	if _in_cabin:
		return  # On foot in the cabin: the keys walk, not fly.
	if _talk_back(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("get_up"):
		if _ship.cruise != null and _docking_at.is_empty():
			_open_cabin()
		else:
			_hud.show_banner("SET A COURSE FIRST (M)", 2.0)
	elif event.is_action_pressed("logbook"):
		_open_logbook()
	elif event.is_action_pressed("toggle_camera"):
		if in_cinema():
			_end_cinema()
		else:
			_set_cockpit_view(not _in_cockpit)
	elif event.is_action_pressed("cinema_camera"):
		_next_cinema_mode()
	elif event.is_action_pressed("chart_course"):
		if _pro_dock != null and _docking_at.is_empty():
			_pro_dock_to_autopilot()  # Pro docking: M hands the bay to the autopilot.
		elif _docking_at.is_empty():
			_open_course_chart()
	elif event.is_action_pressed("horn") and _ship.ship_data.air_horn:
		_honk()
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
	# Before the first job: Marge at the truck stop has it.
	if job == null and not GameState.has_flag("met_marge") and _places.has("truck_stop"):
		return "truck_stop"
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
	var job := GameState.active_job()
	_hud.destination_is_job = job != null and job.to_place == id
	_ship.cockpit.destination = dock
	_ship.cockpit.destination_name = place_name


## How steeply the road climbs (or dives) toward where she's headed, in
## radians: hands off the stick, the nose settles there instead of on level.
## The far systems sit well above and below the lane (a 30-40 degree climb),
## and holding the stick up for ten minutes isn't cozy. No destination: level.
func _road_pitch() -> float:
	if _destination_id.is_empty():
		return 0.0
	var dock := _dock_node(_destination_id)
	if dock == null:
		return 0.0
	var to := dock.global_position - _ship.global_position
	if to.length() < 1.0:
		return 0.0
	var limit := deg_to_rad(GameState.tuning.max_pitch_degrees) * 0.8
	return clampf(asin(clampf(to.normalized().y, -1.0, 1.0)), -limit, limit)


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
			Sfx.play("autopilot_off")
	_capture_mouse()


## Rock colors for the fields that surround stations.
const SURROUND_COLORS := {
	"rocks": [Color(0.56, 0.42, 0.52), Color(0.56, 0.41, 0.31), Color(0.4, 0.42, 0.53), Color(0.7, 0.6, 0.46), Color(0.62, 0.34, 0.26)],
	"ice": [Color(0.75, 0.9, 1.0), Color(0.6, 0.8, 0.9), Color(0.85, 0.95, 0.95), Color(0.5, 0.75, 0.85), Color(0.7, 0.85, 0.8)],
	"chips": [Color(1.0, 0.3, 0.6), Color(0.3, 0.6, 1.0), Color(1.0, 0.85, 0.3), Color(0.95, 0.95, 0.9), Color(0.2, 0.2, 0.25)],
}


## Puts a ball of rocks all the way around a station, if its place data asks
## for one (`surrounding_field`), with a clear traffic lane out from each
## approach ring. No flying over or around it: through the lane, or pick
## your way through the rocks.
func _surround_with_rocks(place_node: Node3D, place: PlaceData) -> void:
	if place.surrounding_field == "none":
		return
	var field := AsteroidField.new()
	field.name = "SurroundingRocks"
	field.layout = "shell"
	field.junk = place.surrounding_field == "junk"
	field.shell_radii = place.field_radii
	field.rock_count = place.field_rock_count
	field.landmark_count = 8
	field.landmark_radius_range = Vector2(70.0, 140.0)
	field.rock_radius_range = Vector2(3.0, 16.0) if place.surrounding_field in ["junk", "chips"] else Vector2(4.0, 55.0)
	field.keep_clear_spots = PackedVector3Array()
	field.lane_radius = place.field_lane_radius
	field.field_seed = hash(place.id) % 100000
	field.draw_distance = place.field_radii.y + 9000.0
	if SURROUND_COLORS.has(place.surrounding_field):
		field.rock_colors = PackedColorArray(SURROUND_COLORS[place.surrounding_field])
	for ring in place_node.get_children():
		if ring is ApproachRing:
			var outward := -(ring as ApproachRing).through_direction()
			field.lane_starts.append(place_node.global_position)
			field.lane_ends.append((ring as Node3D).global_position + outward * (place.field_radii.y + 600.0))
	field.position = place_node.global_position
	$World.add_child(field)  # (Not under the place: it doesn't turn with it.)
	_shells[place.id] = field


## Hands the wheel to the cruise autopilot, to visit `stops` (place ids) in
## order. Public so the tests can use it.
func engage_course(stops: PackedStringArray) -> void:
	_course = stops.duplicate()
	_aim_cruise()
	if _ship.cruise != null:
		Sfx.play("course_set")
		_hud.show_banner("AUTOPILOT > " + GameState.places.find(_course[_course.size() - 1]).display_name, 3.0)
		if not _in_cabin:
			_capture_mouse()  # Watch mode: the mouse is yours again.
		get_tree().create_timer(3.5).timeout.connect(func() -> void:
			if is_instance_valid(_ship) and _ship.cruise != null and not _in_cabin:
				_hud.show_banner("MOUSE IS FREE: SIT BACK AND WATCH · F / X: GET UP", 4.0))


## Sets the cruise autopilot on its way to the next stop on the course. A
## route (a toll lane, a shortcut, a scenic lane) is flown on the way to the
## stop after it, as one trip (so the autopilot doesn't brake in between).
func _aim_cruise() -> void:
	if _course.is_empty():
		_ship.cruise = null
		return
	var pilot := CruisePilot.new()
	var from := _ship.global_position
	while not _course.is_empty() and _course[0].begins_with(ROUTE_PREFIX):
		var lane := approach_points(_course[0], from)
		pilot.waypoints.append_array(lane)
		if not lane.is_empty():
			from = lane[lane.size() - 1]
		_course.remove_at(0)
	if _course.is_empty():
		_ship.cruise = null
		return
	pilot.waypoints.append_array(approach_points(_course[0], from))
	_ship.cruise = pilot
	_set_destination(_course[0])


## The spots to fly through to dock at place `id`, coming from `from`: a
## spot lined up outside the handiest approach ring, then through the ring
## (which starts the docking autopilot). Round any belt of rocks in the
## way (the safe route). `id` can also be "route:<id>": that route's lane,
## from the end nearest `from` to the other (see RouteData.gd).
func approach_points(id: String, from: Vector3) -> Array[Vector3]:
	if id.begins_with(ROUTE_PREFIX):
		var route := GameState.routes.find(id.trim_prefix(ROUTE_PREFIX))
		var lane: Array[Vector3] = []
		if route != null:
			lane.assign(Array(route.points_from(from)))
		return lane
	var best: ApproachRing = null
	var best_distance := INF
	for ring in _rings(id):
		var ring_line_up := ring.global_position - ring.through_direction() * 700.0
		if from.distance_to(ring_line_up) < best_distance:
			best_distance = from.distance_to(ring_line_up)
			best = ring
	if best == null:
		var dock := _dock_node(id)
		return [dock.global_position] if dock != null else []
	var points: Array[Vector3] = []
	var here := from
	var line_up := best.global_position - best.through_direction() * 700.0
	# Out of any ball of rocks we're inside, by its nearest lane.
	var left: AsteroidField = null
	for shell_id: String in _shells:
		var leaving := _shells[shell_id] as AsteroidField
		if shell_id != id and here.distance_to(leaving.global_position) < leaving.shell_radii.y + 100.0:
			here = _lane_mouth(leaving, here)
			points.append(here)
			left = leaving
	# Where we're headed next: the mouth of the lane to this ring, if this
	# place has rocks all around it (and we're outside them).
	var target := line_up
	var arriving := _shells.get(id) as AsteroidField
	var mouth := best.global_position - best.through_direction() * ((arriving.shell_radii.y if arriving != null else 0.0) + 600.0)
	var in_lane := arriving != null and here.distance_to(Geometry3D.get_closest_point_to_segment(here, best.global_position, mouth)) < arriving.lane_radius * 2.0
	if arriving != null and not in_lane and here.distance_to(arriving.global_position) > arriving.shell_radii.x:
		target = mouth
	else:
		arriving = null  # Already in the lane (or inside the rocks): straight on in.
	# Round any belt of rocks between here and there (the safe way).
	var dodge := _dodge_belts(here, target)
	if not dodge.is_empty():
		points.append_array(dodge)
		here = points[points.size() - 1]
	# Round the rocks we just left if what's next is behind them...
	if left != null:
		points.append_array(_around(left.global_position, here, target, left.shell_radii.y + 800.0))
		if not points.is_empty():
			here = points[points.size() - 1]
	# ...and round the destination's rocks (not through them) to its lane.
	if arriving != null:
		points.append_array(_around(arriving.global_position, here, target, arriving.shell_radii.y + 800.0))
		points.append(target)
	points.append(line_up)
	points.append(best.global_position + best.through_direction() * 150.0)
	return points


## The outside end of the lane through `field` nearest to `here`.
func _lane_mouth(field: AsteroidField, here: Vector3) -> Vector3:
	var best := field.global_position
	var best_distance := INF
	for end in field.lane_ends:
		if end.distance_to(here) < best_distance:
			best_distance = end.distance_to(here)
			best = end
	return best


## Waypoints that go around a ball (at `radius` from `center`) from `from`
## to `to`, both outside it, instead of straight through the middle. Empty
## if the straight line doesn't need it (they're on the same side).
func _around(center: Vector3, from: Vector3, to: Vector3, radius: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var start := (from - center).normalized()
	var finish := (to - center).normalized()
	var angle := start.angle_to(finish)
	if angle <= deg_to_rad(80.0):
		return points  # Coming in from this side anyway: the straight line misses the rocks.
	if angle > PI - 0.01:
		finish = (finish + start.cross(Vector3.UP).normalized() * 0.05).normalized()  # Exactly opposite: pick a side.
		angle = start.angle_to(finish)
	# First to the side of the ball (a line from far away just skims it),
	# then round its edge in steps of 40 degrees at most.
	var at := deg_to_rad(80.0)
	while at < angle - 0.01:
		points.append(center + start.slerp(finish, at / angle).normalized() * radius)
		at += deg_to_rad(40.0)
	return points


## Talking back on the comms: T / RB opens Jacki's replies, then Q / R / E
## (1 / 2 / 3, D-pad left / up / right) picks one. Returns whether the key
## was used for that.
func _talk_back(event: InputEvent) -> bool:
	var comm := _hud.comm
	if event.is_action_pressed("reply"):
		if comm.is_picking():
			comm.close_replies()
			return true
		if comm.can_reply():
			comm.open_replies()
			return true
		return false
	if not comm.is_picking() or not event.is_pressed() or event.is_echo():
		return false
	var choice := -1
	var key := event as InputEventKey
	if key != null and key.keycode in [KEY_1, KEY_2, KEY_3]:
		choice = key.keycode - KEY_1
	elif event.is_action_pressed("radio_previous"):
		choice = 0
	elif event.is_action_pressed("radio_power"):
		choice = 1
	elif event.is_action_pressed("radio_next"):
		choice = 2
	if choice < 0:
		return false
	comm.choose_reply(choice)
	return true


# --- The logbook -------------------------------------------------------------------

## Writes down sights you get close to (and the mystery radio station, if
## you hear it). The first time you see something: a banner (a fanfare for
## the rare ones).
func _spot_sights() -> void:
	var here := _ship.global_position
	var things: Array[Node] = []
	things.append_array(_events_holder.get_children())
	things.append_array($World/Roadside.get_children())
	for node in things:
		var thing := node as RoadsideThing
		if thing == null or thing.log_id.is_empty() or _logged.has(thing.get_instance_id()):
			continue
		if here.distance_to(thing.global_position) < LOG_DISTANCE + thing.contact_radius:
			_logged[thing.get_instance_id()] = true
			_log(thing.log_id)
	if Radio.powered and Radio.station().hidden and Radio.reception() > 0.5 and not _logged.has("numbers_station"):
		_logged["numbers_station"] = true
		_log("numbers_station")


func _log(id: String) -> void:
	if not GameState.log_sight(id):
		return
	var entry := GameState.sights.find(id)
	if entry.rare:
		_hud.show_banner("RARE SIGHT! LOGBOOK: " + entry.display_name, 6.0)
	else:
		_hud.show_banner("LOGBOOK: " + entry.display_name, 4.0)


func _open_logbook() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	await LogbookView.open(get_tree())
	get_tree().paused = false
	_capture_mouse()


# --- Crashes --------------------------------------------------------------------------

## A catastrophic hit: out of the cabin (or the nap) at once, back to the
## chase camera so you can watch, and a warning across the screen.
func _on_lost_control(reason: String) -> void:
	_end_cinema()
	_close_cabin()
	if _in_cockpit:
		_set_cockpit_view(false)
	var banners := {"hull": "!! HULL BREACH !!", "overdrive": "!! TOO FAST: SHE'S COMING APART !!"}
	_hud.show_banner(banners.get(reason, "!! LOST CONTROL !!"), 0.0)
	Radio.interference(GameState.tuning.crash_spin_seconds + 2.0)


## OVERDRIVE warnings, as you push past boost's top speed: banners that
## repeat (and get louder) as the hull strain builds, and worried comm calls
## from the crew and friends (res://data/dialogue/overdrive_calls.tres).
## Each call happens once per climb; ease off and they can come again.
func _watch_overdrive(delta: float) -> void:
	if _ship.out_of_control:
		return
	var kmh := _ship.flight.speed() * 3.6
	var strain := _ship.overdrive_strain
	var cap_kmh := FlightModel.boosted_top_speed(_ship.ship_data) * 3.6
	if kmh < cap_kmh - 50.0 and strain <= 0.0:
		_overdrive_called.clear()  # Calmed down: the next climb starts fresh.
		_overdrive_pending = null
		_overdrive_banner_clock = 0.0
		return
	var calls := OVERDRIVE_CALLS.calls
	for i in calls.size():
		var worry := calls[i]
		if worry == null or _overdrive_called.has(i):
			continue
		if (worry.at_kmh > 0.0 and kmh >= worry.at_kmh) or (worry.at_strain > 0.0 and strain >= worry.at_strain):
			_overdrive_called[i] = true
			_overdrive_pending = worry  # (The newest, most urgent one wins.)
	if _overdrive_pending != null and not _hud.comm.is_busy():
		_hud.comm.call_in(_overdrive_pending.speaker, _overdrive_pending.line, ChatterSet.Situation.IDLE, false, PackedStringArray(), true)
		_overdrive_pending = null
	# The banner, again and again, more urgent as the strain builds.
	_overdrive_banner_clock -= delta
	if _overdrive_banner_clock > 0.0 or (_ship.flight.overdrive <= 0.0 and strain <= 0.0):
		return
	var percent := roundi(strain * 100.0)
	if strain >= 0.75:
		_hud.show_banner("!!! HULL CRITICAL %d%%: LET GO OF BOOST !!!" % percent, 0.6)
		_overdrive_banner_clock = 0.5
	elif strain > 0.0:
		_hud.show_banner("!! HULL STRAIN %d%%: EASE OFF !!" % percent, 1.2)
		_overdrive_banner_clock = 1.0
	else:
		_hud.show_banner("OVERDRIVE · %d KM/H AND CLIMBING" % roundi(kmh), 1.2)
		_overdrive_banner_clock = 2.5


## The rig blew up. A moment to take it in, then a prompt to reload, then back
## to the last save.
func _on_exploded() -> void:
	_hud.show_banner("", 0.1)
	var tree := get_tree()
	tree.create_timer(1.6).timeout.connect(func() -> void: WreckScreen.show_and_restart(tree))


# --- The cabin ---------------------------------------------------------------------

## Out of the seat: the rig's sleeper cabin, shown over the flight while the
## autopilot keeps driving.
func _open_cabin() -> void:
	if _in_cabin:
		return
	_end_cinema()
	_in_cabin = true
	_ship.controls.hands_free = true
	await _fade.fade_out()
	_hud.set_cabin(true)
	_cabin_layer = CanvasLayer.new()
	_cabin_layer.layer = 4  # Over the flight, under the HUD's comm calls.
	add_child(_cabin_layer)
	var frame := SubViewportContainer.new()
	frame.stretch = true
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cabin_layer.add_child(frame)
	_cabin_view = SubViewport.new()
	_cabin_view.own_world_3d = true  # Its own little world: nothing in it touches space.
	_cabin_view.audio_listener_enable_3d = true
	frame.add_child(_cabin_view)
	_load_cabin_room(CABIN_SCENE, CABIN_SPAWN)
	_fade.fade_in()
	_hud.show_banner("COCKPIT DOOR: BACK TO THE SEAT   YOUR BED: NAP", 5.0)


## Puts one of the rig's rooms in the cabin view, arriving at `spawn`.
func _load_cabin_room(scene_path: String, spawn: String) -> void:
	if _cabin_room != null:
		_cabin_room.queue_free()
	GameState.next_spawn = spawn
	_cabin_room = (load(scene_path) as PackedScene).instantiate() as HubRoom
	_cabin_room.aboard = true
	_cabin_room.left_cabin.connect(_back_to_seat)
	_cabin_room.nap_requested.connect(_nap)
	_cabin_room.room_change_requested.connect(_walk_to_room)
	_cabin_room.window_feed = _window_feed()
	_cabin_view.add_child(_cabin_room)
	# Only draw the view outside while there's a window to see it through.
	_window_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _cabin_room.has_window() else SubViewport.UPDATE_DISABLED


## The live view of space for the rig's window: a small second camera in
## the flight world, riding the ship's nose. Made once per walk around the
## cabin (it goes away with the cabin view).
func _window_feed() -> Texture2D:
	if _window_view == null:
		_window_view = SubViewport.new()
		_window_view.size = WINDOW_PIXELS
		_window_view.world_3d = _ship.get_world_3d()  # The same space the rig's flying through.
		_window_view.audio_listener_enable_3d = false
		_window_camera = Camera3D.new()
		_window_camera.fov = 60.0
		_window_camera.near = 1.0
		_window_camera.far = _cockpit_camera.far
		_window_view.add_child(_window_camera)
		_cabin_layer.add_child(_window_view)
		_follow_with_window_camera()
	return _window_view.get_texture()


func _follow_with_window_camera() -> void:
	if _window_camera != null:
		_window_camera.global_transform = _ship.global_transform.translated_local(WINDOW_CAMERA_SPOT)


## Walking through a door to another room of the rig, in flight.
func _walk_to_room(scene_path: String, spawn: String) -> void:
	if not _in_cabin or _napping or _changing_room:
		return
	_changing_room = true
	await _fade.fade_out()
	if _in_cabin:
		_load_cabin_room(scene_path, spawn)
	_changing_room = false
	_fade.fade_in()


## Back in the driver's seat (walking out the cabin door).
func _back_to_seat() -> void:
	if not _in_cabin:
		return
	await _fade.fade_out()
	_close_cabin()
	_fade.fade_in()


## Shuts the cabin view at once and puts you back in the seat.
func _close_cabin() -> void:
	if not _in_cabin:
		return
	_in_cabin = false
	if _napping:
		_wake_up()
	if _cabin_layer != null:
		_cabin_layer.queue_free()
		_cabin_layer = null
		_cabin_view = null
		_cabin_room = null
		_window_view = null
		_window_camera = null
	_ship.controls.hands_free = false
	_hud.set_cabin(false)
	Radio.set_context(Radio.Context.FLIGHT)
	_capture_mouse()


## Sleeping in the apartment's bed in flight: lights out, and she wakes up
## back in the seat as the rig pulls up to the next stop on the course
## (SLEEP_WAKE_DISTANCE out, so she still gets to watch it dock). The miles
## still cost their fuel, and the clock still runs for rush jobs; she just
## doesn't have to sit through them. Public so the tests can use it.
func _nap() -> void:
	if _napping or _cabin_room == null:
		return
	# No course set (the autopilot let go, or nobody set one)? Head for the
	# job's drop-off; with no job, she just naps where she is.
	if _ship.cruise == null or _course.is_empty():
		var job := GameState.active_job()
		if job != null and _places.has(job.to_place):
			engage_course(PackedStringArray([job.to_place]))
	_nap_in_place = _ship.cruise == null or _course.is_empty()
	_napping = true
	_nap_started_msec = Time.get_ticks_msec()
	_cabin_room.player.set_busy(true)
	_nap_screen = CanvasLayer.new()
	_nap_screen.layer = 45
	var dark := Control.new()
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.draw.connect(func() -> void: _draw_nap(dark))
	_nap_screen.add_child(dark)
	add_child(_nap_screen)
	await get_tree().create_timer(2.2).timeout
	if not _napping:
		return  # Something woke her (arriving, a crash).
	if _nap_in_place:
		# Nowhere to go: a quick nap, and she wakes up where she was.
		Economy.advance_minutes(GameState.tuning.nap_hours * 60.0)
		await get_tree().create_timer(1.2).timeout
		_wake_up()
		_hud.show_banner("A QUICK NAP. NO COURSE SET, SO WE STAYED PUT (M CHARTS ONE).", 4.0)
		return
	_skip_to_next_stop()
	await get_tree().create_timer(1.2).timeout
	if not _napping:
		return
	_wake_up()
	_close_cabin()
	var place := GameState.places.find(_destination_id)
	_hud.show_banner("SLEPT LIKE A ROCK. %s AHEAD." % (place.display_name if place != null else "THE NEXT STOP"), 4.0)


## On while she naps with no course set (she wakes up where she was).
var _nap_in_place := false
## When the nap started (Time.get_ticks_msec), and how long after that a
## button press counts as "wake up" (so the E that started it doesn't).
var _nap_started_msec := 0
const NAP_WAKE_GRACE_MSEC: int = 600

## How far out from the next stop's approach she wakes up, in meters.
const SLEEP_WAKE_DISTANCE: float = 1500.0


## The debug menu's jump (autoload/DebugMenu.gd): puts the rig the asked
## number of minutes (at cruise speed) out from the asked place, on the
## approach line, cruising, with the autopilot set for it. Costs no fuel
## or time: it's for testing.
func debug_jump() -> void:
	var wish := GameState.debug_jump
	GameState.debug_jump = {}
	var id := str(wish.get("place", ""))
	if not _places.has(id):
		return
	_close_cabin()
	_end_cinema()
	_docking_at = ""
	_leaving = false
	_chatter.skip_takeoff_call()  # (No "you're clear" from wherever we left.)
	var points := approach_points(id, _ship.global_position)
	if points.size() < 2:
		return
	var line_up := points[points.size() - 2]
	var heading_in := (points[points.size() - 1] - line_up).normalized()
	var out := float(wish.get("minutes", 3.0)) * 60.0 * _ship.ship_data.max_speed
	_ship.teleport(Transform3D(Basis.looking_at(heading_in, Vector3.UP), line_up - heading_in * out))
	_restore_rig()  # (Teleporting resets the tanks; put them back.)
	_ship.controls.lever = 1.0
	_ship.flight.velocity = heading_in * _ship.ship_data.max_speed
	_chase_camera.snap_behind_target()
	_blend_systems(true)
	engage_course(PackedStringArray([id]))
	_set_destination(id)
	var place := GameState.places.find(id)
	_hud.show_banner("DEBUG: %d MIN OUT FROM %s" % [roundi(float(wish.get("minutes", 3.0))), place.display_name if place != null else id], 3.0)


## Moves the rig along the course to just outside the next stop, nose in,
## still cruising, and charges the trip's fuel and time.
func _skip_to_next_stop() -> void:
	var points := approach_points(_course[0], _ship.global_position)
	if points.size() < 2:
		return
	var line_up := points[points.size() - 2]  # (The route's last two points: line up, through the ring.)
	var heading_in := (points[points.size() - 1] - line_up).normalized()
	var wake_at := line_up - heading_in * SLEEP_WAKE_DISTANCE
	if _ship.global_position.distance_to(line_up) <= SLEEP_WAKE_DISTANCE + 200.0:
		return  # Nearly there anyway.
	var numbers := CourseChart.estimate(PackedVector3Array([_ship.global_position, wake_at]), _ship.ship_data, GameState.tuning, 0.0)
	# Teleporting resets the rig's tanks and throttle; keep them as they were.
	var fuel := maxf(_ship.flight.fuel - float(numbers["fuel"]), 0.0)
	var boost_fuel := _ship.flight.boost_fuel
	var lever := _ship.controls.lever
	var speed := maxf(_ship.flight.speed(), _ship.ship_data.max_speed * 0.8)
	_ship.teleport(Transform3D(Basis.looking_at(heading_in, Vector3.UP), wake_at))
	_ship.flight.fuel = fuel
	_ship.flight.boost_fuel = boost_fuel
	_ship.controls.lever = lever
	_ship.flight.velocity = heading_in * speed
	if not GameState.active_job_id.is_empty():
		GameState.job_seconds += float(numbers["cruise_seconds"])
	# The calendar runs on while she sleeps, as if she'd driven it.
	Economy.advance_minutes(float(numbers["cruise_seconds"]) * GameState.tuning.flight_minutes_per_second)
	_aim_cruise()
	_chase_camera.snap_behind_target()
	_blend_systems(true)


func _wake_up() -> void:
	if not _napping:
		return
	_napping = false
	if _nap_screen != null:
		_nap_screen.queue_free()
		_nap_screen = null
	if _cabin_room != null and is_instance_valid(_cabin_room):
		_cabin_room.player.set_busy(false)


func _draw_nap(canvas: Control) -> void:
	var screen := canvas.size
	canvas.draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.01, 0.03))
	var square := maxf(2.0, floorf(screen.y / 200.0))
	var dock := _dock_node(_destination_id)
	var left := dock.global_position.distance_to(_ship.global_position) / 1000.0 if dock != null else 0.0
	var z := "Z".repeat(1 + int(Time.get_ticks_msec() / 600.0) % 3)
	PixelFont.draw_centered(canvas, screen * 0.5 - Vector2(0.0, square * 14.0), z, square * 3.0, Color(0.7, 0.75, 1.0))
	# The date, small in the corner (it moves on while she sleeps).
	DateCard.draw_date(canvas, screen, 1.0)
	if _nap_in_place:
		PixelFont.draw_centered(canvas, screen * 0.5 + Vector2(0.0, square * 4.0), "JUST RESTING HER EYES.", square, Color(0.8, 0.82, 0.9))
		return
	PixelFont.draw_centered(canvas, screen * 0.5 + Vector2(0.0, square * 4.0), "SLEEPING. THE AUTOPILOT'S GOT IT.", square, Color(0.8, 0.82, 0.9))
	PixelFont.draw_centered(canvas, screen * 0.5 + Vector2(0.0, square * 16.0), "%.1f KM TO GO" % left, square, Color(1.0, 0.85, 0.3))


## While you push the stick hard on autopilot, say what's about to happen
## (once per push).
func _show_grab_hint() -> void:
	var grab := _ship.cruise.grab if _ship.cruise != null else 0.0
	if grab > 0.25 and not _grab_hinted:
		_grab_hinted = true
		_hud.show_banner("HOLD TO TAKE THE WHEEL", 1.0)
	elif grab <= 0.0:
		_grab_hinted = false


## The week's bills came due while you were on the road: a heads-up (the
## bills card itself shows at the next stop).
func _on_bills_paid(bill: Dictionary) -> void:
	var on_tab := int(bill.get("on_tab", 0))
	var words := "WEEKLY BILLS PAID: %d %s" % [int(bill.get("paid", 0)), GameState.names.currency_short]
	if on_tab > 0:
		words += " (%d ON THE TAB)" % on_tab
	_hud.show_banner(words, 4.0)


## Newtonian flight: G switched Flight Assist.
func _on_flight_assist_switched(on: bool) -> void:
	_hud.show_banner("FLIGHT ASSIST ON" if on else "FLIGHT ASSIST OFF · DRIFT AND SPIN ARE YOURS", 2.5)
	Sfx.play("clunk" if not on else "ui_confirm")


func _on_cruise_released() -> void:
	Sfx.play("autopilot_off")
	_course.clear()
	if not _in_cabin and _docking_at.is_empty():
		_capture_mouse()  # Your wheel again (and the mouse looks around).
	_hud.show_banner("MANUAL CONTROL", 2.0)
	if _docking_computer_on and _docking_at.is_empty():
		# You took the wheel back: it won't grab it again on this approach.
		_docking_computer_declined[_destination_id] = true
		_stop_docking_computer()
		_hud.show_banner("DOCKING COMPUTER OFF. YOUR WHEEL.", 2.5)


# --- The docking computer and the air horn (upgrades from Dusty's) -------------------

## On while the docking computer is flying you in (and its waltz plays).
var _docking_computer_on := false
## Places where you took the wheel back from it (it waits until you've flown
## away and come back before offering again).
var _docking_computer_declined := {}
var _waltz: AudioStreamPlayer
var _horn_cooldown := 0.0

const WALTZ := preload("res://audio/generated/docking_waltz.wav")


## With a docking computer aboard: once you're close to your destination,
## it takes the wheel, flies the lane through the rocks, threads the ring
## and docks, to its own little waltz (the radio fades out for it).
func _run_docking_computer() -> void:
	if not _ship.ship_data.docking_computer or _destination_id.is_empty() or Settings.pro_docking:
		return  # (With pro docking on, you'd rather park it yourself.)
	var dock := _dock_node(_destination_id)
	if dock == null:
		return
	var distance := _ship.global_position.distance_to(dock.global_position)
	var reach := GameState.tuning.docking_computer_range
	if distance > reach * 1.5:
		_docking_computer_declined.erase(_destination_id)
	if _docking_computer_on or distance > reach or not _docking_at.is_empty() or _docking_computer_declined.has(_destination_id):
		return
	# Only where you mean to go: your load's drop-off, or a course you set
	# (not every station you happen to fly past).
	var job := GameState.active_job()
	var on_course := _ship.cruise != null and not _course.is_empty() and _course[0] == _destination_id
	if not on_course and (job == null or job.to_place != _destination_id):
		return
	if _ship.cruise == null or _course.is_empty() or _course[0] != _destination_id:
		engage_course(PackedStringArray([_destination_id]))
	if _ship.cruise == null:
		return
	_docking_computer_on = true
	_hud.show_banner("DOCKING COMPUTER ENGAGED", 3.0)
	if _waltz == null:
		_waltz = AudioStreamPlayer.new()
		_waltz.stream = WALTZ
		_waltz.bus = Radio.RADIO_BUS  # (The radio volume slider sets it too.)
		add_child(_waltz)
	_waltz.volume_db = -30.0
	_waltz.play()
	create_tween().tween_property(_waltz, "volume_db", linear_to_db(maxf(Settings.radio_volume, 0.0001)) - 4.0, 2.5)
	Radio.duck = 1.0


## The docking computer's done (docked, or you took over): the waltz fades
## and the radio comes back.
func _stop_docking_computer() -> void:
	_docking_computer_on = false
	Radio.duck = 0.0
	if _waltz != null and _waltz.playing:
		var fade := create_tween()
		fade.tween_property(_waltz, "volume_db", -40.0, 2.0)
		fade.tween_callback(_waltz.stop)


## BWAAAMP. A trucker nearby might honk back.
func _honk() -> void:
	if _horn_cooldown > 0.0:
		return
	_horn_cooldown = 1.2
	Sfx.play("horn")
	var tuning := GameState.tuning
	var nearest: TrafficShip = null
	var best := tuning.horn_reply_range
	for other: Node in get_tree().get_nodes_in_group("traffic"):
		if other is TrafficShip:
			var distance := _ship.global_position.distance_to((other as TrafficShip).global_position)
			if distance < best:
				best = distance
				nearest = other
	if nearest == null or _rng.randf() > tuning.horn_reply_chance:
		return
	await get_tree().create_timer(_rng.randf_range(0.7, 1.4)).timeout
	if not is_instance_valid(nearest):
		return
	# Farther off sounds quieter; every truck's horn is its own pitch.
	Sfx.play("horn", -4.0 - best / 150.0, _rng.randf_range(0.7, 1.3))
	_hud.show_banner("%s HONKS BACK" % nearest.id_label.to_upper() if not nearest.id_label.is_empty() else "SOMEBODY HONKS BACK", 2.5)


# --- Launching ----------------------------------------------------------------------

## Puts the rig at a place's launch point, nose out, engines idle.
func _launch_from(id: String) -> void:
	if id == GameState.OPEN_SPACE:
		# A new game: out past the company HQ, just after a delivery, already
		# cruising toward the truck stop to collect the check.
		_ship.teleport(Transform3D(Basis.looking_at(OPEN_SPACE_FACING, Vector3.UP), OPEN_SPACE_SPOT))
		if GameState.in_opening():
			_ship.controls.lever = 1.0
			_ship.flight.velocity = OPEN_SPACE_FACING * _ship.ship_data.max_speed
		_chase_camera.snap_behind_target()
		return
	var place: Node3D = _places.get(id, _places.get("truck_stop"))
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
			"hull": _ship.hull, "cargo": _ship.cargo_condition, "snack": GameState.rig.get("snack", 0.0),
			"weighed": GameState.rig.get("weighed", 0.0)}


# --- Docking ------------------------------------------------------------------------

func _begin_docking(id: String, ring: ApproachRing) -> void:
	_docking_at = id
	if _napping:
		_wake_up()
	if _in_cabin:
		_hud.show_banner("ARRIVING! BACK TO THE SEAT", 3.0)
		_close_cabin()
	if not _course.is_empty() and _course[0] == id:
		_course.remove_at(0)
	var dock := _dock_node(id)
	var route: Array[Vector3] = [ring.global_position + ring.through_direction() * 40.0, dock.global_position]
	if (_ship.global_position - ring.global_position).dot(ring.through_direction()) > 40.0:
		route.remove_at(0)  # Already past the ring: straight on in.
	_ship.fly_route(route, clampf(_ship.flight.speed(), 30.0, docking_speed))
	_ship.set_meta("docking_ring", ring.global_position)
	var place := GameState.places.find(id)
	_hud.show_banner("PULLING IN" if place.kind == PlaceData.Kind.DRIVE_THROUGH else "AUTOPILOT DOCKING", 0.0)
	_chatter.say(ChatterSet.Situation.DOCKING, id)


## The autopilot finished its course right by the destination's ring but
## missed the hole (a bit off to the side): the ring's tractor beam catches
## the rig and docks it anyway, instead of letting it coast into the
## station. Returns whether it did.
func _caught_by_the_ring() -> bool:
	if _destination_id.is_empty() or _course.is_empty() or _course[0] != _destination_id:
		return false
	for ring in _rings(_destination_id):
		if _ship.global_position.distance_to(ring.global_position) < ring.radius * 6.0:
			_ship.cruise = null
			_course.clear()
			if _wants_pro_docking(_destination_id):
				_start_pro_docking(_destination_id, ring)
			else:
				_begin_docking(_destination_id, ring)
			return true
	return false


# --- Routes and rest stops -------------------------------------------------------------

## Builds every rest stop from its place data (RestStop.gd) under
## World/Places, unless the scene already has one by that name.
func _build_rest_stops() -> void:
	var holder := $World/Places
	for place in GameState.places.places:
		if place != null and place.rest_stop != "none" and not holder.has_node(NodePath(place.id)):
			holder.add_child(RestStop.build(place))


## Builds the route choices out on the road (res://data/routes/): toll
## turnpikes (gold beacons and gates), shortcuts (a belt of rocks across the
## way) and scenic lanes (pink and teal beacons past a sherbet nebula).
func _build_routes() -> void:
	for route in GameState.routes.routes:
		if route == null:
			continue
		var lane := PackedVector3Array([route.start, route.finish])
		match route.kind:
			"toll":
				var beacons := Spaceway.new()
				beacons.name = "Toll_" + route.id
				beacons.points = lane
				beacons.half_width = route.radius * 0.8
				beacons.spacing = 300.0
				beacons.left_color = Color(1.0, 0.8, 0.2)
				beacons.right_color = Color(1.0, 0.8, 0.2)
				$World.add_child(beacons)
				_toll_gates(route)
			"shortcut":
				var belt := AsteroidField.new()
				belt.name = "Belt_" + route.id
				belt.layout = "egg"
				belt.field_size = Vector3(route.belt_width, route.belt_width * 0.45, route.length())
				belt.rock_count = route.rock_count
				belt.rock_radius_range = Vector2(4.0, 45.0)
				belt.landmark_count = 6
				belt.keep_clear_spots = PackedVector3Array()
				belt.field_seed = absi(hash(route.id)) % 100000
				belt.draw_distance = route.belt_width + 9000.0
				if not route.rock_colors.is_empty():
					belt.rock_colors = route.rock_colors
				var along := (route.finish - route.start).normalized()
				belt.transform = Transform3D(Basis.looking_at(along, Vector3.UP if absf(along.y) < 0.95 else Vector3.RIGHT), route.middle())
				$World.add_child(belt)
			"scenic":
				var beacons := Spaceway.new()
				beacons.name = "Scenic_" + route.id
				beacons.points = lane
				beacons.half_width = route.radius * 0.8
				beacons.spacing = 400.0
				beacons.left_color = Color(1.0, 0.45, 0.75)
				beacons.right_color = Color(0.35, 0.95, 0.9)
				$World.add_child(beacons)
				_sherbet_nebula(route)


## Big glowing gates every few kilometers down a toll lane, and a booth at
## each end.
func _toll_gates(route: RouteData) -> void:
	var along := (route.finish - route.start).normalized()
	var basis := Basis.looking_at(along, Vector3.UP if absf(along.y) < 0.95 else Vector3.RIGHT)
	var glow := ShaderMaterial.new()
	glow.shader = preload("res://shaders/psx_surface.gdshader")
	glow.set_shader_parameter("albedo", Color(1.0, 0.8, 0.2))
	glow.set_shader_parameter("emission", Color(1.0, 0.8, 0.2))
	glow.set_shader_parameter("emission_strength", 1.4)
	var gate := TorusMesh.new()
	gate.inner_radius = route.radius
	gate.outer_radius = route.radius + 12.0
	gate.rings = 24
	gate.ring_segments = 4
	gate.material = glow
	var spacing := 3000.0
	var count := int(route.length() / spacing)
	for i in count + 1:
		var ring := MeshInstance3D.new()
		ring.mesh = gate
		ring.transform = Transform3D(basis * Basis(Vector3.RIGHT, PI / 2.0), route.start + along * minf(i * spacing, route.length()))
		$World.add_child(ring)
	for end: Vector3 in [route.start, route.finish]:
		var booth := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(60.0, 50.0, 60.0)
		box.material = glow
		booth.mesh = box
		booth.position = end + basis.x * (route.radius + 80.0)
		$World.add_child(booth)


## A soft, sherbet-colored nebula beside a scenic lane: a few huge glowing
## blobs.
func _sherbet_nebula(route: RouteData) -> void:
	var along := (route.finish - route.start).normalized()
	var side := along.cross(Vector3.UP).normalized()
	var colors := [Color(1.0, 0.55, 0.7), Color(1.0, 0.8, 0.45), Color(0.55, 0.9, 1.0), Color(0.85, 0.6, 1.0)]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(route.id)
	for i in 7:
		var blob := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = rng.randf_range(1500.0, 3200.0)
		ball.height = ball.radius * 2.0
		ball.radial_segments = 12
		ball.rings = 6
		var color: Color = colors[i % colors.size()]
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(color, 0.22)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		ball.material = material
		blob.mesh = ball
		blob.position = route.middle() + along * rng.randf_range(-9000.0, 9000.0) + side * rng.randf_range(5000.0, 9000.0) + Vector3.UP * rng.randf_range(-3000.0, 3000.0)
		blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		$World.add_child(blob)


## Round the belts of rocks lying between `from` and `to` (the safe way),
## unless one of them is inside a belt already (you're taking the shortcut).
func _dodge_belts(from: Vector3, to: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for route in GameState.routes.routes:
		if route == null or route.kind != "shortcut":
			continue
		var reach := maxf(route.belt_width, route.length()) * 0.5 + 1200.0
		var center := route.middle()
		if from.distance_to(center) < reach or to.distance_to(center) < reach:
			continue
		var nearest := Geometry3D.get_closest_point_to_segment(center, from, to)
		if nearest.distance_to(center) < reach:
			points.append_array(_around(center, from, to, reach))
	return points


## Out on the routes: toll lanes charge at the gate and their current
## carries you along; scenic lanes calm you down; belts warn you.
func _ride_routes(delta: float) -> void:
	if _ship.out_of_control or not _docking_at.is_empty():
		return
	var spot := _ship.global_position
	var on_toll := ""
	var in_belt := ""
	for route in GameState.routes.routes:
		if route == null:
			continue
		var off := route.distance_to(spot)
		match route.kind:
			"toll":
				if off < route.radius:
					on_toll = route.id
					if _on_toll != route.id:
						_pay_toll(route)
						# The current runs toward the far end from where you joined.
						var ends := route.points_from(spot)
						_toll_heading = (ends[1] - ends[0]).normalized()
					var heading := _toll_heading
					# You ride the current while your nose points down the lane
					# and you're not braking; turn away or brake and it lets go
					# (so you can always slow down and leave at the end).
					var riding := _ship.flight.nose().dot(heading) > 0.7 and _ship.flight.thrust >= 0.0
					var past_the_end := (spot - route.points_from(spot)[0]).dot(heading) <= 0.0 or (spot - (route.points_from(spot)[1])).dot(heading) >= 0.0
					if riding and not past_the_end:
						var velocity := _ship.flight.velocity
						# The lane holds you like a tube: sideways drift fades and
						# you're drawn gently to the middle line.
						var middle_line := Geometry3D.get_closest_point_to_segment(spot, route.start, route.finish)
						var sideways := velocity - heading * velocity.dot(heading)
						velocity -= sideways * (1.0 - exp(-1.5 * delta))
						velocity += (middle_line - spot) * 0.6 * delta
						if velocity.dot(heading) < route.current_speed:
							velocity += heading * route.current_push * delta
						_ship.flight.velocity = velocity
			"shortcut":
				if spot.distance_to(route.middle()) < maxf(route.belt_width, route.length()) * 0.5:
					in_belt = route.id
					if _in_belt != route.id:
						_hud.show_banner(route.display_name + ": ROCKS AHEAD. EASY DOES IT.", 3.0)
			"scenic":
				var middle_part := spot.distance_to(route.middle()) < route.length() * 0.25
				if off < route.radius * 3.0 and middle_part and not _enjoyed.has(route.id):
					_enjoyed[route.id] = true
					GameState.rig["snack"] = 1.0  # The view settles her hands, like a snack would.
					var first := GameState.log_sight(route.sight_id) if not route.sight_id.is_empty() else false
					_hud.show_banner(route.display_name + ": WHAT A VIEW" + ("  (NEW IN THE LOGBOOK)" if first else ""), 4.0)
	_on_toll = on_toll
	_in_belt = in_belt


## The gate takes its toll (anything you can't pay goes on the tab).
func _pay_toll(route: RouteData) -> void:
	var paid := mini(route.toll, GameState.credits)
	if paid > 0:
		GameState.spend(paid)
	GameState.tab += route.toll - paid
	var note := "-%d %s" % [route.toll, GameState.names.currency_short] if paid == route.toll else "%d %s ON THE TAB" % [route.toll - paid, GameState.names.currency_short]
	_hud.show_banner("%s: TOLL %s  ENJOY THE CURRENT" % [route.display_name, note], 3.5)
	Sfx.play("course_set")


# --- Pro docking ----------------------------------------------------------------------

## Whether to park in the bay by hand here (pro docking's on, it's a
## station with a loading bay, and the docking computer isn't flying).
func _wants_pro_docking(id: String) -> bool:
	var place := GameState.places.find(id)
	return Settings.pro_docking and place != null and place.kind != PlaceData.Kind.DRIVE_THROUGH and not _docking_computer_on


## Through the ring with pro docking on: the bay lights up and it's your wheel.
func _start_pro_docking(id: String, ring: ApproachRing) -> void:
	_end_pro_docking()
	if _napping:
		_wake_up()
	if _in_cabin:
		_close_cabin()
	_end_cinema()
	_ship.cruise = null  # Your wheel now.
	if not _course.is_empty() and _course[0] == id:
		_course.remove_at(0)
	_pro_dock = ProDocking.new()
	_pro_dock.name = "ProDockingBay"
	$World.add_child(_pro_dock)
	_pro_dock.start(_ship, id, _dock_node(id).global_position, ring.through_direction())
	_pro_dock.parked.connect(_on_pro_docked)
	_pro_dock_ring = ring
	_hud.show_banner("PRO DOCKING: PARK IN THE BAY (BACK IN FOR A BIGGER TIP)  M = AUTOPILOT", 4.0)
	_chatter.say(ChatterSet.Situation.DOCKING, id)


## While parking: guidance on the HUD; wander off and it gives up.
func _watch_pro_docking() -> void:
	if not _docking_at.is_empty():
		return
	if _pro_dock.abandoned():
		_end_pro_docking()
		_hud.show_banner("PRO DOCKING CANCELLED: FLY BACK THROUGH THE RING", 3.0)
		return
	if _hud_banner_clock():
		_hud.show_banner(_pro_dock.guidance(), 0.0)


var _guidance_clock := 0.0


## True every few frames (so the guidance banner isn't rebuilt every frame).
func _hud_banner_clock() -> bool:
	_guidance_clock += get_physics_process_delta_time()
	if _guidance_clock < 0.1:
		return false
	_guidance_clock = 0.0
	return true


## Parked! The dock crew tips you, and in you go.
func _on_pro_docked(result: Dictionary) -> void:
	var id := str(result["place"])
	var ring_spot := _pro_dock_ring.global_position if _pro_dock_ring != null else _ship.global_position
	_end_pro_docking()
	var tip := int(result["tip"])
	GameState.add_credits(tip)
	GameState.set_flag("pro_docked")
	Sfx.play("cash")
	_docking_at = id
	_ship.set_meta("docking_ring", ring_spot)
	_ship.flight.velocity = Vector3.ZERO
	_ship.controls.clear()
	_ship.process_mode = Node.PROCESS_MODE_DISABLED  # Parked: hands off.
	var how := "BACKED IN" if result["backed_in"] else "PARKED"
	_hud.show_banner("%s %s!  DOCK CREW TIP +%d %s" % [result["grade"], how, tip, GameState.names.currency_short], 3.0)
	await get_tree().create_timer(1.5).timeout
	_arrive(id)


## Gave up on parking by hand: the autopilot takes it from here.
func _pro_dock_to_autopilot() -> void:
	var id := _pro_dock.place_id
	var ring := _pro_dock_ring
	_end_pro_docking()
	if ring != null:
		_begin_docking(id, ring)


func _end_pro_docking() -> void:
	if _pro_dock != null:
		_pro_dock.queue_free()
	_pro_dock = null
	_pro_dock_ring = null


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
	if _docking_computer_on:
		_stop_docking_computer()
	if place == null:
		return
	_end_cinema()
	GameState.visit(id)
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
	GameState.rig["snack"] = 0.0  # The trip's over; so is the jerky's calm.
	if GameState.deliver_at(id):
		Radio.dj_react("delivery", {"place": place.display_name}, true)  # A shout-out next trip.
	if place.free_fuel:
		GameState.rig["fuel"] = 1.0
		GameState.rig["boost_fuel"] = 1.0
	GameState.launch_from = id
	GameState.next_spawn = place.arrival_spawn
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _fade.fade_out()
	Radio.set_context(Radio.Context.OFF_AIR)
	LoadingScreen.go(get_tree(), place.interior_scene, "place")


## DROP_OFF places: you stay in the cab. The crane takes the load, you get
## paid, maybe take a load back and fill up, then launch again.
func _drop_off(id: String, place: PlaceData) -> void:
	var delivered := _deliver_here(id)
	if delivered:
		Radio.dj_react("delivery", {"place": place.display_name})
	await _greet(place, "DOCKED: " + place.display_name)
	await _counter(id, place, delivered)
	GameState.launch_from = id
	GameState.rig["snack"] = 0.0  # A new trip.
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
	# A load for here gets dropped at the counter (the boss sends things to
	# the Gas-N-Go).
	var delivered := _deliver_here(id)
	if delivered:
		Radio.dj_react("delivery", {"place": place.display_name})
	await _greet(place, place.display_name)
	await _counter(id, place, delivered)
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


## The weigh station's counter, in a few words.
func _weigh_in_note() -> String:
	if GameState.active_job() == null:
		return "Nothing in the back to weigh."
	if float(GameState.rig.get("weighed", 0.0)) > 0.0:
		return "This load's already weighed and certified."
	return "Put the load on the scale. Legal weight: a weigh slip worth +%d%% on delivery. Overweight: a %d %s fine." % [
			roundi(GameState.tuning.weigh_slip_bonus * 100.0), GameState.tuning.overweight_fine, GameState.names.currency_short]


## Onto the scale: certified (a weigh slip bonus at delivery), or overweight
## for this rig (a small fine; it goes on the tab if you're short).
func _weigh_in(tree: SceneTree) -> void:
	var job := GameState.active_job()
	if job == null:
		await MenuPanel.ask(tree, "WEIGH-IN", "\"Nothing on the scale but you, miss. Have a nice day. Slowly.\"", [{"text": "OKAY"}])
		return
	if float(GameState.rig.get("weighed", 0.0)) > 0.0:
		await MenuPanel.ask(tree, "WEIGH-IN", "\"Already certified. I remember. I remember everything. Slowly.\"", [{"text": "OKAY"}])
		return
	var rating := _ship.ship_data.load_rating
	var weight := "%s on a rig rated for %s." % [HudWidget.tons_text(job.weight, true), HudWidget.tons_text(rating, true)]
	if rating > 0.0 and job.weight > rating:
		var fine := GameState.tuning.overweight_fine
		var paid := mini(fine, GameState.credits)
		if paid > 0:
			GameState.spend(paid)
		GameState.tab += fine - paid
		GameState.rig["weighed"] = 0.5  # (Weighed and fined: no slip, but no second fine either.)
		await MenuPanel.ask(tree, "OVERWEIGHT", weight + "\n\"That's over, miss. %d %s fine. Drive gently, it'll stop like a planet.\"" % [fine, GameState.names.currency_short], [{"text": "...FAIR"}])
		return
	GameState.rig["weighed"] = 1.0
	GameState.set_flag("weighed_a_load")
	Sfx.play("course_set")
	await MenuPanel.ask(tree, "CERTIFIED", weight + "\n\"All legal. Here's your weigh slip: the client pays a little extra for paperwork. Everybody loves paperwork.\"", [{"text": "STAMP IT"}])


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
		_hud.comm.call_in(place.host, place.host_line(int(GameState.visits.get(place.id, 1)), _rng), ChatterSet.Situation.DOCKING, true, PackedStringArray(), true)
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
		if place.kind == PlaceData.Kind.DROP_OFF or not GameState.board_jobs(id).is_empty():
			options.append({"text": "LOOK FOR A LOAD", "description": "See what needs hauling from here."})
			actions.append("job_board")
		if "snacks" in place.services:
			options.append({"text": "MOE'S JERKY", "detail": "%d %s" % [JERKY_PRICE, GameState.names.currency_short],
					"description": "Chewy. Calming. Steadier hands under boost for the rest of this trip."})
			actions.append("snack")
		if "meal" in place.services:
			options.append({"text": "BLUE-PLATE SPECIAL", "detail": "%d %s" % [GameState.tuning.diner_meal_price, GameState.names.currency_short],
					"description": "Meatloaf-ish, a slice of pie, bottomless coffee. Steadier hands for the rest of this trip."})
			actions.append("meal")
		if "weigh" in place.services:
			options.append({"text": "WEIGH-IN", "description": _weigh_in_note()})
			actions.append("weigh")
		if "souvenir" in place.services:
			options.append({"text": "SOUVENIR KEYCHAIN", "detail": "%d %s" % [KEYCHAIN_PRICE, GameState.names.currency_short],
					"description": "For the logbook. A tiny sloth holding a tiny fuel nozzle."})
			actions.append("souvenir")
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
			await HubServices.fuel(tree, pumps, "Come back... whenever.", place.fuel_price_factor)
		elif action == "snack":
			if GameState.spend(JERKY_PRICE):
				GameState.rig["snack"] = 1.0
				await MenuPanel.ask(tree, "MOE'S JERKY", "You chew. And chew. A deep calm settles over you. Your hands feel... steady.", [{"text": "*CHEW*"}])
			else:
				Sfx.play("nope")
				await MenuPanel.ask(tree, "NOT ENOUGH", "Moe... understands... completely.", [{"text": "OKAY"}])
		elif action == "meal":
			if GameState.spend(GameState.tuning.diner_meal_price):
				GameState.rig["snack"] = 1.0
				GameState.set_flag("ate_at_the_diner")
				await MenuPanel.ask(tree, "BLUE-PLATE SPECIAL", "It's warm. It's brown. It's perfect. The coffee keeps coming. Your hands feel steady.", [{"text": "THANKS, HON"}])
			else:
				Sfx.play("nope")
				await MenuPanel.ask(tree, "NOT ENOUGH", "\"Coffee's on the house, sugar. The pie isn't.\"", [{"text": "OKAY"}])
		elif action == "weigh":
			await _weigh_in(tree)
		elif action == "souvenir":
			if GameState.spend(KEYCHAIN_PRICE):
				var first := GameState.log_sight("gas_n_go_keychain")
				await MenuPanel.ask(tree, "SOUVENIR", "A tiny plastic sloth. It goes on your keys." + (" (Added to your logbook.)" if first else " You collect them now, apparently."), [{"text": "CUTE"}])
		else:
			break
	tree.paused = false


# --- Solar systems ------------------------------------------------------------------

## A solar system's name, from its id.
func _system_name(id: String) -> String:
	for system in systems:
		if system.id == id:
			return system.display_name
	return "space"


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
	_motes.tint = signature
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
			_hud.show_banner("NOW ENTERING " + _system_name(now).to_upper(), 4.0)
			Radio.dj_react("new_system", {"system": _system_name(now)})
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
	# The DJ notices when you fly into a storm.
	if storm > 0.3 and not _in_storm:
		_in_storm = true
		Radio.dj_react("storm", {"system": _system_name(current_system())})
	elif storm < 0.05:
		_in_storm = false
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
	Radio.dj_react("ticket")


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


# --- The cinematic camera -----------------------------------------------------------

func _make_cinema() -> void:
	_cinema = CinemaCamera.new()
	_cinema.name = "CinemaCamera"
	_cinema.target = _ship
	_cinema.near = 0.5
	_cinema.far = _chase_camera.far
	$World.add_child(_cinema)
	_letterbox = CanvasLayer.new()
	_letterbox.layer = 4  # Over the 3D view, under the HUD (so calls still show).
	_letterbox.visible = false
	var bars := Control.new()
	bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.draw.connect(func() -> void:
		var bar := bars.size.y * GameState.tuning.cinema_letterbox
		bars.draw_rect(Rect2(0.0, 0.0, bars.size.x, bar), Color.BLACK)
		bars.draw_rect(Rect2(0.0, bars.size.y - bar, bars.size.x, bar), Color.BLACK))
	bars.resized.connect(bars.queue_redraw)
	_letterbox.add_child(bars)
	add_child(_letterbox)


## Whether the cinematic camera has the view.
func in_cinema() -> bool:
	return _cinema != null and _cinema.current


## V / R3: chase cam -> director -> free camera -> chase cam. Only while an
## autopilot drives (someone has to watch the road).
func _next_cinema_mode() -> void:
	if not in_cinema():
		if _ship.cruise == null and _docking_at.is_empty():
			_hud.show_banner("SET A COURSE FIRST (M)", 2.0)
			return
		start_cinema()
	elif _cinema.mode == CinemaCamera.Mode.DIRECTOR:
		_cinema.take_over()
		_hud.show_banner("FREE CAMERA: STICK / MOUSE TO LOOK, W/S TO ZOOM", 3.0)
	else:
		_end_cinema()


## Hands the view to the cinematic camera's director. Public for the tests.
func start_cinema() -> void:
	if in_cinema():
		return
	if _in_cockpit:
		_set_cockpit_view(false)  # The rig has to be visible from outside.
	_ship.controls.hands_free = true  # Looking around can't knock off the autopilot.
	_cinema.start()
	_letterbox.visible = true
	_hud.set_cinema(true)
	_hud.show_banner("CINEMA CAM: TOUCH THE STICK TO LOOK AROUND. V: BACK", 3.0)


## Back to the chase camera (if the cinematic one was on).
func _end_cinema() -> void:
	if not in_cinema():
		return
	_cinema.clear_current(false)
	_chase_camera.make_current()
	_chase_camera.snap_behind_target()
	_letterbox.visible = false
	_hud.set_cinema(false)
	if not _in_cabin:
		_ship.controls.hands_free = false


## Hides the mouse and locks it to the window, so moving it steers the ship.
## Grabs the mouse for steering, except while the autopilot's driving:
## WATCH MODE. Then the mouse stays free, so you can leave the game up on
## screen and get on with other things on your computer while she trucks
## along (the game keeps running when it's not the window in front). It
## grabs the mouse again when you take the wheel back.
func _capture_mouse() -> void:
	if _ship.cruise != null or not get_window().has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Pause menu: hop back to where you launched (tanks and cargo as they are).
func _back_to_launch_point() -> void:
	_end_cinema()
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
