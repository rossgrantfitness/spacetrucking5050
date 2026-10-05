class_name FlightHUD
extends CanvasLayer
## The flight HUD, in the style of late-90s PlayStation racers (Wipeout).
##
## Every piece is drawn into a small low-resolution picture ("Pixels", about
## 360 rows tall, see `hud_rows` in tuning.tres) that's blown up to fill the
## screen with crisp square pixels, so the chunky pixel font looks
## period-correct at any screen size. It also redraws a little slower than
## the game (`hud_frame_rate`) and its numbers tick over in jumps
## (`hud_number_rate`), the way old HUDs did.
##
## The pieces (each its own small script in res://scenes/ui/hud/):
##   corners:   radio ticker (top left), nav tape + ETA (top), cargo + pay
##              (top right), speed + boost (bottom left), radar globe
##              (bottom middle), fuel + economy + hull (bottom right)
##   middle:    flight marker, mouse ring, status lights (left edge)
##   pop-ins:   comm calls, docking brackets, rush timer, ship ID labels,
##              jump charge, and a banner for messages ("AUTOPILOT DOCKING")
##
## The player can hide it all from the pause menu or with H / D-pad down
## (comm calls still pop in). In cockpit view the bottom row steps aside,
## because the dashboard has its own gauges.


## What a radar contact is.
enum Kind { ROCK, SHIP, STATION }

## The rig we're flying, and where we're headed (and its name). The job
## being hauled comes from GameState.
var ship: Ship
var destination: Node3D
var destination_name: String = ""
## The solar system's signature color, used for the HUD's frames.
var tint := Color.WHITE
## Seconds since the flight started (for blinking).
var time: float = 0.0
## Lights up every warning light and gauge, so the look can be checked
## (F9 in the flight sandbox).
var demo: bool = false
## Everything near the ship this HUD frame: rocks, traffic, the destination.
## Each is {position, radius, kind, label}. Shared by the radar, the
## proximity light and the ID labels.
var contacts: Array[Dictionary] = []
## How many real screen pixels wide one HUD pixel is.
var pixel_scale: float = 2.0

var _in_cockpit: bool = false
var _in_cabin: bool = false
var _in_cinema: bool = false
var _frame_clock: float = 0.0
var _number_clock: float = 0.0
var _widgets: Array[HudWidget] = []

@onready var _pixels: SubViewport = $Pixels
@onready var _screen: TextureRect = $Screen
@onready var comm: CommPortrait = $Pixels/CommPortrait


func _ready() -> void:
	_screen.texture = _pixels.get_texture()
	for child in _pixels.get_children():
		if child is HudWidget:
			(child as HudWidget).hud = self
			_widgets.append(child)
	get_viewport().size_changed.connect(_fit)
	Events.settings_changed.connect(_refresh)
	_fit()
	_refresh()


## Tells the HUD which ship to show, where it's headed (and that place's
## name), and the solar system's color.
func setup(new_ship: Ship, new_destination: Node3D, new_destination_name: String, system_tint: Color) -> void:
	ship = new_ship
	destination = new_destination
	destination_name = new_destination_name
	tint = system_tint


## Pops up a message in the middle of the top of the screen for `seconds`
## (0 = until another message replaces it).
func show_banner(text: String, seconds: float) -> void:
	($Pixels/Banner as Banner).show_text(text, seconds)


func set_cockpit_view(in_cockpit: bool) -> void:
	_in_cockpit = in_cockpit
	_refresh()


## Walking around the cabin: only comm calls and messages show.
func set_cabin(in_cabin: bool) -> void:
	_in_cabin = in_cabin
	_refresh()


## Watching through the cinematic camera: the HUD tucks away like in the
## cabin, so only comm calls and messages show.
func set_cinema(in_cinema: bool) -> void:
	_in_cinema = in_cinema
	_refresh()


## Where a spot in the 3D world appears on the HUD, in HUD pixels.
func to_hud(world: Vector3) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.ZERO
	var visible_size := get_viewport().get_visible_rect().size
	return camera.unproject_position(world) * Vector2(_pixels.size) / visible_size


## Whether a spot in the 3D world is behind the camera (so not on screen).
func is_behind(world: Vector3) -> bool:
	var camera := get_viewport().get_camera_3d()
	return camera == null or camera.is_position_behind(world)


## The size of the HUD picture, in HUD pixels.
func hud_size() -> Vector2:
	return Vector2(_pixels.size)


## How close the nearest rock or ship is, to its surface, in meters (INF if
## nothing is on the radar).
func nearest_obstacle() -> float:
	var nearest := INF
	for contact in contacts:
		if contact["kind"] != Kind.STATION:
			nearest = minf(nearest, ship.global_position.distance_to(contact["position"]) - contact["radius"])
	return maxf(nearest, 0.0)


func _process(delta: float) -> void:
	time += delta
	var tuning := GameState.tuning
	_frame_clock += delta
	_number_clock += delta
	if _frame_clock < 1.0 / tuning.hud_frame_rate:
		return
	var step := _frame_clock
	_frame_clock = 0.0
	var numbers_due := _number_clock >= 1.0 / tuning.hud_number_rate
	if numbers_due:
		_number_clock = 0.0
	_gather_contacts()
	for widget in _widgets:
		widget.hud_step(step, numbers_due)
		widget.queue_redraw()
	# Only repaint the HUD picture on HUD frames.
	_pixels.render_target_update_mode = SubViewport.UPDATE_ONCE


## Finds the rocks and ships within radar range, plus the destination.
func _gather_contacts() -> void:
	contacts.clear()
	if ship == null:
		return
	var here := ship.global_position
	var reach := GameState.tuning.radar_range
	for field: AsteroidField in get_tree().get_nodes_in_group("asteroid_fields"):
		for rock in field.rocks_within(here, reach):
			contacts.append({"position": Vector3(rock.x, rock.y, rock.z), "radius": rock.w, "kind": Kind.ROCK, "label": ""})
	# Traffic, plus sights on the road that want to be on the radar (big
	# ships, convoys, derelicts, the cops' radar buoy...).
	for other: Node3D in get_tree().get_nodes_in_group("traffic"):
		if here.distance_to(other.global_position) > reach:
			continue
		if other is TrafficShip:
			var traffic := other as TrafficShip
			contacts.append({"position": traffic.global_position, "radius": traffic.hull_size.length() * 0.5,
					"kind": Kind.SHIP, "label": traffic.id_label})
		elif other is RoadsideThing:
			var thing := other as RoadsideThing
			contacts.append({"position": thing.global_position, "radius": thing.contact_radius,
					"kind": Kind.SHIP, "label": thing.id_label})
	if destination != null:
		contacts.append({"position": destination.global_position, "radius": 0.0, "kind": Kind.STATION,
				"label": destination_name})


## Sizes the HUD picture to the window: as close to `hud_rows` rows as
## whole-pixel scaling allows, so every HUD pixel is a crisp square.
func _fit() -> void:
	var window := Vector2(get_window().size)
	pixel_scale = maxf(1.0, roundf(window.y / GameState.tuning.hud_rows))
	_pixels.size = Vector2i((window / pixel_scale).ceil())
	_pixels.render_target_update_mode = SubViewport.UPDATE_ONCE


func _refresh() -> void:
	for widget in _widgets:
		widget.visible = (Settings.show_hud or widget.always_shown) and not (_in_cockpit and widget.bottom_row) \
				and (widget.always_shown or not (_in_cabin or _in_cinema))
