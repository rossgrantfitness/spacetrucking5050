extends SceneTree
## Builds the placeholder 3D models out of simple chunky shapes, and saves
## them as ordinary scenes you can open in the editor:
##     res://scenes/flight/ShipVisual.tscn                     - your rig
##     res://scenes/flight/traffic/CapsuleHaulerVisual.tscn   - traffic
##     res://scenes/flight/traffic/BoxHaulerVisual.tscn       - traffic
##     res://scenes/flight/Station.tscn                        - the truck stop
##     res://scenes/flight/CockpitInterior.tscn               - inside the cab
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_placeholder_models.gd
##
## Careful: running it again OVERWRITES those scenes. If you've changed them
## by hand in the editor, don't re-run this (or copy your changes into this
## script first). Real art will replace these scenes eventually anyway.
##
## Every surface uses the PS1 shader (res://shaders/psx_surface.gdshader) with
## a tiny texture tinted by a paint color, so it wobbles and swims like 1997.
##
## Directions: in Godot, -Z is "forward", +Y is up, +X is right.


const SURFACE_SHADER := preload("res://shaders/psx_surface.gdshader")
## The hub rooms' pre-rendered sets use this one (lit per pixel, see build_hub.gd).
const SET_SHADER := preload("res://shaders/set_surface.gdshader")
## "No texture" still gets this: flat paint with a little hand-painted
## mottling, so nothing is ever a perfectly flat color (that's what made it
## look like early 3D).
const PAINT_GRAIN := preload("res://textures/generated/paint_grain.png")
const HULL := preload("res://textures/generated/hull_panels.png")
const VENTS := preload("res://textures/generated/vents.png")
const HAZARD := preload("res://textures/generated/hazard_stripes.png")
const WINDOWS := preload("res://textures/generated/station_windows.png")
const CONTAINER := preload("res://textures/generated/container.png")
const CHEVRONS := preload("res://textures/generated/chevrons.png")
const FUZZ := preload("res://textures/generated/fuzz.png")
const PHOTO := preload("res://textures/generated/photo.png")
# Scripts are loaded in _initialize (not preloaded) because EngineTrail uses
# autoloads, which don't exist yet while this tool script is being compiled.
const BLINKER_SCRIPT_PATH := "res://scenes/flight/Blinker.gd"
const TRAIL_SCRIPT_PATH := "res://scenes/flight/EngineTrail.gd"
const FLARE_SCRIPT_PATH := "res://scenes/flight/EngineFlare.gd"

## A rotation that turns a cylinder (normally standing up along Y) to lie
## along Z, front to back.
const ALONG_Z := Vector3(PI / 2.0, 0.0, 0.0)
## Hull panel texture size: one 64-pixel texture covers 4 x 4 meters, so each
## panel is a meter across.
const HULL_SCALE := Vector2(0.25, 0.25)

## Paint jobs. Each truck model can be built in any of these.
const RIG_PAINT := {
	"body": Color(0.42, 0.43, 0.5), "pods": Color(0.8, 0.82, 0.86), "trim": Color(1.0, 0.8, 0.12),
	"dark": Color(0.2, 0.2, 0.25), "glass": Color(1.0, 0.68, 0.22), "engine": Color(1.0, 0.55, 0.3),
}
## Cargo container colors, picked in turn for each container on the rack.
const CONTAINER_COLORS: Array[Color] = [
	Color(0.8, 0.38, 0.22), Color(0.22, 0.56, 0.6), Color(0.9, 0.7, 0.22), Color(0.9, 0.86, 0.78),
	Color(0.52, 0.32, 0.64), Color(0.76, 0.22, 0.24), Color(0.3, 0.62, 0.38), Color(0.9, 0.55, 0.62)]
const CAPSULE_PAINTS: Array[Dictionary] = [
	{"body": Color(0.8, 0.45, 0.26), "band": Color(0.97, 0.9, 0.74), "dark": Color(0.24, 0.2, 0.22), "engine": Color(0.45, 0.85, 1.0)},
	{"body": Color(0.4, 0.66, 0.58), "band": Color(1.0, 0.78, 0.35), "dark": Color(0.18, 0.22, 0.26), "engine": Color(1.0, 0.5, 0.75)},
	{"body": Color(0.86, 0.72, 0.32), "band": Color(0.55, 0.32, 0.6), "dark": Color(0.22, 0.2, 0.26), "engine": Color(0.55, 1.0, 0.5)},
]
const BOX_PAINTS: Array[Dictionary] = [
	{"cab": Color(0.86, 0.2, 0.26), "box": Color(0.18, 0.56, 0.62), "stripe": Color(0.98, 0.92, 0.78), "engine": Color(1.0, 0.55, 0.3)},
	{"cab": Color(0.25, 0.42, 0.85), "box": Color(0.95, 0.58, 0.22), "stripe": Color(0.98, 0.92, 0.78), "engine": Color(0.45, 0.85, 1.0)},
	{"cab": Color(0.55, 0.3, 0.7), "box": Color(0.92, 0.88, 0.8), "stripe": Color(1.0, 0.45, 0.65), "engine": Color(1.0, 0.5, 0.75)},
]

var _blinker_script: Script
var _trail_script: Script
var _flare_script: Script
# Identical materials and boxes are made once and shared, which keeps the
# saved scenes small and cheap to draw.
var _material_cache := {}
## On while building ships: hull paint is one solid color per panel with a
## few painted details (seams, trim, bolts) instead of a tiled hull texture.
## See "Panel decals" in shaders/painted_edges.gdshaderinc.
var _ship_mode := false
var _box_cache := {}
## Material -> its twin with painted edges switched on (for boxes).
var _edged_cache := {}


# _initialize runs once the game's autoloads exist; the trail script needs them.
func _initialize() -> void:
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_trail_script = load(TRAIL_SCRIPT_PATH)
	_flare_script = load(FLARE_SCRIPT_PATH)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/flight/traffic"))
	_ship_mode = true
	_save(_build_rig(), "res://scenes/flight/ShipVisual.tscn")
	_save(_build_capsule_hauler("CapsuleHaulerVisual", CAPSULE_PAINTS[0], true), "res://scenes/flight/traffic/CapsuleHaulerVisual.tscn")
	_save(_build_box_hauler("BoxHaulerVisual", BOX_PAINTS[1], true), "res://scenes/flight/traffic/BoxHaulerVisual.tscn")
	_ship_mode = false
	_save(_build_station(), "res://scenes/flight/Station.tscn")
	_save(_build_cockpit(), "res://scenes/flight/CockpitInterior.tscn")
	quit()


# --- Your rig: a long-haul cargo hauler -------------------------------------
# Half space truck, half the developer's "BB 42 cargo aircraft" reference: a
# truck cab up front (amber cockpit glass, headlights, grille, chrome exhaust
# stacks, crew quarters on top for 4-5 people), a rack of eight colorful
# cargo containers behind it, and a heavy engine block with three engines.
# About 34 m long and 15 m wide.

func _build_rig() -> Node3D:
	var ship := Node3D.new()
	ship.name = "ShipVisual"
	var p := RIG_PAINT
	var body := _paint(p.body)
	var pods := _paint(p.pods)
	var trim := _paint(p.trim, null)
	var dark := _paint(p.dark)
	var chrome := _paint(Color(0.85, 0.87, 0.92), null)

	# The cab: nose, then the main cab section.
	_loft(ship, "Nose", Vector3(0.0, -0.6, -18.0), Vector2(3.6, 2.4), Vector3(0.0, 0.0, -14.0), Vector2(6.4, 4.4), body)
	_loft(ship, "Cab", Vector3(0.0, 0.0, -14.0), Vector2(6.4, 4.4), Vector3(0.0, 0.2, -7.0), Vector2(7.0, 4.8), body)
	_loft(ship, "Canopy", Vector3(0.0, 1.0, -16.6), Vector2(2.4, 0.6), Vector3(0.0, 2.2, -12.6), Vector2(5.0, 1.4), _glow(p.glass, 1.0, Color(0.35, 0.2, 0.05)))
	# Truck face: grille, headlights and a chrome bumper.
	_box(ship, "Grille", Vector3(2.4, 1.0, 0.12), Vector3(0.0, -0.9, -18.04), _paint(Color(1, 1, 1), VENTS, Vector2(0.5, 0.5)))
	_box(ship, "Bumper", Vector3(4.2, 0.5, 0.6), Vector3(0.0, -1.85, -17.0), chrome)
	for side: float in [-1.0, 1.0]:
		_box(ship, "Headlight", Vector3(0.55, 0.35, 0.12), Vector3(1.4 * side, -0.25, -18.04), _glow(Color(1.0, 0.95, 0.8), 1.4))
		# Chrome exhaust stacks behind the cab, a homage to Earth trucks.
		_cylinder(ship, "ExhaustStack", 0.28, 4.4, Vector3(3.15 * side, 2.6, -7.6), chrome, Vector3.ZERO, 8)
		_cylinder(ship, "StackCap", 0.36, 0.3, Vector3(3.15 * side, 4.9, -7.6), dark, Vector3.ZERO, 8)
		_box(ship, "Pinstripe", Vector3(0.1, 0.22, 8.5), Vector3(3.43 * side, -0.5, -10.6), trim)
		_decal(ship, "HullNumber", "5050", Vector3(3.47 * side, 0.6, -9.6), side)
	# Crew quarters on the cab roof, with little warm windows: somebody lives here.
	_loft(ship, "QuartersFront", Vector3(0.0, 2.5, -12.4), Vector2(4.0, 0.6), Vector3(0.0, 3.2, -10.0), Vector2(5.2, 1.8), pods)
	_loft(ship, "Quarters", Vector3(0.0, 3.2, -10.0), Vector2(5.2, 1.8), Vector3(0.0, 3.2, -6.6), Vector2(5.2, 1.8), pods)
	var cabin_light := _glow(Color(1.0, 0.82, 0.45), 1.3)
	for side: float in [-1.0, 1.0]:
		for i in 3:
			_box(ship, "CabinWindow", Vector3(0.1, 0.45, 0.7), Vector3(2.61 * side, 3.25, -9.4 + i * 1.1), cabin_light)

	# The cargo rack: a spine with eight containers, framed front and back.
	_box(ship, "Spine", Vector3(2.0, 2.0, 18.0), Vector3(0.0, 0.0, 1.5), dark)
	_box(ship, "RackFront", Vector3(7.6, 6.8, 0.6), Vector3(0.0, 0.65, -6.1), dark)
	_box(ship, "RackFrontStripe", Vector3(7.64, 0.7, 0.64), Vector3(0.0, 3.6, -6.1), _hazard(1.0))
	var slot := 0
	for z: float in [-2.0, 5.4]:
		for y: float in [-0.9, 2.2]:
			for side: float in [-1.0, 1.0]:
				var paint := _paint(CONTAINER_COLORS[slot % CONTAINER_COLORS.size()], CONTAINER, Vector2(0.3, 0.33))
				_box(ship, "Container", Vector3(3.2, 3.0, 7.2), Vector3(1.7 * side, y, z), paint)
				slot += 1
	for z: float in [1.7, 9.4]:
		_box(ship, "RackClamp", Vector3(7.6, 0.5, 0.5), Vector3(0.0, 3.85, z), dark)
		_box(ship, "RackClampLow", Vector3(7.6, 0.5, 0.5), Vector3(0.0, -2.55, z), dark)

	# The engine block: one big main engine and two silver side pods.
	_loft(ship, "EngineBlock", Vector3(0.0, 0.6, 9.6), Vector2(7.6, 6.4), Vector3(0.0, 0.6, 13.5), Vector2(6.4, 5.2), body)
	_engine(ship, Vector3(0.0, 0.6, 13.55), Vector2(3.4, 2.6), p.engine, 1.0, true)
	for side: float in [-1.0, 1.0]:
		var x := 5.4 * side
		_loft(ship, "PodIntake", Vector3(x, 0.4, 4.0), Vector2(3.2, 3.2), Vector3(x, 0.4, 6.0), Vector2(3.8, 3.8), pods)
		_loft(ship, "Pod", Vector3(x, 0.4, 6.0), Vector2(3.8, 3.8), Vector3(x, 0.4, 14.0), Vector2(3.8, 3.8), pods)
		_loft(ship, "PodExhaust", Vector3(x, 0.4, 14.0), Vector2(3.8, 3.8), Vector3(x, 0.4, 15.5), Vector2(3.2, 3.2), dark)
		_box(ship, "IntakeGrille", Vector3(2.4, 2.4, 0.15), Vector3(x, 0.4, 3.95), _paint(Color(1, 1, 1), VENTS, Vector2(0.5, 0.5)))
		_box(ship, "PodTrim", Vector3(0.3, 0.1, 9.0), Vector3(x, 2.33, 10.0), trim)
		_box(ship, "PodPylon", Vector3(2.0, 0.8, 4.0), Vector3(3.9 * side, 0.4, 11.5), dark)
		_engine(ship, Vector3(x, 0.4, 15.55), Vector2(2.4, 2.4), p.engine, 1.0, true)
		# Radiator fins on top of the engine block.
		_box(ship, "Radiator", Vector3(0.25, 1.8, 3.2), Vector3(1.6 * side, 4.6, 11.3), pods)
		# Nav lights: red on the left, green on the right, like real aircraft.
		var light_color := Color(1.0, 0.15, 0.15) if side < 0.0 else Color(0.2, 1.0, 0.35)
		var nav := _box(ship, "NavLight", Vector3(0.35, 0.35, 0.35), Vector3(x + 1.95 * side, 0.4, 13.0), _glow(light_color, 1.6))
		nav.set_script(_blinker_script)
		nav.set("offset", 0.0 if side < 0.0 else 0.5)
	_cylinder(ship, "Antenna", 0.08, 3.0, Vector3(0.0, 5.4, 12.0), chrome, Vector3.ZERO, 5)
	var beacon := _box(ship, "Beacon", Vector3(0.5, 0.35, 0.5), Vector3(0.0, 4.25, -8.6), _glow(Color(1.0, 0.45, 0.1), 1.8))
	beacon.set_script(_blinker_script)
	beacon.set("offset", 0.25)
	return ship


# --- Traffic: the capsule hauler --------------------------------------------
# From the developer's capsule-ship sketch: a long, rounded fuel-tank body
# with a bubble cockpit and four boxy engine pods on stubby pylons. ~34 m.

func _build_capsule_hauler(node_name: String, p: Dictionary, with_trails: bool) -> Node3D:
	var ship := Node3D.new()
	ship.name = node_name
	var body := _paint(p.body)
	var band := _paint(p.band)
	var dark := _paint(p.dark)
	var round_ish := 0.42  # Big corner cuts make the 8-sided body read as round.
	_loft(ship, "NoseCap", Vector3(0.0, 0.0, -17.0), Vector2(3.4, 3.2), Vector3(0.0, 0.0, -13.0), Vector2(7.0, 6.6), body, round_ish)
	_loft(ship, "Body", Vector3(0.0, 0.0, -13.0), Vector2(7.0, 6.6), Vector3(0.0, 0.0, 12.0), Vector2(7.0, 6.6), body, round_ish)
	_loft(ship, "TailCap", Vector3(0.0, 0.0, 12.0), Vector2(7.0, 6.6), Vector3(0.0, 0.0, 16.0), Vector2(4.0, 3.8), dark, round_ish)
	for z: float in [-7.0, 3.0]:
		_loft(ship, "Band", Vector3(0.0, 0.0, z - 1.0), Vector2(7.4, 7.0), Vector3(0.0, 0.0, z + 1.0), Vector2(7.4, 7.0), band, round_ish)
	_loft(ship, "Bubble", Vector3(0.0, 0.9, -17.3), Vector2(2.0, 1.2), Vector3(0.0, 1.5, -14.2), Vector2(3.4, 2.2), _glow(Color(0.5, 0.9, 1.0), 0.8, Color(0.1, 0.2, 0.3)), 0.4)
	_cylinder(ship, "Antenna", 0.1, 4.0, Vector3(0.0, 5.0, 6.0), dark, Vector3.ZERO, 5)
	for side: float in [-1.0, 1.0]:
		for z: float in [-8.0, 8.0]:
			var x := 6.0 * side
			_box(ship, "Pylon", Vector3(3.0, 0.7, 2.0), Vector3(3.8 * side, -1.0, z), dark)
			_loft(ship, "EnginePod", Vector3(x, -1.0, z - 3.5), Vector2(2.4, 2.4), Vector3(x, -1.0, z + 3.0), Vector2(2.8, 2.8), band)
			_engine(ship, Vector3(x, -1.0, z + 3.05), Vector2(2.0, 2.0), p.engine, 1.0 if with_trails else 0.3, with_trails and z > 0.0)
	return ship


# --- Traffic: the box hauler ------------------------------------------------
# A classic: a truck cab pulling a big cargo container through space. (This
# was the very first placeholder rig.) ~20 m.

func _build_box_hauler(node_name: String, p: Dictionary, with_trails: bool) -> Node3D:
	var ship := Node3D.new()
	ship.name = node_name
	var cab := _paint(p.cab)
	var stripe := _paint(p.stripe)
	var chrome := _paint(Color(0.82, 0.84, 0.9))
	var dark := _paint(Color(0.2, 0.2, 0.26))
	var box := _paint(p.box)
	var glass := _glow(Color(0.25, 0.6, 0.85), 0.5, Color(0.1, 0.16, 0.3))

	_box(ship, "Cab", Vector3(4.2, 3.4, 4.0), Vector3(0.0, 0.5, -6.6), cab)
	_box(ship, "CabStripe", Vector3(4.24, 0.35, 4.04), Vector3(0.0, -0.55, -6.6), stripe)
	_box(ship, "Bumper", Vector3(4.5, 0.9, 0.7), Vector3(0.0, -0.95, -8.75), chrome)
	_box(ship, "Grille", Vector3(2.6, 1.0, 0.15), Vector3(0.0, -0.05, -8.65), _paint(Color(0.9, 0.9, 0.95), VENTS, Vector2(0.6, 0.6)))
	for side: float in [-1.0, 1.0]:
		_box(ship, "Headlight", Vector3(0.7, 0.45, 0.12), Vector3(1.55 * side, -0.1, -8.66), _glow(Color(1.0, 0.95, 0.8), 1.4))
		_box(ship, "SideWindow", Vector3(0.1, 1.0, 1.6), Vector3(2.11 * side, 1.3, -7.4), glass)
		# Chrome exhaust stacks, a little homage to the trucks back on Earth.
		_cylinder(ship, "Exhaust", 0.2, 3.6, Vector3(2.3 * side, 1.6, -5.0), chrome)
	_box(ship, "Windshield", Vector3(3.7, 1.25, 0.12), Vector3(0.0, 1.3, -8.62), glass)
	for i in 5:
		_box(ship, "RoofLight", Vector3(0.35, 0.22, 0.3), Vector3(-1.4 + 0.7 * i, 2.31, -8.25), _glow(Color(1.0, 0.72, 0.25), 1.5))

	_box(ship, "Hitch", Vector3(2.2, 1.4, 1.6), Vector3(0.0, -0.2, -4.0), dark)
	_box(ship, "Container", Vector3(4.5, 4.1, 11.6), Vector3(0.0, 0.7, 2.3), box)
	_box(ship, "ContainerBand", Vector3(4.56, 0.45, 11.66), Vector3(0.0, 1.6, 2.3), stripe)
	_box(ship, "RearBumper", Vector3(4.6, 0.55, 0.45), Vector3(0.0, -1.15, 8.3), _hazard(1.2))
	_box(ship, "EngineMount", Vector3(3.8, 1.6, 1.0), Vector3(0.0, 0.3, 8.6), dark)
	for side: float in [-1.0, 1.0]:
		_loft(ship, "Engine", Vector3(1.35 * side, 0.3, 8.2), Vector2(1.7, 1.7), Vector3(1.35 * side, 0.3, 10.6), Vector2(1.9, 1.9), dark, 0.3)
		_engine(ship, Vector3(1.35 * side, 0.3, 10.65), Vector2(1.4, 1.4), p.engine, 1.0 if with_trails else 0.3, with_trails)
	return ship


# --- The truck-stop station -------------------------------------------------
# Its docking face (the front) points toward +Z, where the player arrives from.
# Out front, below the docking bay, there's a parking deck full of trucks.

func _build_station() -> Node3D:
	var station := Node3D.new()
	station.name = "Station"

	var hull := _paint(Color(0.74, 0.72, 0.8), HULL, Vector2(16.0, 10.0), false)
	var accent := _paint(Color(0.42, 0.28, 0.62), HULL, Vector2(16.0, 1.0), false)
	var strut := _paint(Color(0.42, 0.28, 0.62), HULL, Vector2(0.05, 0.05))
	var dark := _paint(Color(0.16, 0.15, 0.22), HULL, Vector2(0.05, 0.05))
	var body := StaticBody3D.new()
	body.name = "Collision"
	station.add_child(body, true)

	# The central hub.
	var hub := _cylinder(station, "Hub", 70.0, 260.0, Vector3.ZERO, hull, ALONG_Z, 16)
	_add_collision(body, hub)
	for band_z: float in [-90.0, -30.0, 30.0, 90.0]:
		_cylinder(station, "HubBand", 73.0, 14.0, Vector3(0.0, 0.0, band_z), accent, ALONG_Z, 16)
	_add_collision(body, _cylinder(station, "DockingFace", 56.0, 8.0, Vector3(0.0, 0.0, 133.0), dark, ALONG_Z, 16))
	var bay_light := TorusMesh.new()
	bay_light.inner_radius = 30.0
	bay_light.outer_radius = 38.0
	bay_light.rings = 24
	bay_light.ring_segments = 6
	bay_light.material = _glow(Color(0.3, 0.95, 1.0), 1.5)
	_mesh(station, "DockingLights", bay_light, Vector3(0.0, 0.0, 138.0), ALONG_Z)
	var hazard := _hazard(0.06)
	for frame_part: Array in [
			[Vector3(100.0, 10.0, 6.0), Vector3(0.0, 46.0, 138.0)],
			[Vector3(100.0, 10.0, 6.0), Vector3(0.0, -46.0, 138.0)],
			[Vector3(10.0, 82.0, 6.0), Vector3(-46.0, 0.0, 138.0)],
			[Vector3(10.0, 82.0, 6.0), Vector3(46.0, 0.0, 138.0)]]:
		_box(station, "DockingFrame", frame_part[0], frame_part[1], hazard)

	# The big ring, wrapped in rows of little windows (most lit, a few dark),
	# with four spokes holding it to the hub.
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 300.0
	ring_mesh.outer_radius = 360.0
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 8
	ring_mesh.material = _windows(Vector2(24.0, 1.5))
	_mesh(station, "Ring", ring_mesh, Vector3.ZERO, ALONG_Z)
	_add_ring_collision(body, 330.0, 30.0, 24)
	for i in 4:
		var angle := PI / 4.0 + i * PI / 2.0
		var spoke := _box(station, "Spoke", Vector3(18.0, 236.0, 18.0), Vector3(cos(angle), sin(angle), 0.0) * 187.0, strut)
		spoke.rotation = Vector3(0.0, 0.0, angle - PI / 2.0)
		_add_collision(body, spoke)
	for i in 4:
		var angle := i * PI / 2.0
		var beacon := _box(station, "Beacon", Vector3(12.0, 12.0, 12.0), Vector3(cos(angle), sin(angle), 0.0) * 366.0, _glow(Color(1.0, 0.2, 0.2), 1.8))
		beacon.set_script(_blinker_script)
		beacon.set("offset", i * 0.25)

	# Chevron boards either side of the docking bay, like racetrack barriers.
	for side: float in [-1.0, 1.0]:
		_box(station, "ChevronBoard", Vector3(60.0, 16.0, 4.0), Vector3(90.0 * side, 0.0, 136.0), _paint(Color.WHITE, CHEVRONS, Vector2(0.125, 0.125)))

	# A neon sign over the docking bay. Mundane trucker stuff, floating in space.
	var board := _box(station, "SignBoard", Vector3(440.0, 120.0, 6.0), Vector3(0.0, 140.0, 132.0), dark)
	_add_collision(body, board)
	_box(station, "SignPost", Vector3(10.0, 14.0, 10.0), Vector3(0.0, 74.0, 132.0), dark)
	# (No names painted on the station: the HUD's green ID label names it.)

	_build_parking_deck(station, body)
	return station


## The parking deck: a big floating lot below the docking bay where truckers
## park their rigs between jobs. Painted bays, lamp posts, and a row of trucks
## with their cab lights on (somebody's napping in there).
func _build_parking_deck(station: Node3D, body: StaticBody3D) -> void:
	var deck_y := -112.0  # The top of the deck.
	var bay_width := 26.0
	var deck_paint := _paint(Color(0.36, 0.34, 0.44), HULL, Vector2(0.1, 0.1))
	var line_paint := _paint(Color(0.95, 0.92, 0.8), null)
	_add_collision(body, _box(station, "ParkingDeck", Vector3(bay_width * 8.0 + 30.0, 6.0, 130.0), Vector3(0.0, deck_y - 3.0, 170.0), deck_paint))
	_add_collision(body, _box(station, "DeckPylon", Vector3(24.0, 48.0, 30.0), Vector3(0.0, deck_y + 20.0, 118.0), _paint(Color(0.42, 0.28, 0.62), HULL, Vector2(0.1, 0.1))))
	_box(station, "DeckEdge", Vector3(bay_width * 8.0 + 30.0, 3.0, 2.0), Vector3(0.0, deck_y - 0.5, 235.0), _paint(Color.WHITE, CHEVRONS, Vector2(0.25, 0.25)))

	# Eight parking bays (painted lines), six of them taken.
	for i in 9:
		_box(station, "BayLine", Vector3(0.8, 0.3, 44.0), Vector3((i - 4.0) * bay_width, deck_y + 0.15, 178.0), line_paint)
	var parked := [
		[0, "box", 0], [1, "capsule", 1], [3, "box", 2], [4, "capsule", 2], [5, "box", 0], [7, "capsule", 0]]
	for spot: Array in parked:
		var x := (int(spot[0]) - 3.5) * bay_width
		var truck: Node3D
		if spot[1] == "box":
			truck = _build_box_hauler("ParkedBoxHauler", BOX_PAINTS[spot[2]], false)
			truck.position = Vector3(x, deck_y + 2.2, 178.0)
		else:
			truck = _build_capsule_hauler("ParkedCapsuleHauler", CAPSULE_PAINTS[spot[2]], false)
			truck.position = Vector3(x, deck_y + 4.6, 178.0)
		# Parked nose-out, backed into the bay like a pro.
		station.add_child(truck, true)
		var shape := CollisionShape3D.new()
		shape.name = "ParkedTruckShape"
		var box_shape := BoxShape3D.new()
		box_shape.size = Vector3(14.0, 7.0, 34.0) if spot[1] == "capsule" else Vector3(5.0, 5.0, 20.0)
		shape.shape = box_shape
		shape.position = truck.position
		body.add_child(shape, true)

	# Lamp posts along the front edge, glowing warm like a truck-stop lot.
	for i in 5:
		var x := (i - 2.0) * bay_width * 2.0
		_box(station, "LampPost", Vector3(0.8, 14.0, 0.8), Vector3(x, deck_y + 7.0, 232.0), _paint(Color(0.2, 0.2, 0.25), null))
		_box(station, "Lamp", Vector3(3.0, 1.0, 2.0), Vector3(x, deck_y + 14.0, 231.0), _glow(Color(1.0, 0.75, 0.4), 1.5))


# --- Inside the cab -----------------------------------------------------------
# The driver's eyes are at this scene's origin, looking down -Z. Parts that
# move (wheel, lever, dice...) have the names Cockpit.gd looks for, so keep
# those names if you rebuild this by hand.

func _build_cockpit() -> Node3D:
	var cab := Node3D.new()
	cab.name = "CockpitInterior"
	cab.set_script(load("res://scenes/flight/Cockpit.gd"))
	var dash := _paint(Color(0.24, 0.24, 0.3))
	var panel := _paint(Color(0.13, 0.13, 0.18))
	var hazard := _hazard(3.0)
	var pink := _paint(Color(1.0, 0.55, 0.82), FUZZ, Vector2(4.0, 4.0))
	var chrome := _paint(Color(0.82, 0.84, 0.9), null)

	# The windshield frame: hazard-striped pillars and roof bar, like a truck cab.
	for side: float in [-1.0, 1.0]:
		_beam(cab, "Pillar", Vector3(1.38 * side, -0.45, -1.42), Vector3(1.18 * side, 1.02, -0.95), 0.16, hazard)
		_box(cab, "SideWall", Vector3(0.1, 2.2, 2.2), Vector3(1.6 * side, 0.1, -0.2), panel)
	_beam(cab, "RoofBar", Vector3(-1.3, 1.02, -0.95), Vector3(1.3, 1.02, -0.95), 0.16, hazard)
	_box(cab, "Roof", Vector3(3.2, 0.1, 1.8), Vector3(0.0, 1.12, -0.1), panel)

	# The dashboard, with a fuzzy pink dash mat.
	_box(cab, "DashTop", Vector3(3.0, 0.1, 1.0), Vector3(0.0, -0.48, -1.1), dash)
	_box(cab, "DashFront", Vector3(3.0, 0.5, 0.1), Vector3(0.0, -0.75, -0.62), panel)
	_box(cab, "DashMat", Vector3(1.0, 0.03, 0.35), Vector3(0.0, -0.42, -1.4), pink)

	# The instrument panel, tilted toward the driver: two screens and two dials.
	var instruments := Node3D.new()
	instruments.name = "Instruments"
	instruments.position = Vector3(0.0, -0.3, -1.0)
	instruments.rotation = Vector3(-0.35, 0.0, 0.0)
	cab.add_child(instruments, true)
	_box(instruments, "InstrumentPanel", Vector3(2.4, 0.4, 0.08), Vector3.ZERO, dash)
	for screen: Array in [["StatusScreen", -0.72], ["NavScreen", 0.72]]:
		var quad := QuadMesh.new()
		quad.size = Vector2(0.62, 0.32)
		_mesh(instruments, screen[0], quad, Vector3(screen[1], 0.0, 0.045))
	for dial: Array in [["SpeedDial", -0.24], ["HullDial", 0.24]]:
		var face := _cylinder(instruments, dial[0], 0.085, 0.02, Vector3(dial[1], 0.04, 0.05), _paint(Color(0.08, 0.1, 0.09), null), Vector3(PI / 2.0, 0.0, 0.0), 12)
		var bezel := TorusMesh.new()
		bezel.inner_radius = 0.08
		bezel.outer_radius = 0.095
		bezel.rings = 12
		bezel.ring_segments = 4
		bezel.material = chrome
		_mesh(face, "Bezel", bezel, Vector3.ZERO)
		var needle := Node3D.new()
		needle.name = "Needle"
		face.add_child(needle, true)
		_box(needle, "NeedleBar", Vector3(0.012, 0.02, 0.07), Vector3(0.0, 0.016, -0.03), _glow(Color(1.0, 0.35, 0.2), 1.4))
		for tick in 7:
			var tick_angle := lerpf(2.2, -2.2, tick / 6.0)
			var mark := _box(face, "Tick", Vector3(0.008, 0.02, 0.018), Vector3(-sin(tick_angle) * 0.068, 0.012, -cos(tick_angle) * 0.068), _glow(Color(0.5, 1.0, 0.6), 0.9))
			mark.rotation = Vector3(0.0, tick_angle, 0.0)
	# A snapshot taped to the panel, and a couple of sticky notes.
	var photo := QuadMesh.new()
	photo.size = Vector2(0.1, 0.125)
	photo.material = _paint(Color.WHITE, PHOTO, Vector2.ONE, false)
	_mesh(instruments, "Photo", photo, Vector3(-1.13, 0.04, 0.05), Vector3(0.0, 0.0, 0.12))
	for note: Array in [[Vector3(1.1, 0.12, 0.05), -0.1], [Vector3(1.12, -0.06, 0.05), 0.15]]:
		var sticky := QuadMesh.new()
		sticky.size = Vector2(0.08, 0.08)
		sticky.material = _paint(Color(1.0, 0.9, 0.35), null)
		_mesh(instruments, "StickyNote", sticky, note[0], Vector3(0.0, 0.0, note[1]))

	# The steering wheel (with a fuzzy pink cover), tilted toward the driver.
	var column := Node3D.new()
	column.name = "WheelColumn"
	column.position = Vector3(0.0, -0.44, -0.62)
	column.rotation = Vector3(0.96, 0.0, 0.0)
	cab.add_child(column, true)
	_box(column, "ColumnShaft", Vector3(0.07, 0.4, 0.07), Vector3(0.0, -0.2, 0.0), dash)
	var wheel := Node3D.new()
	wheel.name = "Wheel"
	column.add_child(wheel, true)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.19
	rim.outer_radius = 0.24
	rim.rings = 16
	rim.ring_segments = 6
	rim.material = pink
	_mesh(wheel, "Rim", rim, Vector3.ZERO)
	_cylinder(wheel, "Hub", 0.06, 0.05, Vector3.ZERO, chrome, Vector3.ZERO, 8)
	for i in 3:
		var angle := PI / 2.0 + i * TAU / 3.0
		var spoke := _box(wheel, "Spoke", Vector3(0.2, 0.02, 0.03), Vector3(cos(angle), 0.0, sin(angle)) * 0.11, dash)
		spoke.rotation = Vector3(0.0, -angle, 0.0)

	# The throttle lever and the big boost button, right of the wheel.
	_box(cab, "LeverBase", Vector3(0.14, 0.05, 0.18), Vector3(0.45, -0.5, -0.6), panel)
	var lever := Node3D.new()
	lever.name = "ThrottleLever"
	lever.position = Vector3(0.45, -0.48, -0.6)
	cab.add_child(lever, true)
	_box(lever, "LeverStick", Vector3(0.022, 0.14, 0.022), Vector3(0.0, 0.07, 0.0), chrome)
	_box(lever, "LeverKnob", Vector3(0.06, 0.045, 0.06), Vector3(0.0, 0.15, 0.0), _paint(Color(0.9, 0.2, 0.2), null))
	_box(cab, "ButtonBase", Vector3(0.14, 0.03, 0.14), Vector3(0.68, -0.5, -0.64), _hazard(30.0))
	_cylinder(cab, "BoostButton", 0.045, 0.04, Vector3(0.68, -0.47, -0.64), _paint(Color(1.0, 0.45, 0.1), null), Vector3.ZERO, 10)

	# The overhead panel: rows of little lights, and a red alarm light.
	_box(cab, "OverheadPanel", Vector3(1.4, 0.1, 0.6), Vector3(0.0, 1.0, -0.55), dash)
	for row in 2:
		for column_index in 8:
			_box(cab, "Led", Vector3(0.04, 0.02, 0.04), Vector3(-0.42 + column_index * 0.12, 0.945, -0.72 + row * 0.12), _paint(Color(0.3, 0.3, 0.3), null))
	_box(cab, "AlarmLight", Vector3(0.1, 0.06, 0.1), Vector3(0.6, 0.93, -0.8), _paint(Color(0.5, 0.1, 0.1), null))

	# Toys: fuzzy dice and an air freshener hanging from the roof bar, an alien
	# bobblehead, a coffee and a clipboard on the dash.
	var dice := Node3D.new()
	dice.name = "Dice"
	dice.position = Vector3(0.32, 0.94, -0.95)
	cab.add_child(dice, true)
	_box(dice, "String", Vector3(0.006, 0.22, 0.006), Vector3(0.0, -0.11, 0.0), _paint(Color(0.9, 0.9, 0.9), null))
	var pink_die := _paint(Color(1.0, 0.5, 0.8), FUZZ, Vector2(12.0, 12.0))
	_box(dice, "Die", Vector3(0.07, 0.07, 0.07), Vector3(-0.03, -0.25, 0.0), pink_die).rotation = Vector3(0.3, 0.4, 0.1)
	_box(dice, "Die", Vector3(0.07, 0.07, 0.07), Vector3(0.04, -0.28, 0.01), pink_die).rotation = Vector3(-0.2, 0.9, 0.3)
	var freshener := Node3D.new()
	freshener.name = "Freshener"
	freshener.position = Vector3(-0.42, 0.94, -1.0)
	cab.add_child(freshener, true)
	_box(freshener, "String", Vector3(0.005, 0.14, 0.005), Vector3(0.0, -0.07, 0.0), _paint(Color(0.9, 0.9, 0.9), null))
	_slab(freshener, "Tree", PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.05, 0.12), Vector2(-0.05, 0.12)]), 0.0, 0.004, _paint(Color(0.3, 0.85, 0.4), null)).rotation = Vector3(PI / 2.0, 0.0, 0.0)
	var bobble := Node3D.new()
	bobble.name = "Bobblehead"
	bobble.position = Vector3(-0.85, -0.43, -1.2)
	cab.add_child(bobble, true)
	_cylinder(bobble, "BobbleBody", 0.03, 0.08, Vector3(0.0, 0.04, 0.0), _paint(Color(0.55, 0.3, 0.7), null), Vector3.ZERO, 6)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, 0.1, 0.0)
	bobble.add_child(head, true)
	_loft(head, "HeadShape", Vector3(0.0, 0.0, -0.04), Vector2(0.09, 0.08), Vector3(0.0, 0.0, 0.04), Vector2(0.09, 0.08), _paint(Color(0.45, 0.95, 0.5), null), 0.4)
	_box(head, "Eye", Vector3(0.025, 0.03, 0.01), Vector3(-0.02, 0.005, 0.042), _paint(Color(0.05, 0.05, 0.08), null))
	_box(head, "Eye", Vector3(0.025, 0.03, 0.01), Vector3(0.02, 0.005, 0.042), _paint(Color(0.05, 0.05, 0.08), null))
	_box(head, "Antenna", Vector3(0.006, 0.06, 0.006), Vector3(0.0, 0.07, 0.0), _paint(Color(0.45, 0.95, 0.5), null))
	_cylinder(cab, "Coffee", 0.04, 0.11, Vector3(1.0, -0.37, -0.95), _paint(Color(0.95, 0.92, 0.85), null), Vector3.ZERO, 8)
	_cylinder(cab, "CoffeeLid", 0.043, 0.02, Vector3(1.0, -0.305, -0.95), _paint(Color(0.35, 0.22, 0.15), null), Vector3.ZERO, 8)
	var clipboard := _box(cab, "Clipboard", Vector3(0.24, 0.01, 0.32), Vector3(-1.05, -0.425, -1.05), _paint(Color(0.55, 0.38, 0.22), null))
	clipboard.rotation = Vector3(0.0, 0.3, 0.0)
	var paper := _box(clipboard, "Paper", Vector3(0.21, 0.004, 0.27), Vector3(0.0, 0.006, 0.01), _paint(Color(0.96, 0.95, 0.9), null))
	paper.rotation = Vector3(0.0, 0.05, 0.0)

	# A warm little cab light, so it feels like a place someone lives in.
	var lamp := OmniLight3D.new()
	lamp.name = "CabLight"
	lamp.position = Vector3(0.0, 0.7, -0.3)
	lamp.light_color = Color(1.0, 0.72, 0.5)
	lamp.light_energy = 0.7
	lamp.omni_range = 3.0
	cab.add_child(lamp, true)
	return cab


## A box stretched between two points, `thickness` meters thick.
func _beam(parent: Node3D, node_name: String, from: Vector3, to: Vector3, thickness: float, material: Material) -> MeshInstance3D:
	var beam := _box(parent, node_name, Vector3(thickness, thickness, from.distance_to(to)), (from + to) * 0.5, material)
	beam.basis = Basis.looking_at(to - from, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.BACK)
	return beam


# --- Shapes -------------------------------------------------------------------

## A chunky 8-sided tube: a rectangle with its corners cut off, stretched
## from one cross-section (`front_center`, `front_size`) to another. Most of
## the ships are built from these. `bevel` is how much of each corner is cut
## (0.25 = a quarter of the smaller side).
func _loft(parent: Node3D, node_name: String, front_center: Vector3, front_size: Vector2,
		back_center: Vector3, back_size: Vector2, material: Material, bevel: float = 0.22) -> MeshInstance3D:
	var front := _octagon(front_center, front_size, bevel)
	var back := _octagon(back_center, back_size, bevel)
	var triangles: Array[PackedVector3Array] = []
	var uvs: Array[PackedVector2Array] = []
	var sizes := PackedVector2Array()
	for i in 8:
		var j := (i + 1) % 8
		# Each side is one panel: across it, and along the hull.
		var size := Vector2((front[i].distance_to(front[j]) + back[i].distance_to(back[j])) * 0.5,
				(front[i].distance_to(back[i]) + front[j].distance_to(back[j])) * 0.5)
		triangles.append(PackedVector3Array([front[i], front[j], back[j]]))
		uvs.append(PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1)]))
		sizes.append(size)
		triangles.append(PackedVector3Array([front[i], back[j], back[i]]))
		uvs.append(PackedVector2Array([Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]))
		sizes.append(size)
	for i in range(1, 7):
		triangles.append(PackedVector3Array([front[0], front[i], front[i + 1]]))
		triangles.append(PackedVector3Array([back[0], back[i], back[i + 1]]))
		for cap in 2:
			uvs.append(PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
			sizes.append(Vector2.ZERO)  # End caps: no panel details.
	return _mesh(parent, node_name, _flat_mesh(triangles, (front_center + back_center) * 0.5, material, uvs, sizes), Vector3.ZERO)


## A flat slab (like a wing): a convex outline in the X/Z plane (seen from
## above), `thickness` meters thick, centered at height `y`.
func _slab(parent: Node3D, node_name: String, outline: PackedVector2Array, y: float, thickness: float, material: Material) -> MeshInstance3D:
	var top := PackedVector3Array()
	var bottom := PackedVector3Array()
	var middle := Vector3.ZERO
	for point in outline:
		top.append(Vector3(point.x, y + thickness * 0.5, point.y))
		bottom.append(Vector3(point.x, y - thickness * 0.5, point.y))
		middle += Vector3(point.x, y, point.y) / outline.size()
	var triangles: Array[PackedVector3Array] = []
	var count := outline.size()
	for i in count:
		var j := (i + 1) % count
		triangles.append(PackedVector3Array([top[i], top[j], bottom[j]]))
		triangles.append(PackedVector3Array([top[i], bottom[j], bottom[i]]))
	for i in range(1, count - 1):
		triangles.append(PackedVector3Array([top[0], top[i], top[i + 1]]))
		triangles.append(PackedVector3Array([bottom[0], bottom[i], bottom[i + 1]]))
	return _mesh(parent, node_name, _flat_mesh(triangles, middle, material), Vector3.ZERO)


## The eight corners of a rectangle with its corners cut off.
func _octagon(center: Vector3, size: Vector2, bevel: float) -> PackedVector3Array:
	var w := size.x * 0.5
	var h := size.y * 0.5
	var cut := minf(size.x, size.y) * bevel
	var corners := PackedVector3Array()
	for point: Vector2 in [
			Vector2(-w + cut, h), Vector2(w - cut, h), Vector2(w, h - cut), Vector2(w, -h + cut),
			Vector2(w - cut, -h), Vector2(-w + cut, -h), Vector2(-w, -h + cut), Vector2(-w, h - cut)]:
		corners.append(center + Vector3(point.x, point.y, 0.0))
	return corners


## Turns a list of triangles into a flat-shaded mesh. Works for any convex
## shape: each triangle is turned to face away from the shape's `middle`.
## Optional: `uvs` (three per triangle) and `sizes` (one per triangle, put
## in UV2) for panel decals (see _loft).
func _flat_mesh(triangles: Array[PackedVector3Array], middle: Vector3, material: Material,
		uvs: Array[PackedVector2Array] = [], sizes: PackedVector2Array = PackedVector2Array()) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	for t in triangles.size():
		var triangle := triangles[t]
		var a := triangle[0]
		var b := triangle[1]
		var c := triangle[2]
		var corner_uvs := uvs[t] if t < uvs.size() else PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
		var uv_a := corner_uvs[0]
		var uv_b := corner_uvs[1]
		var uv_c := corner_uvs[2]
		var outward := (b - a).cross(c - a)
		if outward.length_squared() < 0.000001:
			continue  # A squashed, zero-size triangle: skip it.
		if outward.dot((a + b + c) / 3.0 - middle) < 0.0:
			outward = -outward
		else:
			# Godot shows a triangle's front when its corners go CLOCKWISE as
			# seen from outside, so swap two corners to get that order.
			var swap := b
			b = c
			c = swap
			var swap_uv := uv_b
			uv_b = uv_c
			uv_c = swap_uv
		surface.set_normal(outward.normalized())
		var size := sizes[t] if t < sizes.size() else Vector2.ZERO
		for corner: Array in [[a, uv_a], [b, uv_b], [c, uv_c]]:
			surface.set_uv(corner[1])
			surface.set_uv2(size)
			surface.add_vertex(corner[0])
	return surface.commit()


## A glowing engine nozzle at `where` (the back of an engine), plus a marker
## with an engine trail if `with_trail` is on.
func _engine(ship: Node3D, where: Vector3, size: Vector2, color: Color, strength: float, with_trail: bool) -> void:
	_box(ship, "EngineGlow", Vector3(size.x, size.y, 0.15), where, _glow(color, strength))
	if not with_trail:
		return
	var nozzle := Marker3D.new()
	nozzle.name = "Nozzle"
	nozzle.position = where + Vector3(0.0, 0.0, 0.25)
	ship.add_child(nozzle, true)
	var trail := MeshInstance3D.new()
	trail.name = "EngineTrail"
	trail.set_script(_trail_script)
	nozzle.add_child(trail, true)
	var flare := MeshInstance3D.new()
	flare.name = "EngineFlare"
	flare.set_script(_flare_script)
	flare.position = Vector3(0.0, 0.0, 0.4)
	flare.set("size_at_top_speed", maxf(size.x, size.y) * 3.0)
	nozzle.add_child(flare, true)


func _mirrored(outline: PackedVector2Array) -> PackedVector2Array:
	var flipped := PackedVector2Array()
	for point in outline:
		flipped.append(Vector2(-point.x, point.y))
	return flipped


# --- Materials ------------------------------------------------------------------

## A painted PS1 surface: a tiny texture (hull plating by default) tinted with
## `color`. `texture` = null gives flat paint. `box_uv` projects the texture
## from the sides in meters; turn it off for round shapes that bring their
## own texture coordinates (cylinders, rings).
func _paint(color: Color, texture: Texture2D = HULL, uv_scale: Vector2 = HULL_SCALE, box_uv: bool = true) -> ShaderMaterial:
	var panels := _ship_mode and box_uv and (texture == HULL or texture == null)
	if panels:
		texture = null  # Solid color: the panel details are painted by the shader.
	var key := "paint %s %s %s %s %s" % [color, texture.resource_path if texture else "none", uv_scale, box_uv, panels]
	if not _material_cache.has(key):
		var material := ShaderMaterial.new()
		material.shader = SURFACE_SHADER
		material.set_shader_parameter("albedo", color)
		if panels:
			material.set_shader_parameter("panel_decals", true)
			material.set_shader_parameter("box_uv", true)
			_material_cache[key] = material
			return material
		if texture == null and box_uv:
			# Flat paint, but hand-painted: a gentle mottle, about 2 m a tile.
			texture = PAINT_GRAIN
			uv_scale = Vector2(0.5, 0.5)
		if texture != null:
			material.set_shader_parameter("albedo_texture", texture)
		material.set_shader_parameter("uv_scale", uv_scale)
		material.set_shader_parameter("box_uv", box_uv)
		_material_cache[key] = material
	return _material_cache[key]


## A material that glows on its own, like a lamp, a screen or an engine.
func _glow(color: Color, strength: float, base: Color = Color.BLACK) -> ShaderMaterial:
	var key := "glow %s %s %s" % [color, strength, base]
	if not _material_cache.has(key):
		var material := ShaderMaterial.new()
		material.shader = SURFACE_SHADER
		material.set_shader_parameter("albedo", base if base != Color.BLACK else color)
		material.set_shader_parameter("emission", color)
		material.set_shader_parameter("emission_strength", strength)
		_material_cache[key] = material
	return _material_cache[key]


## Rows of little station windows that glow where they're lit.
func _windows(uv_scale: Vector2) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	material.set_shader_parameter("albedo_texture", WINDOWS)
	material.set_shader_parameter("uv_scale", uv_scale)
	material.set_shader_parameter("box_uv", false)
	material.set_shader_parameter("emission", Color.WHITE)
	material.set_shader_parameter("emission_strength", 1.3)
	material.set_shader_parameter("emission_from_texture", true)
	return material


## Yellow-and-black hazard stripes. `stripes_per_meter` sets how big they look.
func _hazard(stripes_per_meter: float) -> ShaderMaterial:
	return _paint(Color.WHITE, HAZARD, Vector2.ONE * stripes_per_meter * 0.25)


# --- Helpers -----------------------------------------------------------------

func _box(parent: Node3D, node_name: String, size: Vector3, where: Vector3, material: Material) -> MeshInstance3D:
	material = _edged(material)
	var key := "%s %d" % [size, material.get_instance_id()]
	if not _box_cache.has(key):
		var new_box := BoxMesh.new()
		new_box.size = size
		new_box.material = material
		_box_cache[key] = new_box
	return _mesh(parent, node_name, _box_cache[key], where)


## The same material with painted bevels and shadow switched on (see
## shaders/painted_edges.gdshaderinc). Only for boxes, and not for things
## that glow (signs and screens stay clean).
func _edged(material: Material) -> Material:
	var shaded := material as ShaderMaterial
	if shaded == null or not (shaded.shader == SURFACE_SHADER or shaded.shader == SET_SHADER):
		return material
	var glow: Variant = shaded.get_shader_parameter("emission_strength")
	if glow != null and float(glow) > 0.0:
		return material
	if not _edged_cache.has(material):
		var edged := shaded.duplicate() as ShaderMaterial
		edged.set_shader_parameter("painted_edges", true)
		if shaded.shader == SURFACE_SHADER:
			# Ships and stations: bigger, seen from farther away.
			edged.set_shader_parameter("edge_width", 0.22)
			edged.set_shader_parameter("edge_pixels_per_meter", 8.0)
			edged.set_shader_parameter("edge_floor_reach", 1.5)
		_edged_cache[material] = edged
	return _edged_cache[material]


func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, where: Vector3,
		material: Material, turn: Vector3 = Vector3.ZERO, sides: int = 10) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = sides
	cylinder.rings = 1
	cylinder.material = material
	return _mesh(parent, node_name, cylinder, where, turn)


func _mesh(parent: Node3D, node_name: String, mesh: Mesh, where: Vector3, turn: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = where
	instance.rotation = turn
	parent.add_child(instance, true)  # true = auto-number repeated names.
	return instance


## Approximates a ring's collision with a loop of capsules (much lighter than
## an exact copy of all its triangles).
func _add_ring_collision(body: StaticBody3D, ring_radius: float, tube_radius: float, pieces: int) -> void:
	var chord := 2.0 * ring_radius * sin(PI / pieces)
	for i in pieces:
		var angle := TAU * (i + 0.5) / pieces
		var capsule := CapsuleShape3D.new()
		capsule.radius = tube_radius
		capsule.height = chord + 2.0 * tube_radius
		var collision := CollisionShape3D.new()
		collision.name = "RingShape"
		collision.shape = capsule
		collision.position = Vector3(cos(angle), sin(angle), 0.0) * ring_radius
		collision.rotation = Vector3(0.0, 0.0, angle)  # Capsule lies along the ring.
		body.add_child(collision, true)


## Glowing text that floats in space. `meters_per_pixel` sets its size.
func _sign(parent: Node3D, node_name: String, text: String, meters_per_pixel: float, color: Color, where: Vector3) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.font_size = 96
	label.pixel_size = meters_per_pixel
	label.outline_size = 16
	label.modulate = color
	label.outline_modulate = Color(0.25, 0.05, 0.3)
	label.position = where
	parent.add_child(label, true)


## Painted-on lettering on the side of a ship. `side` is -1 (left) or 1 (right).
func _decal(parent: Node3D, node_name: String, text: String, where: Vector3, side: float) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.font_size = 64
	label.pixel_size = 0.03
	label.outline_size = 0
	label.modulate = Color(0.2, 0.2, 0.25)
	label.double_sided = false
	label.position = where
	label.rotation = Vector3(0.0, PI / 2.0 * side, 0.0)  # Face outward.
	parent.add_child(label, true)


## Gives a model part a matching invisible collision shape.
func _add_collision(body: StaticBody3D, part: MeshInstance3D) -> void:
	var collision := CollisionShape3D.new()
	collision.name = part.name + "Shape"
	# Simple shapes where we can (cheap and tiny); an exact copy of the
	# triangles only for awkward shapes.
	if part.mesh is BoxMesh:
		var box := BoxShape3D.new()
		box.size = (part.mesh as BoxMesh).size
		collision.shape = box
	elif part.mesh is CylinderMesh:
		var cylinder := CylinderShape3D.new()
		cylinder.radius = (part.mesh as CylinderMesh).top_radius
		cylinder.height = (part.mesh as CylinderMesh).height
		collision.shape = cylinder
	else:
		collision.shape = part.mesh.create_trimesh_shape()
	collision.transform = part.transform
	body.add_child(collision, true)


func _save(scene_root: Node, path: String) -> void:
	_claim(scene_root, scene_root)
	var scene := PackedScene.new()
	var error := scene.pack(scene_root)
	if error == OK:
		error = ResourceSaver.save(scene, path)
	print("%s: %s" % [path, error_string(error)])
	scene_root.free()


## Saved scenes only keep nodes "owned" by the scene's root.
func _claim(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		_claim(child, scene_root)
