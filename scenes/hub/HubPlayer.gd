class_name HubPlayer
extends CharacterBody3D
## The bunny on foot, walking around the base.
##
## Movement is "camera-relative": pushing up walks away from the camera,
## whichever fixed camera is showing her. When the view cuts to a new camera,
## she keeps walking the way you were pushing (using the OLD camera's
## directions) until you let go or change direction, so a cut never suddenly
## flips your controls. That's how the old fixed-camera games got it right.
##
## The look is a separate scene inside "Visual" (BunnyVisual.tscn), so the
## placeholder can be swapped for a real model without touching this.


## Things she can use right now (people, doors), nearest first.
var _in_reach: Array[Interactable] = []
var _move_yaw := 0.0  # Which way "up on the stick" points, as a heading.
var _holding_old_camera := false
var _input_at_cut := Vector2.ZERO
var _busy := false  # Talking, or walking through a door: no moving.

@onready var visual: Node3D = $Visual
@onready var _reach: Area3D = $Reach


func _ready() -> void:
	_reach.area_entered.connect(_on_reach_entered)
	_reach.area_exited.connect(_on_reach_exited)
	floor_snap_length = 0.4  # Stick to stairs and slopes on the way down.


func _physics_process(delta: float) -> void:
	var tuning := GameState.tuning
	var stick := Vector2.ZERO
	if not _busy:
		stick = Input.get_vector("move_left", "move_right", "move_forward", "move_back", tuning.stick_deadzone)
	_update_move_yaw(stick)
	var wanted := Basis(Vector3.UP, _move_yaw) * Vector3(stick.x, 0.0, stick.y) * tuning.walk_speed
	var flat := Vector3(velocity.x, 0.0, velocity.z).move_toward(wanted, tuning.walk_acceleration * delta)
	velocity = Vector3(flat.x, velocity.y, flat.z)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
	# Turn to face where she's walking.
	if flat.length() > 0.2:
		var facing := atan2(-flat.x, -flat.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, facing, 1.0 - exp(-tuning.walk_turn_speed * delta))
	if visual.has_method("animate"):
		visual.call("animate", delta, flat.length() / tuning.walk_speed)


func _unhandled_input(event: InputEvent) -> void:
	if _busy or not event.is_action_pressed("interact"):
		return
	var target := nearest_interactable()
	if target != null:
		get_viewport().set_input_as_handled()
		target.interact(self)


## Called by the room when the view cuts to another camera.
func on_camera_cut() -> void:
	_holding_old_camera = true
	_input_at_cut = Input.get_vector("move_left", "move_right", "move_forward", "move_back", GameState.tuning.stick_deadzone)


## Stops (or lets) her move, e.g. while talking.
func set_busy(busy: bool) -> void:
	_busy = busy


func is_busy() -> bool:
	return _busy


## Faces her a given way (a heading in radians), e.g. when arriving in a room.
func face(heading: float) -> void:
	visual.rotation.y = heading


## The closest thing she can use right now, or null.
func nearest_interactable() -> Interactable:
	var best: Interactable = null
	var best_distance := INF
	for thing in _in_reach:
		if not is_instance_valid(thing) or not thing.shows_prompt():
			continue
		var distance := global_position.distance_to(thing.global_position)
		if distance < best_distance:
			best = thing
			best_distance = distance
	return best


## Works out which way the stick's "up" points: the current camera's forward
## direction, unless we're still holding on to the previous camera's after a cut.
func _update_move_yaw(stick: Vector2) -> void:
	if stick.length() < 0.1:
		_holding_old_camera = false  # Let go of the stick: use the new camera.
	elif _holding_old_camera and stick.angle_to(_input_at_cut) > deg_to_rad(GameState.tuning.camera_cut_hold_angle):
		_holding_old_camera = false  # Changed direction a lot: use the new camera.
	if _holding_old_camera:
		return
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		_move_yaw = camera_heading(camera.global_basis)


## The heading (rotation around the up axis) a camera is looking along,
## ignoring how far it tilts down.
static func camera_heading(camera_basis: Basis) -> float:
	var forward := -camera_basis.z
	return atan2(-forward.x, -forward.z)


func _on_reach_entered(area: Area3D) -> void:
	if area is Interactable:
		_in_reach.append(area as Interactable)


func _on_reach_exited(area: Area3D) -> void:
	if area is Interactable:
		_in_reach.erase(area as Interactable)
