extends "res://tools/build_placeholder_models.gd"
## Builds the placeholder models for walking around the base, and saves them
## as ordinary scenes you can open in the editor:
##     res://scenes/hub/BunnyVisual.tscn          - our chibi bunny trucker
##     res://scenes/hub/RaccoonVisual.tscn        - Dottie, the dispatch clerk
##     res://scenes/hub/sets/ApartmentSet.tscn    - the rooms' "sets": walls,
##     res://scenes/hub/sets/HallwaySet.tscn        furniture, lights and
##     res://scenes/hub/sets/DispatchSet.tscn       collision
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_hub.gd
##
## Careful: running it again OVERWRITES those scenes. The rooms themselves
## (Apartment.tscn, Hallway.tscn, Dispatch.tscn, with their cameras, doors
## and people) are NOT touched, so camera angles you set in the editor are safe.
##
## It borrows the shape helpers (boxes, lofts...) from build_placeholder_models.gd.
## Characters use the wobbly PS1 shader; the sets use ordinary smooth
## materials and real lights, because they get "pre-rendered" into painted
## backgrounds (see scenes/hub/HubRoom.gd).


const ANIMATOR_PATH := "res://scenes/hub/BunnyAnimator.gd"
const FLOOR_TILES := preload("res://textures/generated/floor_tiles.png")
const WALL_PANELS := preload("res://textures/generated/wall_panels.png")
const CARPET := preload("res://textures/generated/carpet.png")
const WOOD := preload("res://textures/generated/wood.png")
const BLANKET := preload("res://textures/generated/blanket.png")
const SPACE_VIEW := preload("res://textures/generated/space_view.png")
const JOB_BOARD := preload("res://textures/generated/job_board.png")
const DOOR := preload("res://textures/generated/door.png")
const TERMINAL := preload("res://textures/generated/terminal.png")

const BUNNY_LOOK := {
	"fur": Color(0.74, 0.7, 0.8), "belly": Color(0.95, 0.93, 0.92), "inner_ear": Color(1.0, 0.68, 0.76),
	"jacket": Color(0.46, 0.4, 0.26), "shirt": Color(0.92, 0.9, 0.82), "pants": Color(0.3, 0.36, 0.52),
	"boots": Color(0.32, 0.21, 0.15), "cap": Color(0.85, 0.2, 0.22), "cap_front": Color(0.96, 0.95, 0.9),
	"ears": "long", "cap_on": true, "wheat": true, "mask": false, "tail": "puff",
}
const RACCOON_LOOK := {
	"fur": Color(0.55, 0.55, 0.6), "belly": Color(0.85, 0.85, 0.86), "inner_ear": Color(0.35, 0.33, 0.38),
	"jacket": Color(0.2, 0.55, 0.58), "shirt": Color(0.95, 0.95, 0.95), "pants": Color(0.25, 0.25, 0.3),
	"boots": Color(0.15, 0.15, 0.18), "cap": Color(0, 0, 0), "cap_front": Color(0, 0, 0),
	"ears": "round", "cap_on": false, "wheat": false, "mask": true, "tail": "ringed",
}

var _animator_script: Script
var _set_materials := {}


func _initialize() -> void:
	_animator_script = load(ANIMATOR_PATH)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/hub/sets"))
	_save(_build_critter("BunnyVisual", BUNNY_LOOK), "res://scenes/hub/BunnyVisual.tscn")
	_save(_build_critter("RaccoonVisual", RACCOON_LOOK), "res://scenes/hub/RaccoonVisual.tscn")
	_save(_build_apartment(), "res://scenes/hub/sets/ApartmentSet.tscn")
	_save(_build_hallway(), "res://scenes/hub/sets/HallwaySet.tscn")
	_save(_build_dispatch(), "res://scenes/hub/sets/DispatchSet.tscn")
	quit()


# --- Characters ----------------------------------------------------------------
# Chibi proportions: a big head on a small body, about 1.3 m tall with ears.
# Feet at the origin, facing -Z. The moving parts (LegLeft, Body/ArmRight,
# Body/Head/EarLeft...) are named for BunnyAnimator.gd.

func _build_critter(node_name: String, look: Dictionary) -> Node3D:
	var critter := Node3D.new()
	critter.name = node_name
	critter.set_script(_animator_script)
	var fur := _paint(look.fur, FUZZ, Vector2(8.0, 8.0))
	var belly := _paint(look.belly, FUZZ, Vector2(8.0, 8.0))
	var jacket := _paint(look.jacket, FUZZ, Vector2(3.0, 3.0))
	var pants := _paint(look.pants, null)
	var boots := _paint(look.boots, null)
	var dark := _paint(Color(0.06, 0.05, 0.08), null)

	for side: float in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.name = "LegLeft" if side < 0.0 else "LegRight"
		leg.position = Vector3(0.08 * side, 0.34, 0.0)
		critter.add_child(leg, true)
		_box(leg, "Leg", Vector3(0.11, 0.24, 0.12), Vector3(0.0, -0.13, 0.0), pants)
		_box(leg, "Boot", Vector3(0.13, 0.1, 0.19), Vector3(0.0, -0.29, -0.03), boots)

	var body := Node3D.new()
	body.name = "Body"
	body.position = Vector3(0.0, 0.34, 0.0)
	critter.add_child(body, true)
	# Lofts run front-to-back, so upright parts are built lying down (along
	# -Z) and stood up with a quarter turn.
	_loft(body, "Torso", Vector3(0.0, 0.0, 0.0), Vector2(0.3, 0.22), Vector3(0.0, 0.0, -0.31), Vector2(0.26, 0.2), jacket, 0.3).rotation = Vector3(PI / 2.0, 0.0, 0.0)
	_box(body, "Shirt", Vector3(0.1, 0.24, 0.02), Vector3(0.0, 0.17, -0.105), _paint(look.shirt, null))
	if look.tail == "puff":
		_loft(body, "Tail", Vector3(0.0, 0.06, 0.1), Vector2(0.1, 0.1), Vector3(0.0, 0.06, 0.18), Vector2(0.1, 0.1), belly, 0.45)
	else:
		for ring in 4:  # A big ringed raccoon tail, sweeping down behind.
			var color: Color = look.fur if ring % 2 == 0 else Color(0.2, 0.2, 0.24)
			_loft(body, "Tail", Vector3(0.0, 0.05 - ring * 0.06, 0.12 + ring * 0.06), Vector2(0.13, 0.13), Vector3(0.0, 0.0 - ring * 0.06, 0.18 + ring * 0.06), Vector2(0.13, 0.13), _paint(color, FUZZ, Vector2(8.0, 8.0)), 0.4)
	for side: float in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "ArmLeft" if side < 0.0 else "ArmRight"
		arm.position = Vector3(0.17 * side, 0.28, 0.0)
		body.add_child(arm, true)
		_box(arm, "Sleeve", Vector3(0.08, 0.21, 0.09), Vector3(0.015 * side, -0.1, 0.0), jacket)
		_box(arm, "Paw", Vector3(0.07, 0.07, 0.07), Vector3(0.015 * side, -0.24, 0.0), fur)

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, 0.31, 0.0)
	body.add_child(head, true)
	_loft(head, "Skull", Vector3(0.0, 0.19, 0.17), Vector2(0.42, 0.36), Vector3(0.0, 0.19, -0.17), Vector2(0.42, 0.36), fur, 0.42)
	_loft(head, "Snout", Vector3(0.0, 0.11, -0.16), Vector2(0.18, 0.12), Vector3(0.0, 0.11, -0.22), Vector2(0.14, 0.09), belly, 0.4)
	_box(head, "Nose", Vector3(0.05, 0.035, 0.02), Vector3(0.0, 0.145, -0.225), _paint(Color(0.95, 0.45, 0.6), null))
	if look.mask:
		_box(head, "Mask", Vector3(0.36, 0.08, 0.02), Vector3(0.0, 0.22, -0.172), dark)
	for side: float in [-1.0, 1.0]:
		_box(head, "Eye", Vector3(0.06, 0.07, 0.02), Vector3(0.09 * side, 0.22, -0.18), dark)
		_box(head, "EyeShine", Vector3(0.018, 0.018, 0.01), Vector3(0.09 * side + 0.012, 0.24, -0.192), _paint(Color.WHITE, null))
	# Heavy, tired eyelids (she's seen a lot of space). They drop to blink.
	var eyelids := Node3D.new()
	eyelids.name = "Eyelids"
	eyelids.position = Vector3(0.0, 0.25, -0.19)
	head.add_child(eyelids, true)
	for side: float in [-1.0, 1.0]:
		_box(eyelids, "Lid", Vector3(0.07, 0.03, 0.01), Vector3(0.09 * side, 0.0, 0.0), dark if look.mask else fur)
	for side: float in [-1.0, 1.0]:
		var ear := Node3D.new()
		ear.name = "EarLeft" if side < 0.0 else "EarRight"
		ear.position = Vector3(0.1 * side, 0.36, 0.03)
		head.add_child(ear, true)
		if look.ears == "long":
			_loft(ear, "Ear", Vector3(0.0, 0.0, 0.0), Vector2(0.09, 0.04), Vector3(0.0, 0.0, -0.36), Vector2(0.07, 0.03), fur, 0.35).rotation = Vector3(PI / 2.0, 0.0, 0.0)
			_box(ear, "InnerEar", Vector3(0.05, 0.26, 0.01), Vector3(0.0, 0.18, -0.021), _paint(look.inner_ear, null))
		else:
			_loft(ear, "Ear", Vector3(0.0, 0.0, 0.0), Vector2(0.1, 0.04), Vector3(0.0, 0.0, -0.1), Vector2(0.08, 0.03), fur, 0.45).rotation = Vector3(PI / 2.0, 0.0, 0.0)
			_box(ear, "InnerEar", Vector3(0.05, 0.06, 0.01), Vector3(0.0, 0.05, -0.021), _paint(look.inner_ear, null))
		ear.rotation = Vector3(0.1, 0.0, -0.12 * side)
	if look.cap_on:
		# A trucker cap, ears poking out through holes in the top.
		_loft(head, "CapCrown", Vector3(0.0, 0.4, 0.13), Vector2(0.34, 0.08), Vector3(0.0, 0.41, -0.15), Vector2(0.36, 0.1), _paint(look.cap, null), 0.4)
		_box(head, "CapFront", Vector3(0.2, 0.06, 0.02), Vector3(0.0, 0.41, -0.16), _paint(look.cap_front, null))
		_box(head, "CapBrim", Vector3(0.26, 0.02, 0.12), Vector3(0.0, 0.37, -0.22), _paint(look.cap, null))
	if look.wheat:
		# A stalk of wheat in the corner of her mouth.
		var stalk := _box(head, "Wheat", Vector3(0.012, 0.012, 0.2), Vector3(0.1, 0.08, -0.27), _paint(Color(0.95, 0.8, 0.35), null))
		stalk.rotation = Vector3(0.25, -0.6, 0.0)
	else:
		# A headset microphone, for the dispatch desk.
		_box(head, "Headset", Vector3(0.44, 0.03, 0.03), Vector3(0.0, 0.4, 0.0), dark)
		_box(head, "Mic", Vector3(0.015, 0.015, 0.14), Vector3(0.2, 0.12, -0.12), dark).rotation = Vector3(0.0, 0.5, 0.0)
	return critter


# --- Sets: shared bits -------------------------------------------------------------

## An ordinary smooth material for the sets (they get pre-rendered, so they
## can afford to look nicer than the PS1 models). `texture` tiles every
## `meters` meters, projected from the sides so boxes tile evenly.
func _set_paint(color: Color, texture: Texture2D = null, meters: float = 1.0, glow: float = 0.0) -> StandardMaterial3D:
	var key := "%s %s %s %s" % [color, texture.resource_path if texture else "", meters, glow]
	if not _set_materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.85
		if texture != null:
			material.albedo_texture = texture
			material.uv1_triplanar = true
			material.uv1_scale = Vector3.ONE / meters
		if glow > 0.0:
			# Glowing things: dark underneath, so the glow doesn't wash out to white.
			material.albedo_color = color * 0.15
			material.emission_enabled = true
			material.emission = color
			material.emission_energy_multiplier = glow
			if texture != null:
				material.emission_texture = texture
		_set_materials[key] = material
	return _set_materials[key]


## A box in a set, optionally solid (with a matching collision box).
func _piece(parent: Node3D, body: StaticBody3D, node_name: String, size: Vector3, where: Vector3, material: Material) -> MeshInstance3D:
	var part := _box(parent, node_name, size, where, material)
	if body != null:
		_add_collision(body, part)
	return part


## A lamp: a glowing bulb plus a real light (with shadows, for the painting).
func _lamp(parent: Node3D, node_name: String, where: Vector3, color: Color, energy: float, reach: float, shadows: bool = true) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = where
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.2
	light.shadow_enabled = shadows
	light.set_meta("paint_shadows", shadows)
	parent.add_child(light, true)


## The four walls, floor and ceiling of a box-shaped room, `size` big, with
## its floor's center at the origin. Walls get collision; the ceiling too.
func _room_shell(set_root: Node3D, body: StaticBody3D, size: Vector3, floor_material: Material, wall_material: Material, ceiling_material: Material) -> void:
	var half := size * 0.5
	_piece(set_root, body, "Floor", Vector3(size.x, 0.2, size.z), Vector3(0.0, -0.1, 0.0), floor_material)
	_piece(set_root, body, "Ceiling", Vector3(size.x, 0.2, size.z), Vector3(0.0, size.y + 0.1, 0.0), ceiling_material)
	_piece(set_root, body, "WallBack", Vector3(size.x, size.y, 0.2), Vector3(0.0, half.y, -half.z - 0.1), wall_material)
	_piece(set_root, body, "WallFront", Vector3(size.x, size.y, 0.2), Vector3(0.0, half.y, half.z + 0.1), wall_material)
	_piece(set_root, body, "WallLeft", Vector3(0.2, size.y, size.z), Vector3(-half.x - 0.1, half.y, 0.0), wall_material)
	_piece(set_root, body, "WallRight", Vector3(0.2, size.y, size.z), Vector3(half.x + 0.1, half.y, 0.0), wall_material)


func _new_set(node_name: String) -> Array:
	var set_root := Node3D.new()
	set_root.name = node_name
	var body := StaticBody3D.new()
	body.name = "Collision"
	set_root.add_child(body, true)
	return [set_root, body]


## A sliding door in a wall (just a picture; RoomExit does the walking through).
func _door_panel(parent: Node3D, node_name: String, where: Vector3, facing_y: float) -> void:
	var door := _box(parent, node_name, Vector3(1.2, 2.2, 0.06), where, _set_paint(Color.WHITE, DOOR, 2.2))
	door.rotation = Vector3(0.0, facing_y, 0.0)
	var frame := _box(parent, node_name + "Frame", Vector3(1.45, 2.4, 0.04), where - Vector3(0.0, 0.0, 0.0), _set_paint(Color(0.18, 0.18, 0.24)))
	frame.rotation = door.rotation
	frame.position += Basis(Vector3.UP, facing_y) * Vector3(0.0, 0.0, -0.02)


# --- The apartment ----------------------------------------------------------------
# 6 x 5 m, 2.8 m tall. From the developer's sketch: a big window onto space
# with a heater under it, an unmade bed, a desk with an old computer, socks
# all over the floor, a framed photo, a rug, a plant and a hanging lamp.

func _build_apartment() -> Node3D:
	var parts := _new_set("ApartmentSet")
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var wall := _set_paint(Color(0.5, 0.55, 0.75), WALL_PANELS, 2.0)
	_room_shell(room, body, Vector3(6.0, 2.8, 5.0), _set_paint(Color(0.75, 0.55, 0.45), CARPET, 1.5), wall, _set_paint(Color(0.3, 0.3, 0.4)))

	# The big window, with deep space (and a planet) outside.
	_box(room, "SpaceView", Vector3(3.6, 2.0, 0.05), Vector3(-1.0, 1.6, -2.62), _set_paint(Color.WHITE, SPACE_VIEW, 3.6, 0.9))
	var frame := _set_paint(Color(0.2, 0.2, 0.26))
	_box(room, "WindowSill", Vector3(3.2, 0.12, 0.3), Vector3(-1.0, 0.86, -2.42), frame)
	_box(room, "WindowTop", Vector3(3.2, 0.12, 0.2), Vector3(-1.0, 2.32, -2.45), frame)
	for x: float in [-2.6, -1.0, 0.6]:
		_box(room, "WindowBar", Vector3(0.1, 1.5, 0.15), Vector3(x, 1.6, -2.45), frame)
	# Cut the window out of the back wall: rebuild the wall around it.
	room.get_node("WallBack").free()
	body.get_node("WallBackShape").free()
	_piece(room, body, "WallBackLow", Vector3(6.0, 0.8, 0.2), Vector3(0.0, 0.4, -2.6), wall)
	_piece(room, body, "WallBackHigh", Vector3(6.0, 0.45, 0.2), Vector3(0.0, 2.58, -2.6), wall)
	_piece(room, body, "WallBackLeft", Vector3(0.4, 1.6, 0.2), Vector3(-2.8, 1.6, -2.6), wall)
	_piece(room, body, "WallBackRight", Vector3(2.4, 1.6, 0.2), Vector3(1.8, 1.6, -2.6), wall)
	# The heater under the window, ribbed.
	for i in 8:
		_box(room, "HeaterRib", Vector3(0.12, 0.55, 0.12), Vector3(-1.8 + i * 0.22, 0.35, -2.38), _set_paint(Color(0.85, 0.82, 0.78)))
	_add_collision(body, _box(room, "HeaterBox", Vector3(1.8, 0.55, 0.2), Vector3(-1.03, 0.35, -2.4), _set_paint(Color(0.85, 0.82, 0.78))))

	# The unmade bed along the left wall.
	_piece(room, body, "BedFrame", Vector3(1.1, 0.35, 2.1), Vector3(-2.4, 0.18, 1.3), _set_paint(Color(1, 1, 1), WOOD, 1.0))
	_box(room, "Mattress", Vector3(1.0, 0.2, 2.0), Vector3(-2.4, 0.45, 1.3), _set_paint(Color(0.92, 0.9, 0.86)))
	var blanket := _box(room, "Blanket", Vector3(1.05, 0.12, 1.3), Vector3(-2.35, 0.6, 1.6), _set_paint(Color.WHITE, BLANKET, 0.8))
	blanket.rotation = Vector3(0.05, 0.12, -0.04)
	_box(room, "Pillow", Vector3(0.7, 0.14, 0.4), Vector3(-2.45, 0.62, 0.45), _set_paint(Color(0.95, 0.85, 0.9)))

	# The desk in the back-right corner: an old CRT computer and a lava lamp.
	_piece(room, body, "Desk", Vector3(1.5, 0.08, 0.75), Vector3(2.15, 0.76, -1.95), _set_paint(Color(1, 1, 1), WOOD, 1.0))
	for leg: Vector3 in [Vector3(1.48, 0.36, -1.65), Vector3(2.82, 0.36, -1.65), Vector3(1.48, 0.36, -2.25), Vector3(2.82, 0.36, -2.25)]:
		_box(room, "DeskLeg", Vector3(0.06, 0.72, 0.06), leg, frame)
	_box(room, "Monitor", Vector3(0.5, 0.42, 0.45), Vector3(2.1, 1.02, -2.05), _set_paint(Color(0.85, 0.82, 0.74)))
	_box(room, "MonitorScreen", Vector3(0.4, 0.3, 0.02), Vector3(2.1, 1.03, -1.82), _set_paint(Color.WHITE, TERMINAL, 0.4, 1.4))
	_box(room, "Keyboard", Vector3(0.45, 0.03, 0.16), Vector3(2.05, 0.81, -1.7), _set_paint(Color(0.8, 0.78, 0.72)))
	_cylinder(room, "LavaLamp", 0.07, 0.4, Vector3(2.65, 1.0, -2.1), _set_paint(Color(0.85, 0.35, 1.0), null, 1.0, 1.5), Vector3.ZERO, 8)
	_piece(room, body, "Chair", Vector3(0.45, 0.45, 0.45), Vector3(1.95, 0.23, -1.2), _set_paint(Color(0.3, 0.3, 0.38)))
	_box(room, "ChairBack", Vector3(0.45, 0.5, 0.08), Vector3(1.95, 0.7, -0.98), _set_paint(Color(0.3, 0.3, 0.38)))

	# An old TV on a crate in the back-left corner.
	_piece(room, body, "TVCrate", Vector3(0.6, 0.5, 0.5), Vector3(-2.55, 0.25, -1.7), _set_paint(Color(1, 1, 1), WOOD, 0.6))
	_box(room, "TV", Vector3(0.55, 0.45, 0.45), Vector3(-2.55, 0.73, -1.7), _set_paint(Color(0.25, 0.22, 0.28)))
	_box(room, "TVScreen", Vector3(0.02, 0.32, 0.36), Vector3(-2.27, 0.74, -1.7), _set_paint(Color(0.35, 0.55, 0.9), null, 1.0, 1.2))

	# The photo on the wall (someone she misses), and a band poster.
	_box(room, "PhotoFrame", Vector3(0.5, 0.6, 0.04), Vector3(0.9, 1.65, -2.48), _set_paint(Color(1, 1, 1), WOOD, 0.5))
	_box(room, "Photo", Vector3(0.4, 0.5, 0.02), Vector3(0.9, 1.65, -2.45), _set_paint(Color.WHITE, PHOTO, 0.5, 0.15))
	_box(room, "PosterBacking", Vector3(0.02, 1.0, 0.75), Vector3(2.98, 1.7, 0.6), _set_paint(Color(0.2, 0.08, 0.25)))
	_sign(room, "Poster", "SPACE DUST\nWORLD TOUR\n'49", 0.0018, Color(1.0, 0.5, 0.75), Vector3(2.96, 1.7, 0.6))
	room.get_node("Poster").rotation = Vector3(0.0, -PI / 2.0, 0.0)

	# The rug and the socks. So many socks.
	_box(room, "Rug", Vector3(2.2, 0.02, 1.4), Vector3(0.1, 0.01, 0.4), _set_paint(Color.WHITE, BLANKET, 1.0))
	var sock_colors: Array[Color] = [Color(0.95, 0.95, 0.95), Color(0.9, 0.4, 0.5), Color(0.4, 0.7, 0.9), Color(0.95, 0.85, 0.3)]
	var socks: Array[Vector3] = [Vector3(-0.6, 0.0, 1.2), Vector3(0.8, 0.0, -0.6), Vector3(1.3, 0.0, 1.5), Vector3(-1.2, 0.0, -0.9), Vector3(0.2, 0.0, 1.9)]
	for i in socks.size():
		var sock := Node3D.new()
		sock.name = "Sock"
		sock.position = socks[i] + Vector3(0.0, 0.03, 0.0)
		sock.rotation = Vector3(0.0, i * 1.3, 0.0)
		room.add_child(sock, true)
		_box(sock, "Leg", Vector3(0.08, 0.04, 0.22), Vector3.ZERO, _set_paint(sock_colors[i % sock_colors.size()]))
		_box(sock, "Foot", Vector3(0.14, 0.04, 0.08), Vector3(0.03, 0.0, 0.13), _set_paint(sock_colors[i % sock_colors.size()]))
	_box(room, "PizzaBox", Vector3(0.45, 0.06, 0.45), Vector3(-0.9, 0.03, -0.3), _set_paint(Color(0.85, 0.72, 0.5)))

	# A plant in the corner by the door, doing its best.
	_piece(room, body, "PlantPot", Vector3(0.35, 0.4, 0.35), Vector3(2.6, 0.2, 2.1), _set_paint(Color(0.75, 0.4, 0.3)))
	for i in 5:
		var leaf := _box(room, "Leaf", Vector3(0.08, 0.5, 0.2), Vector3(2.6, 0.65, 2.1), _set_paint(Color(0.35, 0.7, 0.35)))
		leaf.rotation = Vector3(0.4, i * 1.25, 0.0)

	# The door to the hallway (front wall).
	_door_panel(room, "Door", Vector3(1.5, 1.1, 2.47), PI)

	# Light: a hanging lamp (warm), the TV and computer (cool), a pink neon
	# strip, and blue starlight through the window.
	_box(room, "LampCord", Vector3(0.02, 0.6, 0.02), Vector3(0.2, 2.5, 0.2), frame)
	_cylinder(room, "LampShade", 0.25, 0.25, Vector3(0.2, 2.1, 0.2), _set_paint(Color(1.0, 0.75, 0.45), null, 1.0, 1.0), Vector3.ZERO, 10)
	_lamp(room, "LampLight", Vector3(0.2, 1.9, 0.2), Color(1.0, 0.72, 0.45), 2.2, 6.0)
	_box(room, "NeonStrip", Vector3(0.05, 0.05, 4.6), Vector3(2.93, 2.65, 0.0), _set_paint(Color(1.0, 0.35, 0.75), null, 1.0, 1.6))
	_lamp(room, "NeonLight", Vector3(2.6, 2.3, 0.0), Color(1.0, 0.4, 0.75), 1.0, 4.5, false)
	_lamp(room, "WindowLight", Vector3(-1.0, 1.6, -2.0), Color(0.5, 0.6, 1.0), 1.0, 4.0, false)
	_lamp(room, "ScreenGlow", Vector3(2.1, 1.1, -1.5), Color(0.4, 1.0, 0.6), 0.5, 2.0, false)
	return room


# --- The hallway ------------------------------------------------------------------
# A long corridor (3 m wide, 20 m long), like the sketch: doors on both
# sides, pipes along the ceiling, and the dispatch door at the far end.

func _build_hallway() -> Node3D:
	var parts := _new_set("HallwaySet")
	var hall: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var length := 20.0
	var floor_material := _set_paint(Color(1, 1, 1), FLOOR_TILES, 1.2)
	var wall := _set_paint(Color(0.5, 0.55, 0.75), WALL_PANELS, 2.0)
	_room_shell(hall, body, Vector3(3.0, 3.2, length), floor_material, wall, _set_paint(Color(0.22, 0.22, 0.3)))
	for node in hall.get_children():
		if node is Node3D and node.name != "Collision":
			(node as Node3D).position.z -= length * 0.5  # Runs from z=0 to z=-20.
	for node in body.get_children():
		(node as Node3D).position.z -= length * 0.5

	# Doors along both walls (other people's apartments), with neon numbers.
	var neon_colors: Array[Color] = [Color(0.4, 0.95, 1.0), Color(1.0, 0.45, 0.8), Color(1.0, 0.8, 0.3), Color(0.5, 1.0, 0.5)]
	var doors := [[-1.0, 2.0, "5050"], [1.0, 6.0, "5051"], [-1.0, 10.0, "5052"], [1.0, 13.0, "5053"], [-1.0, 16.0, "5054"]]
	for i in doors.size():
		var side: float = doors[i][0]
		var z := -float(doors[i][1])
		_door_panel(hall, "Door", Vector3(1.47 * side, 1.1, z), -side * PI / 2.0)
		var number := Label3D.new()
		number.name = "DoorNumber"
		number.text = doors[i][2]
		number.font_size = 64
		number.pixel_size = 0.004
		number.modulate = neon_colors[i % neon_colors.size()]
		number.position = Vector3(1.44 * side, 2.45, z)
		number.rotation = Vector3(0.0, -side * PI / 2.0, 0.0)
		hall.add_child(number, true)
	# The end door: dispatch.
	_door_panel(hall, "DispatchDoor", Vector3(0.0, 1.1, -length + 0.03), 0.0)
	_sign(hall, "DispatchSign", "DISPATCH", 0.006, Color(1.0, 0.8, 0.3), Vector3(0.0, 2.6, -length + 0.1))

	# Pipes and cables along the ceiling.
	for pipe: Array in [[-1.3, 3.05, 0.07, Color(0.7, 0.4, 0.3)], [-1.1, 3.1, 0.05, Color(0.5, 0.55, 0.6)], [1.28, 3.05, 0.08, Color(0.55, 0.6, 0.5)]]:
		_cylinder(hall, "Pipe", pipe[2], length, Vector3(pipe[0], pipe[1], -length * 0.5), _set_paint(pipe[3]), ALONG_Z, 8)
	# Neon strips at waist height, and ceiling lights every 4 m.
	for side: float in [-1.0, 1.0]:
		_box(hall, "NeonStrip", Vector3(0.04, 0.05, length), Vector3(1.47 * side, 1.0, -length * 0.5), _set_paint(Color(0.35, 0.9, 1.0), null, 1.0, 2.0))
	for i in 5:
		var z := -2.0 - i * 4.0
		_box(hall, "CeilingLight", Vector3(1.0, 0.05, 0.5), Vector3(0.0, 3.17, z), _set_paint(Color(0.85, 0.95, 1.0), null, 1.0, 1.1))
		_lamp(hall, "Light", Vector3(0.0, 2.8, z), Color(0.8, 0.9, 1.0), 1.4, 5.0, i % 2 == 0)
	_lamp(hall, "DispatchGlow", Vector3(0.0, 2.2, -length + 1.0), Color(1.0, 0.8, 0.4), 1.0, 4.0, false)
	# A bit of life: a trash bag, a vending machine, a plant.
	_piece(hall, body, "VendingMachine", Vector3(0.9, 1.9, 0.7), Vector3(1.0, 0.95, -18.0), _set_paint(Color(0.85, 0.25, 0.3)))
	_box(hall, "VendingFront", Vector3(0.6, 1.2, 0.02), Vector3(0.95, 1.15, -17.64), _set_paint(Color(0.6, 0.9, 1.0), null, 1.0, 1.2))
	_piece(hall, body, "TrashBag", Vector3(0.5, 0.5, 0.5), Vector3(-1.1, 0.25, -7.5), _set_paint(Color(0.15, 0.15, 0.18)))
	_piece(hall, body, "PlantPot", Vector3(0.4, 0.45, 0.4), Vector3(1.15, 0.22, -0.8), _set_paint(Color(0.75, 0.4, 0.3)))
	for i in 5:
		var leaf := _box(hall, "Leaf", Vector3(0.08, 0.6, 0.22), Vector3(1.15, 0.75, -0.8), _set_paint(Color(0.35, 0.7, 0.35)))
		leaf.rotation = Vector3(0.4, i * 1.25, 0.0)
	return hall


# --- Dispatch ------------------------------------------------------------------------
# A tall room (10 x 9 m, 6 m high): the dispatch counter with the clerk on
# the left, a job board and waiting chairs, and on the right a staircase up
# to the door marked SHIP that leads to the hangar.

func _build_dispatch() -> Node3D:
	var parts := _new_set("DispatchSet")
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var wall := _set_paint(Color(0.45, 0.5, 0.7), WALL_PANELS, 2.5)
	var dark := _set_paint(Color(0.2, 0.2, 0.26))
	_room_shell(room, body, Vector3(10.0, 6.0, 9.0), _set_paint(Color(1, 1, 1), FLOOR_TILES, 1.2), wall, _set_paint(Color(0.2, 0.2, 0.28)))

	# The counter, with stuff on it, and a raised platform behind it so the
	# clerk can see over it.
	_piece(room, body, "Counter", Vector3(4.0, 0.85, 0.8), Vector3(-1.5, 0.43, -2.0), _set_paint(Color(0.85, 0.6, 0.35)))
	_box(room, "CounterTop", Vector3(4.2, 0.06, 0.95), Vector3(-1.5, 0.88, -2.0), _set_paint(Color(0.25, 0.25, 0.3)))
	_box(room, "CounterStripe", Vector3(4.02, 0.12, 0.02), Vector3(-1.5, 0.62, -1.59), _hazard(2.0))
	_piece(room, body, "ClerkPlatform", Vector3(4.4, 0.45, 1.8), Vector3(-1.5, 0.225, -3.3), _set_paint(Color(0.32, 0.32, 0.4)))
	_box(room, "DeskMonitor", Vector3(0.5, 0.4, 0.4), Vector3(-2.4, 1.12, -2.1), _set_paint(Color(0.85, 0.82, 0.74)))
	var screen := _box(room, "DeskScreen", Vector3(0.4, 0.3, 0.02), Vector3(-2.4, 1.13, -2.31), _set_paint(Color.WHITE, TERMINAL, 0.4, 1.4))
	screen.rotation = Vector3(0.0, PI, 0.0)
	_cylinder(room, "Mug", 0.05, 0.12, Vector3(-0.7, 0.97, -1.8), _set_paint(Color(0.95, 0.9, 0.85)), Vector3.ZERO, 8)
	_cylinder(room, "Bell", 0.06, 0.05, Vector3(-1.2, 0.93, -1.7), _set_paint(Color(0.9, 0.8, 0.4)), Vector3.ZERO, 8)
	_box(room, "Papers", Vector3(0.3, 0.04, 0.22), Vector3(-0.2, 0.93, -1.85), _set_paint(Color(0.96, 0.95, 0.9)))
	_box(room, "TicketMachine", Vector3(0.2, 0.3, 0.15), Vector3(0.3, 1.05, -1.75), _set_paint(Color(0.9, 0.3, 0.3)))
	# Behind the counter: the back wall's job board and a big neon sign.
	_box(room, "JobBoard", Vector3(2.6, 1.3, 0.05), Vector3(-1.5, 2.1, -4.47), _set_paint(Color.WHITE, JOB_BOARD, 2.6))
	_box(room, "SignBacking", Vector3(4.0, 1.1, 0.05), Vector3(-1.5, 3.55, -4.47), dark)
	_sign(room, "DispatchSign", "DISPATCH", 0.007, Color(1.0, 0.8, 0.3), Vector3(-1.5, 3.75, -4.4))
	_sign(room, "Motto", "WE MOVE IT SO YOU DON'T HAVE TO", 0.0025, Color(0.4, 0.95, 1.0), Vector3(-1.5, 3.2, -4.4))
	# Waiting chairs along the left wall, and a sad potted plant.
	for i in 3:
		_piece(room, body, "Chair", Vector3(0.55, 0.45, 0.55), Vector3(-4.5, 0.23, 1.0 + i * 0.8), _set_paint(Color(0.3, 0.6, 0.62)))
		_box(room, "ChairBack", Vector3(0.08, 0.5, 0.55), Vector3(-4.75, 0.7, 1.0 + i * 0.8), _set_paint(Color(0.3, 0.6, 0.62)))
	_piece(room, body, "PlantPot", Vector3(0.45, 0.5, 0.45), Vector3(-4.5, 0.25, -0.2), _set_paint(Color(0.75, 0.4, 0.3)))
	for i in 5:
		var leaf := _box(room, "Leaf", Vector3(0.1, 0.7, 0.25), Vector3(-4.5, 0.85, -0.2), _set_paint(Color(0.35, 0.7, 0.35)))
		leaf.rotation = Vector3(0.45, i * 1.25, 0.0)
	# The door back to the hallway (front-left).
	_door_panel(room, "HallwayDoor", Vector3(-3.5, 1.1, 4.47), PI)

	# The staircase up to the SHIP door (right side): 8 solid steps, then a landing.
	var steps := 8
	var rise := 2.4 / steps
	var run := 0.6
	for i in steps:
		var height := rise * (i + 1)
		_box(room, "Step", Vector3(2.6, height, run), Vector3(3.6, height * 0.5, 2.2 - i * run), _set_paint(Color(0.5, 0.53, 0.62), FLOOR_TILES, 1.2))
		_box(room, "StepEdge", Vector3(2.6, 0.03, 0.06), Vector3(3.6, height + 0.01, 2.2 - i * run - run * 0.5 + 0.03), _hazard(4.0))
	# Collision for the stairs is a smooth ramp, so walking up feels nice.
	var ramp := CollisionShape3D.new()
	ramp.name = "StairRamp"
	var ramp_box := BoxShape3D.new()
	var ramp_length := Vector2(steps * run, 2.4).length()
	ramp_box.size = Vector3(2.6, 0.1, ramp_length)
	ramp.shape = ramp_box
	ramp.position = Vector3(3.6, 1.2, 2.5 - steps * run * 0.5)
	ramp.rotation = Vector3(atan2(2.4, steps * run), 0.0, 0.0)
	body.add_child(ramp, true)
	_piece(room, body, "Landing", Vector3(2.6, 2.4, 2.2), Vector3(3.6, 1.2, -3.4), _set_paint(Color(0.5, 0.53, 0.62), FLOOR_TILES, 1.2))
	# An invisible wall beside the stairs, so you can't walk into them from the side.
	var side_wall := CollisionShape3D.new()
	side_wall.name = "StairSide"
	var side_box := BoxShape3D.new()
	side_box.size = Vector3(0.15, 2.4, 3.4)
	side_wall.shape = side_box
	side_wall.position = Vector3(2.25, 1.2, -0.6)
	body.add_child(side_wall, true)
	var rail := _set_paint(Color(1.0, 0.8, 0.2))
	_beam(room, "Railing", Vector3(2.3, 1.0, 2.5), Vector3(2.3, 3.4, -2.3), 0.06, rail)
	_beam(room, "LandingRailing", Vector3(2.3, 3.4, -2.3), Vector3(2.3, 3.4, -4.5), 0.06, rail)
	# An invisible wall along the landing's open edge, so nobody falls off.
	var edge := CollisionShape3D.new()
	edge.name = "LandingEdge"
	var edge_box := BoxShape3D.new()
	edge_box.size = Vector3(0.15, 1.2, 2.2)
	edge.shape = edge_box
	edge.position = Vector3(2.3, 3.0, -3.4)
	body.add_child(edge, true)
	# The ship door at the top, with a big sign.
	_door_panel(room, "ShipDoor", Vector3(3.6, 3.5, -4.47), 0.0)
	_sign(room, "ShipSign", "SHIP", 0.01, Color(0.4, 0.95, 1.0), Vector3(3.6, 5.0, -4.4))
	_box(room, "ShipSignBacking", Vector3(1.6, 0.8, 0.05), Vector3(3.6, 5.0, -4.47), dark)

	# Lights: warm over the counter, cool over the stairs, neon by the signs.
	_lamp(room, "CounterLight", Vector3(-1.5, 3.2, -1.0), Color(1.0, 0.8, 0.55), 2.5, 7.0)
	_lamp(room, "StairsLight", Vector3(3.2, 5.0, -1.0), Color(0.6, 0.85, 1.0), 2.0, 7.0)
	_lamp(room, "SignGlow", Vector3(-1.5, 3.8, -3.8), Color(1.0, 0.7, 0.3), 1.2, 4.0, false)
	_lamp(room, "LobbyFill", Vector3(-2.5, 4.0, 3.0), Color(0.75, 0.6, 1.0), 1.2, 8.0, false)
	for i in 3:
		_box(room, "CeilingLight", Vector3(1.6, 0.05, 0.6), Vector3(-2.0 + i * 3.0, 5.97, 0.0), _set_paint(Color(0.9, 0.95, 1.0), null, 1.0, 1.4))
	return room
