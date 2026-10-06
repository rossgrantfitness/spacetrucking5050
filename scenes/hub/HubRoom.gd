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


## Cabin mode (the rig's sleeper cabin, walked around in flight): the
## bunny walked out the cabin door, back to the driver's seat.
signal left_cabin
## Cabin mode: she lay down on the bed for a nap.
signal nap_requested
## Cabin mode: she walked through a door to another room of the rig.
signal room_change_requested(scene_path: String, spawn: String)
## Something to tell the player (like "the airlock's locked in flight").
signal notice_requested(text: String)

## The rooms inside the rig (your home): in flight you can walk between them.
const RIG_ROOMS: PackedStringArray = [
	"res://scenes/hub/Apartment.tscn", "res://scenes/hub/Hallway.tscn", "res://scenes/hub/Dispatch.tscn",
	"res://scenes/hub/Galley.tscn", "res://scenes/hub/EngineRoom.tscn", "res://scenes/hub/CargoBay.tscn"]

const BACKDROP_SHADER := preload("res://shaders/prerendered_backdrop.gdshader")
const PLAYER_SCENE := preload("res://scenes/hub/Player.tscn")
## Visual layer 2 holds the Set (what gets painted); layer 1 holds people.
const SET_LAYER: int = 2

## The spawn spot to use when nobody said where to arrive (like a new game).
## How long the camera can lose sight of the bunny before cutting to one
## that sees her (a short grace, so walking past a pillar doesn't flicker).
const UNSEEN_GRACE: float = 0.25
## How close to a doorway (meters) walking out of the camera's view takes
## her through it (see _walk_out_of_frame).
const DOOR_PULL: float = 2.2

@export var default_spawn: String = ""
## Which place this room belongs to (a place id from res://data/places/,
## like "base" or "truck_stop"): its job board lists jobs from here.
@export var place_id: String = "base"
## Whether the radio plays through this room's speakers (the jukebox).
@export var radio_speakers: bool = false

## On when this room is the rig's cabin, shown inside the flight scene while
## the autopilot drives (see FlightSandbox.gd). Then the door leads back to
## the driver's seat, the bed is for napping, the game doesn't save here,
## and the radio plays through the cabin speakers.
var aboard: bool = false
## What's outside, live (set by FlightSandbox.gd in flight): shown on the
## room's window ("SpaceView" in the Set) instead of its painted space.
var window_feed: Texture2D

var player: HubPlayer
var _hud: HubHUD
var _shots: Array[RoomShot] = []
var _active_shot: RoomShot
## How long the current camera has been unable to see the bunny.
var _unseen_time: float = 0.0
var _offscreen_time: float = 0.0
var _pulled_through := false
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
	# Each rig's rooms have their own color cast, so you know which rig
	# you're aboard (same rooms, different mood).
	if scene_file_path in RIG_ROOMS:
		_backdrop.set_shader_parameter("tint", GameState.active_ship_data().interior_tint)
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
	_hud = hud
	notice_requested.connect(hud.show_notice.bind(2.5))
	if scene_file_path in RIG_ROOMS:
		_bring_the_rig_to_life()
	var pause_menu := get_node_or_null("PauseMenu") as PauseMenu
	if aboard and pause_menu != null:
		pause_menu.queue_free()  # The flight scene's pause menu covers the cabin.
		pause_menu = null
	if aboard:
		_set_up_cabin()
	if window_feed != null:
		_show_window_feed()
	if pause_menu != null:
		pause_menu.quit_to_title_pressed.connect(func() -> void: leave_to("res://scenes/boot/Boot.tscn", ""))
	# Repaint the backgrounds if the window changes size (after it settles).
	_resize_timer = Timer.new()
	_resize_timer.one_shot = true
	_resize_timer.wait_time = 0.3
	_resize_timer.timeout.connect(_repaint)
	add_child(_resize_timer)
	get_viewport().size_changed.connect(_resize_timer.start)
	# Every sign on a board (the lettering's measured a frame after it loads).
	await get_tree().process_frame
	if not is_inside_tree():
		return  # Already left the room (it happens when you go straight through).
	SignBoards.mount_all([_set, get_node_or_null("Things") as Node3D])
	_put_set_on_its_layer(_set)
	await paint_backgrounds()
	_choose_shot(true)
	_ready_to_play = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Radio.set_context(Radio.Context.ROOM if radio_speakers or aboard else Radio.Context.OFF_AIR)
	# The game saves itself whenever you walk into a room (not in the cabin
	# in flight: that's saved with the flight).
	if not aboard:
		GameState.current_room = scene_file_path
		GameState.save_game()
	await _fade.fade_in()
	# A game just started or loaded: what day is it?
	if GameState.show_date_card:
		GameState.show_date_card = false
		DateCard.pop_up(get_tree())
	# Just docked with a delivery? Here's what it paid.
	if not GameState.pending_payout.is_empty():
		player.set_busy(true)
		await HubServices.show_payout(get_tree())
		player.set_busy(false)


func _physics_process(delta: float) -> void:
	if _ready_to_play:
		if _walk_out_of_frame(delta):
			return
		_choose_shot(false)


## Doors just out of the cameras' view (like dispatch's door to the
## hallway, right under the camera): if she walks out of every camera's
## frame within DOOR_PULL meters of a doorway, heading toward it, she's on
## her way through it. No hunting for an invisible doorway off-screen.
func _walk_out_of_frame(delta: float) -> bool:
	if _pulled_through or player == null or player.is_busy() or _active_shot == null or not has_node("Exits"):
		return false
	for shot in _shots:
		if sees(shot, player.global_position + Vector3.UP * 0.7, false):
			_offscreen_time = 0.0
			return false  # Some camera can still see her.
	_offscreen_time += delta
	if _offscreen_time < 0.08:
		return false
	var feet := player.global_position
	for exit in $Exits.get_children():
		var door := exit as RoomExit
		if door == null or not door.enabled or door.needs_button:
			continue
		var apart := door.global_position - feet
		var flat := Vector2(apart.x, apart.z)
		var walking := Vector2(player.velocity.x, player.velocity.z)
		# Close by, and walking toward it (not just passing).
		if flat.length() < DOOR_PULL and walking.length() > 0.3 and walking.normalized().dot(flat.normalized()) > 0.3:
			_pulled_through = true
			door.walk_through()
			return true
	return false


## Fades out and goes to another room (or scene), arriving at `spawn`.
func leave_to(scene_path: String, spawn: String) -> void:
	if _leaving or scene_path.is_empty():
		return
	if aboard:
		# In flight: the cockpit door leads back to the driver's seat, and the
		# other doors to the rig's other rooms.
		if scene_path in RIG_ROOMS:
			room_change_requested.emit(scene_path, spawn)
		else:
			left_cabin.emit()
		return
	_leaving = true
	player.set_busy(true)
	GameState.next_spawn = spawn
	await _fade.fade_out()
	if scene_path.ends_with("FlightSandbox.tscn"):
		LoadingScreen.go(get_tree(), scene_path, "flight")  # Boarding the rig.
	else:
		get_tree().change_scene_to_file(scene_path)


## Rooms aboard the rig: puts each crew member who's in here right now at
## their spot, doing their thing (see ShipLife.gd), plus anything a ship
## event has left lying around, and announces the event the first time.
func _bring_the_rig_to_life() -> void:
	ShipLife.in_flight = aboard
	var spots := get_node_or_null("CrewSpots")
	var people := get_node_or_null("People")
	if spots == null or people == null:
		return
	for entry in ShipLife.crew_in(scene_file_path):
		var activity: CrewActivity = entry["activity"]
		var marker := spots.get_node_or_null(activity.spot) as Node3D
		if marker == null:
			continue
		var crew_member := CrewNPC.new()
		crew_member.setup(entry["member"], activity)
		crew_member.transform = marker.transform
		people.add_child(crew_member)
	var event := ShipLife.current_event()
	if event != null:
		if event.find_room == scene_file_path and not event.find_item.is_empty() and not ShipLife.has_found(event):
			var marker := spots.get_node_or_null(event.find_spot) as Node3D
			if marker != null:
				_place_lost_thing(event, marker.position)
		if ShipLife.first_look(event):
			_hud.show_notice(GameState.names.fill_in(event.title).to_upper(), 4.0)
			Sfx.play("notice")
	var cargo_sign := get_node_or_null("Things/CargoSign") as Label3D
	if cargo_sign != null:
		var job := GameState.active_job()
		cargo_sign.text = "IN THE BACK: " + (job.cargo_name.to_upper() if job != null else "NOTHING. YET.")


## Something lost during a ship event, glinting where it was dropped.
func _place_lost_thing(event: ShipEvent, where: Vector3) -> void:
	var thing := Interactable.new()
	thing.name = "LostThing"
	thing.prompt = "PICK UP " + event.find_item.to_upper()
	thing.position = where
	var reach := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.9
	reach.shape = sphere
	thing.add_child(reach)
	var glint := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.18, 0.06, 0.12)
	var shine := StandardMaterial3D.new()
	shine.albedo_color = Color(1.0, 0.85, 0.3)
	shine.emission_enabled = true
	shine.emission = Color(1.0, 0.8, 0.3)
	box.material = shine
	glint.mesh = box
	glint.position = Vector3(0.0, 0.05, 0.0)
	thing.add_child(glint)
	thing.interacted.connect(func(_who: Node3D) -> void:
		ShipLife.pick_up(event)
		Sfx.play("pickup")
		var owner_name := GameState.crew.find(event.find_owner).npc.display_name.to_upper() if GameState.crew.find(event.find_owner) != null else "ITS OWNER"
		_hud.show_notice("FOUND %s! GIVE IT TO %s." % [event.find_item.to_upper(), owner_name], 4.0)
		thing.queue_free())
	$People.add_child(thing)


## Whether this room has a window that can show what's outside.
func has_window() -> bool:
	return _set.find_child("SpaceView", true, false) is MeshInstance3D


## Lays the live view (window_feed) over the window's painted space: a
## flat picture just in front of it, drawn live like the people, so the
## window bars (painted, in front of it) still cover it.
func _show_window_feed() -> void:
	var painted := _set.find_child("SpaceView", true, false) as MeshInstance3D
	if painted == null or not painted.mesh is BoxMesh:
		return
	var size := (painted.mesh as BoxMesh).size
	var quad := QuadMesh.new()
	quad.size = Vector2(size.x, size.y)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Crunchy, like the rest.
	material.albedo_texture = window_feed
	material.disable_fog = true
	quad.material = material
	var view := MeshInstance3D.new()
	view.name = "LiveWindow"
	view.mesh = quad
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	view.global_transform = painted.global_transform.translated_local(Vector3(0.0, 0.0, size.z * 0.5 + 0.01))


## Cabin mode: the bed becomes a place to nap while the autopilot drives.
func _set_up_cabin() -> void:
	if not scene_file_path.ends_with("Apartment.tscn"):
		return  # Only the apartment has a bed.
	# In flight, the bed sleeps you all the way to the next stop instead of
	# just to morning.
	var parked_bed := get_node_or_null("Things/Bed") as Interactable
	if parked_bed != null:
		parked_bed.enabled = false
	var bed := Interactable.new()
	bed.name = "NapBed"
	bed.prompt = "SLEEP TILL WE GET THERE"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 1.2, 2.6)
	shape.shape = box
	bed.add_child(shape)
	bed.position = Vector3(-2.3, 0.6, 1.3)
	bed.interacted.connect(func(_who: Node3D) -> void: nap_requested.emit())
	add_child(bed)


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
	var chest := player.global_position + Vector3.UP * 0.7
	# Keep the current shot while she's in its zone and it can see her. If
	# it loses sight of her (out of frame, or behind something solid) for
	# a moment, cut to one that can: she should never be lost off-screen.
	if not first_time and _active_shot != null and _active_shot.contains(feet):
		if sees(_active_shot, chest, true):
			_unseen_time = 0.0
			return
		_unseen_time += get_physics_process_delta_time()
		if _unseen_time < UNSEEN_GRACE:
			return
	var chosen: RoomShot = null
	# 1. The shot for where she's standing, if it can see her.
	for shot in _shots:
		if shot.contains(feet) and sees(shot, chest, not first_time):
			chosen = shot
			break
	# 2. Any shot that can see her (the closest camera).
	if chosen == null:
		var best := INF
		for shot in _shots:
			var distance := shot.camera().global_position.distance_to(chest) if shot.camera() != null else INF
			if distance < best and sees(shot, chest, not first_time):
				best = distance
				chosen = shot
	# 3. Nothing sees her (shouldn't happen): the old way, by zone.
	if chosen == null:
		for shot in _shots:
			if shot.contains(feet):
				chosen = shot
				break
	if chosen == null:
		chosen = _active_shot if _active_shot != null else (_shots[0] if not _shots.is_empty() else null)
	_unseen_time = 0.0
	if chosen == null or (chosen == _active_shot and not first_time):
		return
	_active_shot = chosen
	chosen.camera().make_current()
	_backdrop.set_shader_parameter("background", chosen.background)
	if not first_time:
		player.on_camera_cut()


## Whether `shot`'s camera can see `point`: inside its frame and (with
## `check_walls`) not hidden behind anything solid.
func sees(shot: RoomShot, point: Vector3, check_walls: bool) -> bool:
	var cam := shot.camera()
	if cam == null or not cam.is_inside_tree() or not cam.is_position_in_frustum(point):
		return false
	if not check_walls:
		return true
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, point)
	if player != null:
		query.exclude = [player.get_rid()]
	var hit := cam.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or (hit["position"] as Vector3).distance_to(point) < 0.5


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
