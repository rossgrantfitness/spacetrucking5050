extends "res://tools/build_truck_stop.gd"
## Builds the OrbitalEx regional office (through the glass doors on the
## truck stop's front wall). (Bonnie the receptionist, the boss and his
## coworker are the developer's models, in res://art/models/.)
##     res://scenes/hub/sets/OrbitalExOfficeSet.tscn - the room: an entryway
##         with the greeter's desk, a lobby down a red carpet, and the
##         boss's desk at the far end under a giant glowing logo
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_office.gd
##
## Careful: running it again OVERWRITES those scenes. The room itself
## (res://scenes/hub/OrbitalExOffice.tscn, with its cameras, doors, people
## and things to use) is NOT touched.


func _initialize() -> void:
	_animator_script = load(ANIMATOR_PATH)
	_blinker_script = load(BLINKER_SCRIPT_PATH)
	_save(_build_office(), "res://scenes/hub/sets/OrbitalExOfficeSet.tscn")
	quit()


# --- The office -------------------------------------------------------------------
# 10 x 24 m, 7 m tall, one long axis so the cameras can look down it.
# Front (+Z) is the glass doors back to the truck stop. Then:
#   z +11 to +5: the ENTRYWAY, Bonnie's desk on the right
#   z  +5 to -5: the LOBBY, pillars either side of a red carpet
#   z  -5 to -12: the BOSS's desk on a low platform, under a giant
#                 glowing OrbitalEx logo, with windows onto space

func _build_office() -> Node3D:
	var parts := _new_set("OrbitalExOfficeSet")
	var room: Node3D = parts[0]
	var body: StaticBody3D = parts[1]
	var wall := _set_paint(Color(0.3, 0.32, 0.5), WALL_PANELS, 3.0)
	var dark := _set_paint(Color(0.07, 0.07, 0.12))
	var gold := _set_paint(Color(1.0, 0.75, 0.3), null, 1.0, 1.4)
	_room_shell(room, body, Vector3(10.0, 7.0, 24.0), _set_paint(Color(0.5, 0.52, 0.66), FLOOR_TILES, 1.2), wall, _set_paint(Color(0.05, 0.05, 0.09)))
	_box(room, "Carpet", Vector3(2.0, 0.02, 19.5), Vector3(0.0, 0.011, 1.5), _set_paint(Color(0.85, 0.15, 0.2), CARPET, 0.8))
	for side: float in [-1.0, 1.0]:
		_box(room, "CarpetTrim", Vector3(0.08, 0.025, 19.5), Vector3(1.04 * side, 0.012, 1.5), gold)
	_entryway(room, body, dark)
	_lobby(room, body, dark)
	_boss_end(room, body, dark, gold)
	_office_lights(room)
	return room


## The glass doors back out, and Bonnie's desk.
func _entryway(room: Node3D, body: StaticBody3D, dark: Material) -> void:
	_box(room, "DoorGlow", Vector3(3.0, 2.8, 0.05), Vector3(0.0, 1.4, 11.88), _set_paint(Color(0.45, 0.95, 1.0), null, 1.0, 0.6))
	for side: float in [-1.0, 1.0]:
		_box(room, "GlassDoor", Vector3(1.2, 2.5, 0.06), Vector3(0.62 * side, 1.25, 11.84), _set_paint(Color(0.75, 0.95, 1.0), null, 1.0, 1.0))
	_box(room, "DoorHeader", Vector3(3.4, 0.3, 0.2), Vector3(0.0, 2.95, 11.8), dark)
	_sign(room, "ExitSign", "TRUCK STOP", 0.003, Color(0.45, 0.95, 1.0), Vector3(0.0, 3.3, 11.78))
	(room.get_node("ExitSign") as Node3D).rotation = Vector3(0.0, PI, 0.0)
	# Bonnie's desk: long, white, a cyan glow strip, a little bell.
	_piece(room, body, "GreeterDesk", Vector3(0.8, 0.7, 2.6), Vector3(3.0, 0.35, 7.5), _set_paint(Color(0.9, 0.92, 0.95)))
	_box(room, "GreeterDeskTop", Vector3(1.0, 0.06, 2.8), Vector3(3.0, 0.73, 7.5), _set_paint(Color(0.2, 0.55, 0.85)))
	_box(room, "GreeterDeskGlow", Vector3(0.04, 0.1, 2.5), Vector3(2.58, 0.55, 7.5), _set_paint(Color(0.45, 0.95, 1.0), null, 1.0, 2.0))
	_cylinder(room, "DeskBell", 0.07, 0.07, Vector3(2.85, 0.8, 6.8), _set_paint(Color(1.0, 0.8, 0.35)), Vector3.ZERO, 8)
	_box(room, "GreeterSignBack", Vector3(3.2, 0.8, 0.1), Vector3(3.0, 3.6, 11.85), dark)
	_sign(room, "GreeterSign", "WELCOME TO ORBITALEX", 0.0035, Color(1.0, 0.8, 0.3), Vector3(3.0, 3.65, 11.78))
	(room.get_node("GreeterSign") as Node3D).rotation = Vector3(0.0, PI, 0.0)


## Pillars with neon strips, waiting chairs nobody waits in, a plant.
func _lobby(room: Node3D, body: StaticBody3D, dark: Material) -> void:
	for z: float in [4.0, -1.0, -6.0]:
		for side: float in [-1.0, 1.0]:
			_piece(room, body, "Pillar", Vector3(0.8, 7.0, 0.8), Vector3(3.3 * side, 3.5, z), _set_paint(Color(0.38, 0.4, 0.6), WALL_PANELS, 2.0))
			_box(room, "PillarNeon", Vector3(0.06, 5.0, 0.06), Vector3(3.3 * side - 0.42 * side, 3.0, z), _set_paint(Color(0.45, 0.95, 1.0), null, 1.0, 2.2))
	for i in 4:
		_piece(room, body, "WaitingChair", Vector3(0.7, 0.5, 0.7), Vector3(-4.3, 0.25, 2.6 - i * 0.9), _set_paint(Color(0.55, 0.2, 0.3)))
		_box(room, "WaitingChairBack", Vector3(0.12, 0.7, 0.7), Vector3(-4.6, 0.85, 2.6 - i * 0.9), _set_paint(Color(0.55, 0.2, 0.3)))
	_cylinder(room, "PlantPot", 0.3, 0.6, Vector3(-4.2, 0.3, 6.0), _set_paint(Color(0.8, 0.42, 0.25)), Vector3.ZERO, 8)
	_box(room, "PlantLeaves", Vector3(0.8, 1.0, 0.8), Vector3(-4.2, 1.1, 6.0), _set_paint(Color(0.3, 0.75, 0.35)))
	_box(room, "PosterFrame", Vector3(0.08, 1.6, 2.4), Vector3(-4.93, 2.6, 0.5), dark)
	_sign(room, "Poster", "WE DELIVER.\nYOU PAY.", 0.004, Color(1.0, 0.45, 0.4), Vector3(-4.86, 2.6, 0.5))
	(room.get_node("Poster") as Node3D).rotation = Vector3(0.0, PI / 2.0, 0.0)
	_box(room, "CoolerBody", Vector3(0.5, 1.1, 0.5), Vector3(4.4, 0.55, 2.5), _set_paint(Color(0.9, 0.92, 0.95)))
	_cylinder(room, "CoolerJug", 0.2, 0.5, Vector3(4.4, 1.35, 2.5), _set_paint(Color(0.4, 0.8, 1.0), null, 1.0, 0.6), Vector3.ZERO, 8)


## The platform, the big desk, and the logo wall behind it.
func _boss_end(room: Node3D, body: StaticBody3D, dark: Material, gold: Material) -> void:
	_piece(room, body, "Platform", Vector3(10.0, 0.3, 3.0), Vector3(0.0, 0.15, -10.5), _set_paint(Color(0.12, 0.1, 0.16), WOOD, 1.2))
	_box(room, "PlatformEdge", Vector3(10.0, 0.04, 0.08), Vector3(0.0, 0.3, -9.0), gold)
	_piece(room, body, "BossDesk", Vector3(3.8, 0.85, 1.2), Vector3(0.0, 0.43, -8.4), _set_paint(Color(0.36, 0.2, 0.12), WOOD, 1.0))
	_box(room, "BossDeskTop", Vector3(4.0, 0.08, 1.4), Vector3(0.0, 0.89, -8.4), _set_paint(Color(0.12, 0.08, 0.06)))
	_box(room, "BossDeskTrim", Vector3(3.8, 0.06, 0.04), Vector3(0.0, 0.7, -7.78), gold)
	_box(room, "Nameplate", Vector3(0.9, 0.16, 0.06), Vector3(0.6, 1.01, -7.95), gold)
	_cylinder(room, "Mug", 0.07, 0.16, Vector3(-0.9, 1.01, -8.3), _set_paint(Color(0.95, 0.95, 0.9)), Vector3.ZERO, 8)
	_box(room, "Paperwork", Vector3(0.6, 0.25, 0.45), Vector3(-1.4, 1.05, -8.5), _set_paint(Color(0.95, 0.95, 0.88)))
	_box(room, "BossChairBack", Vector3(0.9, 1.0, 0.2), Vector3(0.0, 0.9, -10.1), _set_paint(Color(0.55, 0.12, 0.15)))
	# The logo wall: one huge glowing slab with the name across it.
	_box(room, "LogoGlow", Vector3(7.0, 3.6, 0.1), Vector3(0.0, 4.4, -11.88), _set_paint(Color(1.0, 0.55, 0.2), null, 1.0, 1.1))
	_box(room, "LogoBand", Vector3(7.4, 0.12, 0.12), Vector3(0.0, 2.55, -11.82), gold)
	_sign(room, "Logo", "ORBITALEX", 0.0105, Color(1.0, 0.95, 0.85), Vector3(0.0, 4.7, -11.8))
	_sign(room, "LogoSub", "WE DELIVER", 0.004, Color(0.2, 0.08, 0.04), Vector3(0.0, 3.5, -11.8))
	for side: float in [-1.0, 1.0]:
		_space_picture(room, "Window", Vector2(1.4, 4.0), Vector3(4.2 * side, 3.4, -11.88), 0.0)
		_box(room, "WindowFrame", Vector3(1.6, 4.2, 0.08), Vector3(4.2 * side, 3.4, -11.92), dark)


func _office_lights(room: Node3D) -> void:
	_lamp(room, "EntryLight", Vector3(1.5, 5.5, 8.5), Color(0.6, 0.9, 1.0), 3.0, 11.0)
	_lamp(room, "LobbyLeft", Vector3(-2.5, 5.0, 1.0), Color(0.75, 0.65, 1.0), 2.6, 11.0, false)
	_lamp(room, "LobbyRight", Vector3(2.5, 5.0, -3.0), Color(0.5, 0.95, 1.0), 2.6, 11.0, false)
	# Backlit: the logo throws the boss into silhouette, and the desk lamp
	# picks out his face.
	_lamp(room, "LogoLight", Vector3(0.0, 4.0, -11.0), Color(1.0, 0.6, 0.25), 3.0, 11.0)
	_lamp(room, "DeskLamp", Vector3(0.0, 3.0, -6.5), Color(1.0, 0.9, 0.7), 2.2, 7.0, false)
	for z: float in [8.0, 1.5, -5.0]:
		_box(room, "CeilingStrip", Vector3(1.2, 0.08, 0.3), Vector3(0.0, 6.95, z), _set_paint(Color(0.85, 1.0, 1.0), null, 1.0, 1.6))
