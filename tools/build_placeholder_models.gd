extends SceneTree
## Builds the placeholder 3D models out of simple boxes and cylinders, and
## saves them as ordinary scenes you can open in the editor:
##     res://scenes/flight/ShipVisual.tscn  - "The Lazy Susan", the starter rig
##     res://scenes/flight/Station.tscn     - a big truck-stop space station
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_placeholder_models.gd
##
## Careful: running it again OVERWRITES those two scenes. If you've changed
## them by hand in the editor, don't re-run this (or copy your changes into
## this script first). Real art will replace these scenes eventually anyway.
##
## Directions: in Godot, -Z is "forward", +Y is up, +X is right.


const HAZARD_TEXTURE := preload("res://textures/generated/hazard_stripes.png")
# Scripts are loaded in _initialize (not preloaded) because EngineTrail uses
# autoloads, which don't exist yet while this tool script is being compiled.
const BLINKER_SCRIPT_PATH := "res://scenes/flight/Blinker.gd"
const TRAIL_SCRIPT_PATH := "res://scenes/flight/EngineTrail.gd"

## A rotation that turns a cylinder (normally standing up along Y) to lie
## along Z, front to back.
const ALONG_Z := Vector3(PI / 2.0, 0.0, 0.0)

var _blinker_script: Script
var _trail_script: Script
# Identical materials and box shapes are made once and shared, which keeps the
# saved scenes small and cheap to draw.
var _material_cache := {}
var _box_cache := {}


# _initialize runs once the game's autoloads exist; the trail script needs them.
func _initialize() -> void:
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_trail_script = load(TRAIL_SCRIPT_PATH)
	_save(_build_ship(), "res://scenes/flight/ShipVisual.tscn")
	_save(_build_station(), "res://scenes/flight/Station.tscn")
	quit()


# --- The Lazy Susan ---------------------------------------------------------

func _build_ship() -> Node3D:
	var ship := Node3D.new()
	ship.name = "ShipVisual"

	var cab_red := _paint(Color(0.86, 0.2, 0.26), 0.55)
	var cream := _paint(Color(0.98, 0.92, 0.78))
	var chrome := _paint(Color(0.8, 0.82, 0.9), 0.3)
	var dark := _paint(Color(0.2, 0.2, 0.26))
	var teal := _paint(Color(0.18, 0.56, 0.62))
	var teal_dark := _paint(Color(0.12, 0.38, 0.44))
	var glass := _glow(Color(0.25, 0.6, 0.85), 0.5, Color(0.1, 0.16, 0.3))
	var engine_glow := _glow(Color(1.0, 0.55, 0.3), 1.3)

	# The cab, up front.
	_box(ship, "Cab", Vector3(4.2, 3.4, 4.0), Vector3(0.0, 0.5, -6.6), cab_red)
	_box(ship, "CabStripe", Vector3(4.24, 0.35, 4.04), Vector3(0.0, -0.55, -6.6), cream)
	_box(ship, "Bumper", Vector3(4.5, 0.9, 0.7), Vector3(0.0, -0.95, -8.75), chrome)
	_box(ship, "Grille", Vector3(2.6, 1.0, 0.15), Vector3(0.0, -0.05, -8.65), chrome)
	for side: float in [-1.0, 1.0]:
		_box(ship, "Headlight", Vector3(0.7, 0.45, 0.12), Vector3(1.55 * side, -0.1, -8.66), _glow(Color(1.0, 0.95, 0.8), 1.4))
		_box(ship, "SideWindow", Vector3(0.1, 1.0, 1.6), Vector3(2.11 * side, 1.3, -7.4), glass)
		# Chrome exhaust stacks, a little homage to the trucks back on Earth.
		_cylinder(ship, "Exhaust", 0.2, 3.6, Vector3(2.3 * side, 1.6, -5.0), chrome)
		_cylinder(ship, "ExhaustCap", 0.26, 0.25, Vector3(2.3 * side, 3.45, -5.0), dark)
	_box(ship, "Windshield", Vector3(3.7, 1.25, 0.12), Vector3(0.0, 1.3, -8.62), glass)
	for i in 5:
		_box(ship, "RoofLight", Vector3(0.35, 0.22, 0.3), Vector3(-1.4 + 0.7 * i, 2.31, -8.25), _glow(Color(1.0, 0.72, 0.25), 1.5))
	var beacon := _box(ship, "Beacon", Vector3(0.55, 0.4, 0.55), Vector3(0.0, 2.42, -5.8), _glow(Color(1.0, 0.45, 0.1), 1.8))
	beacon.set_script(_blinker_script)

	# The cargo container out back.
	_box(ship, "Hitch", Vector3(2.2, 1.4, 1.6), Vector3(0.0, -0.2, -4.0), dark)
	_box(ship, "Container", Vector3(4.5, 4.1, 11.6), Vector3(0.0, 0.7, 2.3), teal)
	_box(ship, "ContainerBand", Vector3(4.56, 0.45, 11.66), Vector3(0.0, 1.6, 2.3), cream)
	for rib_z: float in [-3.3, -0.6, 2.1, 4.8, 7.9]:
		_box(ship, "Rib", Vector3(4.6, 4.16, 0.18), Vector3(0.0, 0.7, rib_z), teal_dark)
	_box(ship, "RearBumper", Vector3(4.6, 0.55, 0.45), Vector3(0.0, -1.15, 8.3), _hazard(1.2))
	_box(ship, "NavLightLeft", Vector3(0.25, 0.25, 0.25), Vector3(-2.3, 2.85, 8.0), _glow(Color(1.0, 0.15, 0.15), 1.5))
	_box(ship, "NavLightRight", Vector3(0.25, 0.25, 0.25), Vector3(2.3, 2.85, 8.0), _glow(Color(0.2, 1.0, 0.35), 1.5))

	# Two big engines, each with a glowing nozzle and an engine trail.
	_box(ship, "EngineMount", Vector3(3.8, 1.6, 1.0), Vector3(0.0, 0.3, 8.6), dark)
	for side: float in [-1.0, 1.0]:
		var x := 1.35 * side
		_cylinder(ship, "Engine", 0.95, 2.4, Vector3(x, 0.3, 9.4), dark, ALONG_Z, 12)
		_cylinder(ship, "EngineGlow", 0.72, 0.12, Vector3(x, 0.3, 10.62), engine_glow, ALONG_Z, 12)
		var nozzle := Marker3D.new()
		nozzle.name = "Nozzle"
		nozzle.position = Vector3(x, 0.3, 10.75)
		ship.add_child(nozzle, true)
		var trail := MeshInstance3D.new()
		trail.name = "EngineTrail"
		trail.set_script(_trail_script)
		nozzle.add_child(trail, true)
	return ship


# --- The truck-stop station -------------------------------------------------
# Its docking face (the front) points toward +Z, where the player arrives from.

func _build_station() -> Node3D:
	var station := Node3D.new()
	station.name = "Station"

	var hull := _paint(Color(0.72, 0.7, 0.78))
	var accent := _paint(Color(0.35, 0.22, 0.55))
	var dark := _paint(Color(0.14, 0.13, 0.2))
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

	# The big ring, with four spokes holding it to the hub.
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 300.0
	ring_mesh.outer_radius = 360.0
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 8
	ring_mesh.material = hull
	_mesh(station, "Ring", ring_mesh, Vector3.ZERO, ALONG_Z)
	_add_ring_collision(body, 330.0, 30.0, 24)
	for i in 4:
		var angle := PI / 4.0 + i * PI / 2.0
		var spoke := _box(station, "Spoke", Vector3(18.0, 236.0, 18.0), Vector3(cos(angle), sin(angle), 0.0) * 187.0, accent)
		spoke.rotation = Vector3(0.0, 0.0, angle - PI / 2.0)
		_add_collision(body, spoke)

	# Warm windows all around the ring's front face, and blinking beacons.
	var window_colors: Array[Color] = [Color(1.0, 0.82, 0.4), Color(1.0, 0.82, 0.4), Color(1.0, 0.5, 0.75), Color(0.45, 0.95, 1.0)]
	for i in 64:
		var angle := TAU * i / 64.0
		var color: Color = window_colors[(i * 7) % window_colors.size()]
		var window := _box(station, "Window", Vector3(16.0, 9.0, 3.0), Vector3(cos(angle) * 330.0, sin(angle) * 330.0, 30.0), _glow(color, 1.4))
		window.rotation = Vector3(0.0, 0.0, angle + PI / 2.0)  # Long side along the ring.
	for i in 4:
		var angle := i * PI / 2.0
		var beacon := _box(station, "Beacon", Vector3(12.0, 12.0, 12.0), Vector3(cos(angle), sin(angle), 0.0) * 366.0, _glow(Color(1.0, 0.2, 0.2), 1.8))
		beacon.set_script(_blinker_script)
		beacon.set("offset", i * 0.25)

	# A neon sign over the docking bay. Mundane trucker stuff, floating in space.
	var board := _box(station, "SignBoard", Vector3(440.0, 120.0, 6.0), Vector3(0.0, 140.0, 132.0), dark)
	_add_collision(body, board)
	_box(station, "SignPost", Vector3(10.0, 14.0, 10.0), Vector3(0.0, 74.0, 132.0), dark)
	_sign(station, "NeonSignTop", "TRUCK STOP", 0.5, Color(1.0, 0.45, 0.8), Vector3(0.0, 158.0, 136.0))
	_sign(station, "NeonSignBottom", "OPEN 24/7 - FUEL - NAPS", 0.25, Color(0.45, 0.95, 1.0), Vector3(0.0, 108.0, 136.0))
	return station


# --- Helpers -----------------------------------------------------------------

func _paint(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var key := "paint %s %s" % [color, roughness]
	if not _material_cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = roughness
		_material_cache[key] = material
	return _material_cache[key]


## A material that glows on its own, like a lamp or a screen.
func _glow(color: Color, strength: float, base: Color = Color.BLACK) -> StandardMaterial3D:
	var key := "glow %s %s %s" % [color, strength, base]
	if not _material_cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = base if base != Color.BLACK else color
		material.roughness = 0.8
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = strength
		_material_cache[key] = material
	return _material_cache[key]


## Yellow-and-black hazard stripes. `stripes_per_meter` sets how big they look.
func _hazard(stripes_per_meter: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.roughness = 0.8
	material.albedo_texture = HAZARD_TEXTURE
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Crisp pixels.
	# "Triplanar" projects the stripes from the sides, so they tile evenly
	# across every face of the box.
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * stripes_per_meter
	return material


func _box(parent: Node3D, node_name: String, size: Vector3, where: Vector3, material: Material) -> MeshInstance3D:
	var key := "%s %d" % [size, material.get_instance_id()]
	if not _box_cache.has(key):
		var new_box := BoxMesh.new()
		new_box.size = size
		new_box.material = material
		_box_cache[key] = new_box
	return _mesh(parent, node_name, _box_cache[key], where)


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


## Gives a model part a matching invisible collision shape.
func _add_collision(body: StaticBody3D, part: MeshInstance3D) -> void:
	var collision := CollisionShape3D.new()
	collision.name = part.name + "Shape"
	# Simple shapes where we can (cheap and tiny); an exact copy of the
	# triangles only for awkward shapes like the ring.
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
