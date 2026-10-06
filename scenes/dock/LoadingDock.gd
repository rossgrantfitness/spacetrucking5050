class_name LoadingDock
extends Node3D
## LOADING THE RIG yourself: a station's loading dock, in 3D. Your rig is
## backed up to the dock with its hold open at the far end. Walk to the
## forklift (E climbs on), drive it (stick / W A S D), slide the forks under
## a pallet and lift it (E), drive it into the hold and set it down (E) on
## one of the glowing spots. F / X climbs off. Fill every spot and the load
## is snug: the cargo takes less of a knock until you deliver it. Esc / B
## lets the dock crew finish (no snug load, no fuss). Nothing fails.
##
## It's chosen when you take a job (HubServices.load_cargo), and afterwards
## you're back where you were. The dock is built from simple shapes in
## _build_dock(); the forklift is Forklift.gd.


const PLAYER_SCENE := preload("res://scenes/hub/Player.tscn")
const PALLET_SIZE := Vector3(1.2, 0.95, 1.0)
## The hold: its floor, from the open door (z = HOLD_DOOR_Z) back.
const HOLD_DOOR_Z: float = -8.0
const HOLD_DEPTH: float = 7.0
const HOLD_WIDTH: float = 7.0
## How close a pallet has to be set down to a spot to snap into it.
const SNAP_DISTANCE: float = 1.0
const CRATE_COLORS: Array[Color] = [Color("e07a3a"), Color("4f8fc4"), Color("c9b44a"), Color("78b06a"), Color("c66a9e"), Color("8e7ad1")]

var forklift: Forklift
var player: HubPlayer
var pallets: Array[Node3D] = []
## The spots in the hold (their middles), and which pallet is in each.
var spots: PackedVector3Array = PackedVector3Array()
var spot_pallets: Array = []
var bumps: int = 0
var seconds: float = 0.0
var done := false

var _camera: Camera3D
var _hud: HubHUD
var _info: Label
var _note: Label
var _note_left: float = 0.0
var _spot_lights: Array[MeshInstance3D] = []
var _leaving := false


func _ready() -> void:
	Radio.set_context(Radio.Context.ROOM)
	_build_dock()
	_spawn_pallets(clampi(GameState.dock_pallets, 1, 6))
	forklift = Forklift.new()
	forklift.name = "Forklift"
	forklift.position = Vector3(0.0, 0.0, 1.5)
	add_child(forklift)
	forklift.happened.connect(_on_forklift)
	var climb_on := Interactable.new()
	climb_on.name = "ClimbOn"
	climb_on.prompt = "DRIVE THE FORKLIFT"
	var reach := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.8
	reach.shape = sphere
	reach.position = Vector3(0.0, 1.0, 0.3)
	climb_on.add_child(reach)
	forklift.add_child(climb_on)
	climb_on.interacted.connect(func(_who: Node3D) -> void: _climb_on())
	player = PLAYER_SCENE.instantiate() as HubPlayer
	add_child(player)
	player.global_position = Vector3(2.6, 0.0, 4.5)
	player.face(PI * 0.25)
	_camera = Camera3D.new()
	_camera.fov = 60.0
	add_child(_camera)
	_camera.make_current()
	_place_camera(1.0)
	_hud = HubHUD.new()
	_hud.player = player
	add_child(_hud)
	_build_overlay()
	_say("WALK OVER TO THE FORKLIFT AND PRESS E", 4.0)


func _process(delta: float) -> void:
	if not done:
		seconds += delta
	_note_left = maxf(_note_left - delta, 0.0)
	_note.visible = _note_left > 0.0
	_info.text = "LOADED %d / %d" % [loaded(), pallets.size()]
	_place_camera(delta)
	for i in _spot_lights.size():
		var filled := spot_pallets[i] != null
		var glow := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 300.0) if not filled else 1.0
		((_spot_lights[i].mesh as BoxMesh).material as ShaderMaterial).set_shader_parameter("emission_strength", glow * (2.0 if filled else 1.4))


func _physics_process(delta: float) -> void:
	if forklift.driver != null and not _leaving and not done:
		var throttle := Input.get_axis("move_back", "move_forward")
		var steer := Input.get_axis("move_left", "move_right")
		forklift.drive(delta, throttle, steer)
	elif forklift.driver == null:
		forklift.drive(delta, 0.0, 0.0)  # (Rolls to a stop, keeps the forks moving.)


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_ask_to_leave()
		return
	if forklift.driver == null or done:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		forklift.use_forks(_pickable())
	elif event.is_action_pressed("get_up"):
		get_viewport().set_input_as_handled()
		_climb_off()


## How many pallets are in spots in the hold.
func loaded() -> int:
	var count := 0
	for pallet: Variant in spot_pallets:
		if pallet != null:
			count += 1
	return count


## The pallets that can be lifted (not already in a spot).
func _pickable() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for pallet in pallets:
		if not pallet.has_meta("spot"):
			found.append(pallet)
	return found


func _climb_on() -> void:
	if forklift.driver != null:
		return
	forklift.seat(player)
	_hud.player = null
	Sfx.play("door", -4.0, 0.7)
	_say("W/S DRIVE  ·  A/D STEER  ·  E FORKS  ·  F CLIMB OFF", 5.0)


func _climb_off() -> void:
	if forklift.carrying != null:
		_say("SET THE PALLET DOWN FIRST", 2.0)
		return
	forklift.unseat(self)
	_hud.player = player
	Sfx.play("door", -4.0, 0.9)


func _on_forklift(what: String, pallet: Node3D) -> void:
	match what:
		"lift":
			Sfx.play("ui_move", 0.0, 0.7)
			_say("INTO THE HOLD WITH IT", 2.0)
		"no_pallet":
			_say("SLIDE THE FORKS RIGHT UNDER A PALLET", 2.0)
		"bump":
			bumps += 1
			Sfx.play("door", -8.0, 0.4)
		"drop":
			_on_set_down(pallet)


func _on_set_down(pallet: Node3D) -> void:
	var best := -1
	var best_distance := SNAP_DISTANCE
	for i in spots.size():
		var distance := Vector2(pallet.global_position.x, pallet.global_position.z).distance_to(Vector2(spots[i].x, spots[i].z))
		if spot_pallets[i] == null and distance < best_distance:
			best = i
			best_distance = distance
	if best < 0:
		Sfx.play("ui_move", 0.0, 0.5)
		if pallet.global_position.z < HOLD_DOOR_Z:
			_say("A LITTLE CLOSER TO A GLOWING SPOT", 2.0)
		return
	spot_pallets[best] = pallet
	pallet.set_meta("spot", best)
	var tween := create_tween()
	tween.tween_property(pallet, "global_position", spots[best], 0.2)
	tween.parallel().tween_property(pallet, "rotation", Vector3.ZERO, 0.2)
	Sfx.play("ui_confirm")
	if loaded() == pallets.size():
		_finish()
	else:
		_say("%d OF %d LOADED" % [loaded(), pallets.size()], 2.0)


func _finish() -> void:
	done = true
	Sfx.play("job_accept")
	GameState.rig["snug"] = 1.0
	var gentler := roundi((1.0 - GameState.tuning.snug_load_care) * 100.0)
	await get_tree().create_timer(1.0).timeout
	await MenuPanel.ask(get_tree(), "SNUG LOAD", "All loaded in %s%s. Strapped down tight: your cargo takes %d%% less of a knock until you deliver it." % [
			HudWidget.clock(seconds), (", %d bump%s" % [bumps, "" if bumps == 1 else "s"]) if bumps > 0 else ", not a single bump", gentler],
			[{"text": "NICE"}])
	_go_back()


func _ask_to_leave() -> void:
	var choice := await MenuPanel.ask(get_tree(), "LOADING DOCK", "%d of %d loaded." % [loaded(), pallets.size()], [
		{"text": "KEEP LOADING", "description": "Back to it."},
		{"text": "LET THE CREW FINISH", "description": "They'll have it aboard in no time. (No snug load.)"}])
	if choice == 1:
		_go_back()


## Back to where she was before the dock.
func _go_back() -> void:
	if _leaving:
		return
	_leaving = true
	GameState.next_spawn = "@return"
	var back := GameState.return_scene if not GameState.return_scene.is_empty() else "res://scenes/hub/TruckStop.tscn"
	LoadingScreen.go(get_tree(), back, "start")


func _say(words: String, seconds_shown: float) -> void:
	_note.text = words
	_note_left = seconds_shown


## Behind and above her on foot (the view keeps pointing at the rig, so
## "up" always walks toward the hold); behind the forklift when driving.
func _place_camera(delta: float) -> void:
	var where: Vector3
	var look_at_spot: Vector3
	if forklift.driver != null:
		var back := forklift.global_basis.z
		where = forklift.global_position + back * 6.5 + Vector3.UP * 4.0
		look_at_spot = forklift.global_position - back * 2.0 + Vector3.UP * 0.8
	else:
		where = player.global_position + Vector3(0.0, 4.5, 6.5)
		look_at_spot = player.global_position + Vector3(0.0, 0.8, -1.5)
	var blend := 1.0 - exp(-4.0 * delta)
	_camera.global_position = _camera.global_position.lerp(where, blend) if delta < 1.0 else where
	var wanted := _camera.global_transform.looking_at(look_at_spot, Vector3.UP)
	_camera.global_basis = _camera.global_basis.slerp(wanted.basis, blend) if delta < 1.0 else wanted.basis


# --- Building the dock ---------------------------------------------------------------

func _build_dock() -> void:
	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color(0.02, 0.02, 0.05)
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.62, 0.64, 0.78)
	sky.ambient_light_energy = 1.5
	environment.environment = sky
	add_child(environment)
	var psx := PSXScreen.new()
	psx.layer = 0
	add_child(psx)
	for spot: Vector3 in [Vector3(-7.0, 5.0, -2.0), Vector3(7.0, 5.0, -2.0), Vector3(-7.0, 5.0, 8.0), Vector3(7.0, 5.0, 8.0), Vector3(0.0, 5.0, 3.0)]:
		var lamp := OmniLight3D.new()
		lamp.position = spot
		lamp.omni_range = 18.0
		lamp.light_energy = 2.2
		lamp.light_color = Color(1.0, 0.85, 0.65)
		add_child(lamp)
	var floor_color := Color(0.34, 0.36, 0.42)
	var wall_color := Color(0.3, 0.32, 0.42)
	# The dock: a floor and walls, with the rig's open hold at the far end.
	_solid(Vector3(26.0, 0.2, 22.0), Vector3(0.0, -0.1, 3.0), floor_color)
	_solid(Vector3(26.0, 6.0, 0.3), Vector3(0.0, 3.0, 14.0), wall_color)  # The back wall.
	for x: float in [-13.0, 13.0]:
		_solid(Vector3(0.3, 6.0, 22.0), Vector3(x, 3.0, 3.0), wall_color)
	var front_side := (26.0 - HOLD_WIDTH) * 0.5
	for x: float in [-1.0, 1.0]:
		_solid(Vector3(front_side, 6.0, 0.3), Vector3(x * (HOLD_WIDTH * 0.5 + front_side * 0.5), 3.0, HOLD_DOOR_Z), wall_color)
	_solid(Vector3(HOLD_WIDTH, 2.2, 0.3), Vector3(0.0, 4.9, HOLD_DOOR_Z), wall_color)  # Over the door.
	# Painted lane lines on the dock floor, and neon strips on the walls.
	for x: float in [-3.5, 3.5]:
		_box(Vector3(0.15, 0.02, 17.0), Vector3(x, 0.01, 4.5), Color(1.0, 0.82, 0.2), true, 0.6)
	for x: float in [-12.8, 12.8]:
		_box(Vector3(0.08, 0.12, 20.0), Vector3(x, 4.2, 3.0), Color(0.4, 0.9, 1.0), true, 2.0)
	_box(Vector3(26.0, 0.12, 0.08), Vector3(0.0, 4.2, 13.8), Color(1.0, 0.4, 0.8), true, 2.0)
	# Dock clutter: stacked crates, barrels, and a big painted dock number.
	for spot: Vector3 in [Vector3(-11.5, 0.0, 12.0), Vector3(-11.5, 0.0, 9.5), Vector3(11.5, 0.0, 12.0), Vector3(11.0, 0.0, -5.5)]:
		for level in 2:
			_solid(Vector3(1.6, 1.2, 1.6), spot + Vector3(0.0, 0.6 + level * 1.2, 0.0), Color(0.55, 0.42, 0.28) if level == 0 else Color(0.42, 0.5, 0.62))
	for spot: Vector3 in [Vector3(-11.8, 0.0, -6.5), Vector3(-10.8, 0.0, -6.8), Vector3(11.8, 0.0, 6.0)]:
		var barrel := StaticBody3D.new()
		barrel.position = spot + Vector3(0.0, 0.55, 0.0)
		add_child(barrel)
		var barrel_shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = 0.4
		cylinder.height = 1.1
		barrel_shape.shape = cylinder
		barrel.add_child(barrel_shape)
		Forklift._cylinder(barrel, 0.4, 1.1, Vector3.ZERO, Color(0.85, 0.3, 0.2), Vector3.ZERO)
	_box(Vector3(2.4, 0.02, 2.4), Vector3(0.0, 0.012, 9.5), Color(1.0, 0.82, 0.2), true, 0.5)  # The pickup bay.
	# Your rig's hold: a box with the back doors open, hazard stripes round the door.
	var hold_middle_z := HOLD_DOOR_Z - HOLD_DEPTH * 0.5
	var hold_color := Color(0.3, 0.32, 0.38)
	_solid(Vector3(HOLD_WIDTH, 0.2, HOLD_DEPTH), Vector3(0.0, -0.1, hold_middle_z), Color(0.28, 0.28, 0.3))
	for x: float in [-1.0, 1.0]:
		_solid(Vector3(0.25, 3.8, HOLD_DEPTH), Vector3(x * HOLD_WIDTH * 0.5, 1.9, hold_middle_z), hold_color)
	_solid(Vector3(HOLD_WIDTH, 3.8, 0.25), Vector3(0.0, 1.9, HOLD_DOOR_Z - HOLD_DEPTH), hold_color)
	_box(Vector3(HOLD_WIDTH, 0.2, HOLD_DEPTH), Vector3(0.0, 3.85, hold_middle_z), hold_color, false, 0.0)
	for x: float in [-1.0, 1.0]:
		for k in 8:
			_box(Vector3(0.3, 0.42, 0.32), Vector3(x * (HOLD_WIDTH * 0.5 - 0.05), 0.25 + k * 0.48, HOLD_DOOR_Z + 0.05), Color(1.0, 0.8, 0.1) if k % 2 == 0 else Color(0.1, 0.1, 0.1), false, 0.0)
	_box(Vector3(HOLD_WIDTH * 0.9, 0.12, 0.12), Vector3(0.0, 3.6, hold_middle_z), Color(1.0, 0.9, 0.7), true, 2.0)  # A strip light inside.
	var inside := OmniLight3D.new()
	inside.position = Vector3(0.0, 3.2, hold_middle_z)
	inside.omni_range = 7.0
	inside.light_energy = 1.2
	add_child(inside)


## The pallets waiting on the dock, and a glowing spot in the hold for each.
func _spawn_pallets(count: int) -> void:
	var columns := 2
	var rows := ceili(count / float(columns))
	for i in count:
		var column := i % columns
		var row := floori(i / float(columns))
		var z := HOLD_DOOR_Z - HOLD_DEPTH + 1.0 + row * ((HOLD_DEPTH - 2.0) / maxf(rows - 1, 1)) if rows > 1 else HOLD_DOOR_Z - HOLD_DEPTH * 0.55
		spots.append(Vector3(-1.5 if column == 0 else 1.5, 0.0, z))
		spot_pallets.append(null)
		_spot_lights.append(_box(Vector3(1.35, 0.02, 1.15), Vector3(spots[i].x, 0.012, z), Color(1.0, 0.85, 0.3), true, 1.4))
	for i in count:
		var pallet := StaticBody3D.new()
		pallet.name = "Pallet%d" % i
		pallet.position = Vector3(-6.0 + (i % 4) * 4.0, 0.0, 8.0 + floori(i / 4.0) * 3.0)
		pallet.rotation.y = randf_range(-0.25, 0.25)
		add_child(pallet)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = PALLET_SIZE
		shape.shape = box
		shape.position = Vector3(0.0, PALLET_SIZE.y * 0.5, 0.0)
		pallet.add_child(shape)
		var color := CRATE_COLORS[i % CRATE_COLORS.size()]
		Forklift._box(pallet, Vector3(1.2, 0.14, 1.0), Vector3(0.0, 0.07, 0.0), Color(0.48, 0.34, 0.2))  # The wooden pallet.
		Forklift._box(pallet, Vector3(1.0, 0.75, 0.9), Vector3(0.0, 0.53, 0.0), color)  # The crate.
		Forklift._box(pallet, Vector3(1.02, 0.08, 0.92), Vector3(0.0, 0.62, 0.0), color.darkened(0.45))  # A strap.
		pallets.append(pallet)


func _solid(size: Vector3, where: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = where
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	Forklift._box(body, size, Vector3.ZERO, color)


func _box(size: Vector3, where: Vector3, color: Color, glowing: bool, strength: float) -> MeshInstance3D:
	var part := Forklift._box(self, size, where, color, glowing)
	if glowing:
		((part.mesh as BoxMesh).material as ShaderMaterial).set_shader_parameter("emission_strength", strength)
	return part


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	_info = Label.new()
	_info.position = Vector2(24.0, 20.0)
	_info.add_theme_font_size_override("font_size", 26)
	_info.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	layer.add_child(_info)
	_note = Label.new()
	_note.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_note.position = Vector2(-500.0, -150.0)
	_note.size = Vector2(1000.0, 40.0)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_font_size_override("font_size", 24)
	layer.add_child(_note)
