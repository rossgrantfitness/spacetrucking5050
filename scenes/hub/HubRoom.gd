class_name HubRoom
extends Node3D
## One room of the base, shown with fixed camera angles and pre-rendered
## backgrounds, like Final Fantasy VIII or Dino Crisis.
##
## HOW A ROOM SCENE IS LAID OUT (see Apartment.tscn):
##   Set       - the room's look: furniture, walls, lights (and a "Collision"
##               body for the walls and floor). Built by tools/build_hub.gd.
##   Shots     - RoomShot nodes: a camera angle each, plus the zone where it's used.
##   Spawns    - Marker3D spots where the bunny can arrive (named, like "FromHallway").
##   Exits     - RoomExit doorways to other rooms.
##   People    - NPCs standing around.
##
## HOW THE PRE-RENDERING WORKS: when the room loads (behind a black fade),
## each camera angle's view of the Set is painted once into a picture, with
## all the fancy lighting and shadows. Then the Set's shapes switch to a
## shader that just shows that picture (prerendered_backdrop.gdshader). It
## looks like a painted background, but the shapes still hide the bunny when
## she walks behind things. The bunny and the people are drawn live on top,
## wobbly PS1 models in front of a crisp painting, just like back then.


const BACKDROP_SHADER := preload("res://shaders/prerendered_backdrop.gdshader")
const PLAYER_SCENE := preload("res://scenes/hub/Player.tscn")
## Visual layer 2 holds the Set (what gets painted); layer 1 holds people.
const SET_LAYER: int = 2

## The spawn spot to use when nobody said where to arrive (like a new game).
@export var default_spawn: String = ""
## Which place this room belongs to (a place id from res://data/places/,
## like "base" or "truck_stop"): its job board lists jobs from here.
@export var place_id: String = "base"
## Whether the radio plays through this room's speakers (the jukebox).
@export var radio_speakers: bool = false

var player: HubPlayer
var _shots: Array[RoomShot] = []
var _active_shot: RoomShot
var _backdrop := ShaderMaterial.new()
var _fade: ScreenFade
var _ready_to_play := false
var _leaving := false
var _resize_timer: Timer

@onready var _set: Node3D = $Set


## The room that `node` is in, or null.
static func find(node: Node) -> HubRoom:
	while node != null and not node is HubRoom:
		node = node.get_parent()
	return node as HubRoom


func _ready() -> void:
	_backdrop.shader = BACKDROP_SHADER
	_fade = ScreenFade.new()
	add_child(_fade)
	_fade.cover()
	for shot in $Shots.get_children():
		if shot is RoomShot:
			_shots.append(shot as RoomShot)
	_put_set_on_its_layer(_set)
	_spawn_player()
	var hud := HubHUD.new()
	hud.player = player
	add_child(hud)
	var pause_menu := get_node_or_null("PauseMenu") as PauseMenu
	if pause_menu != null:
		pause_menu.quit_to_title_pressed.connect(func() -> void: leave_to("res://scenes/boot/Boot.tscn", ""))
	# Repaint the backgrounds if the window changes size (after it settles).
	_resize_timer = Timer.new()
	_resize_timer.one_shot = true
	_resize_timer.wait_time = 0.3
	_resize_timer.timeout.connect(_repaint)
	add_child(_resize_timer)
	get_viewport().size_changed.connect(_resize_timer.start)
	await paint_backgrounds()
	_choose_shot(true)
	_ready_to_play = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Radio.set_context(Radio.Context.ROOM if radio_speakers else Radio.Context.OFF_AIR)
	# The game saves itself whenever you walk into a room.
	GameState.current_room = scene_file_path
	GameState.save_game()
	await _fade.fade_in()
	# Just docked with a delivery? Here's what it paid.
	if not GameState.pending_payout.is_empty():
		player.set_busy(true)
		await HubServices.show_payout(get_tree())
		player.set_busy(false)


func _physics_process(_delta: float) -> void:
	if _ready_to_play:
		_choose_shot(false)


## Fades out and goes to another room (or scene), arriving at `spawn`.
func leave_to(scene_path: String, spawn: String) -> void:
	if _leaving or scene_path.is_empty():
		return
	_leaving = true
	player.set_busy(true)
	GameState.next_spawn = spawn
	await _fade.fade_out()
	get_tree().change_scene_to_file(scene_path)


## The shot currently on screen.
func active_shot() -> RoomShot:
	return _active_shot


## Paints every shot's background picture (see the notes at the top).
func paint_backgrounds() -> void:
	if DisplayServer.get_name() == "headless":
		return  # No screen, nothing to paint (the automated tests run like this).
	_show_set_for_painting(true)
	var window := Vector2(get_window().size)
	var painter := SubViewport.new()
	painter.size = Vector2i((window * GameState.tuning.prerender_scale).round()).max(Vector2i.ONE)
	painter.world_3d = get_viewport().find_world_3d()
	painter.msaa_3d = Viewport.MSAA_4X  # Smooth edges, like rendered CG.
	painter.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var brush := Camera3D.new()
	brush.cull_mask = 1 << (SET_LAYER - 1)  # Only the Set; no people in the paint.
	painter.add_child(brush)
	add_child(painter)
	for shot in _shots:
		var camera := shot.camera()
		if camera == null:
			continue
		brush.global_transform = camera.global_transform
		brush.fov = camera.fov
		brush.near = camera.near
		brush.far = camera.far
		brush.keep_aspect = camera.keep_aspect
		brush.current = true
		painter.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		shot.background = ImageTexture.create_from_image(painter.get_texture().get_image())
	painter.queue_free()
	_show_set_for_painting(false)
	if _active_shot != null:
		_backdrop.set_shader_parameter("background", _active_shot.background)


## Switches the Set between its real look (for painting) and the painted
## backdrop (for playing). Lights stay on so they light the people, but
## without shadows, which only matter for the painting.
func _show_set_for_painting(painting: bool) -> void:
	for node in _set.find_children("*", "", true, false):
		if node is Label3D or node is Sprite3D:
			(node as Node3D).visible = painting  # Painted into the picture.
		elif node is GeometryInstance3D:
			(node as GeometryInstance3D).material_override = null if painting else _backdrop
		elif node is Light3D:
			(node as Light3D).shadow_enabled = painting and node.get_meta("paint_shadows", true)


func _put_set_on_its_layer(node: Node) -> void:
	for child in node.find_children("*", "VisualInstance3D", true, false):
		(child as VisualInstance3D).layers = 1 << (SET_LAYER - 1)


## Picks which camera to show: stay with the current shot while she's in its
## zone, otherwise the first shot whose zone she's in.
func _choose_shot(first_time: bool) -> void:
	if player == null:
		return
	var feet := player.global_position + Vector3.UP * 0.1
	if _active_shot != null and _active_shot.contains(feet) and not first_time:
		return
	var chosen: RoomShot = null
	for shot in _shots:
		if shot.contains(feet):
			chosen = shot
			break
	if chosen == null:
		chosen = _active_shot if _active_shot != null else (_shots[0] if not _shots.is_empty() else null)
	if chosen == null or (chosen == _active_shot and not first_time):
		return
	_active_shot = chosen
	chosen.camera().make_current()
	_backdrop.set_shader_parameter("background", chosen.background)
	if not first_time:
		player.on_camera_cut()


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as HubPlayer
	add_child(player)
	var spawn_name := GameState.next_spawn if not GameState.next_spawn.is_empty() else default_spawn
	GameState.next_spawn = ""
	var spawn := get_node_or_null("Spawns/" + spawn_name) as Node3D
	if spawn == null and has_node("Spawns") and $Spawns.get_child_count() > 0:
		spawn = $Spawns.get_child(0) as Node3D
	if spawn != null:
		player.global_position = spawn.global_position
		player.face(spawn.global_rotation.y)
	player.reset_physics_interpolation()


func _repaint() -> void:
	if _ready_to_play:
		await paint_backgrounds()
