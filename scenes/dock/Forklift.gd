class_name Forklift
extends CharacterBody3D
## The forklift on the loading dock (LoadingDock.gd). Walk up to it and
## press E to climb on; then drive it (stick / W A S D: it steers from the
## back wheels, like a real one), slide the forks under a pallet and press E
## to lift it, drive it into your rig's hold and press E again to set it
## down. F / X climbs off.
##
## Its look is built from simple shapes in build_look() (swap in a real
## model under "Look" later). It faces -Z.


## Says something happened: "lift", "drop", "no_pallet", "bump".
signal happened(what: String, pallet: Node3D)

## Driving numbers (meters, seconds).
const TOP_SPEED: float = 5.0
const REVERSE_SPEED: float = 3.0
const ACCELERATION: float = 4.5
const BRAKING: float = 9.0
const TURN_RATE: float = 1.7
## How fast the forks go up and down, and how high.
const FORK_SPEED: float = 0.9
const FORK_LOW: float = 0.08
const FORK_HIGH: float = 0.9
## Where a lifted pallet sits on the forks (relative to the forklift).
const CARRY_SPOT := Vector3(0.0, 0.0, -1.75)

## The pallet on the forks, or null.
var carrying: Node3D = null
## The bunny in the seat (her HubPlayer), or null.
var driver: Node3D = null
var speed: float = 0.0

var _fork_height: float = FORK_LOW
var _fork_target: float = FORK_LOW
var _carriage: Node3D
var _seat: Marker3D
var _bump_cooldown: float = 0.0
var _lowering := false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.3, 1.9, 2.1)
	shape.shape = box
	shape.position = Vector3(0.0, 1.0, 0.15)  # (A hair off the floor: it rolls, it doesn't scrape.)
	add_child(shape)
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING  # Driving on the flat: no falling, no floor to stick to.
	build_look()


## Drives on: `throttle` -1 (back) to 1 (forward), `steer` -1 (left) to 1 (right).
func drive(delta: float, throttle: float, steer: float) -> void:
	var wanted := throttle * (TOP_SPEED if throttle >= 0.0 else REVERSE_SPEED)
	var rate := ACCELERATION if signf(wanted) == signf(speed) or is_zero_approx(speed) else BRAKING
	speed = move_toward(speed, wanted, rate * delta)
	if absf(throttle) < 0.05:
		speed = move_toward(speed, 0.0, BRAKING * 0.6 * delta)
	# Steering bites more the faster you go (and turns the other way in reverse).
	var grip := clampf(absf(speed) / 1.5, 0.0, 1.0)
	rotation.y -= steer * TURN_RATE * grip * signf(speed) * delta
	velocity = -global_basis.z * speed
	velocity.y = 0.0
	var before := speed
	move_and_slide()
	_bump_cooldown = maxf(_bump_cooldown - delta, 0.0)
	var hit_something := false
	for i in get_slide_collision_count():
		if absf(get_slide_collision(i).get_normal().y) < 0.7:
			hit_something = true  # (A wall or a pallet, not the floor.)
	if hit_something:
		speed *= 0.4
		if absf(before) > 2.0 and _bump_cooldown <= 0.0:
			_bump_cooldown = 0.6
			happened.emit("bump", null)
	_move_forks(delta)


## E: lift a pallet off the floor, or set the one on the forks down.
## `pallets` are the ones on the floor.
func use_forks(pallets: Array[Node3D]) -> void:
	if carrying != null:
		if _lowering:
			return
		# Lower the forks all the way, then let go.
		_lowering = true
		_fork_target = FORK_LOW
		await get_tree().create_timer(maxf(_fork_height - FORK_LOW, 0.0) / FORK_SPEED + 0.05).timeout
		_lowering = false
		var dropped := carrying
		_set_down(dropped)
		happened.emit("drop", dropped)
		return
	var best: Node3D = null
	var best_distance := 0.9
	for pallet in pallets:
		var local := global_transform.affine_inverse() * pallet.global_position
		var distance := Vector2(local.x, local.z).distance_to(Vector2(CARRY_SPOT.x, CARRY_SPOT.z))
		if distance < best_distance:
			best = pallet
			best_distance = distance
	if best == null:
		happened.emit("no_pallet", null)
		return
	_pick_up(best)
	happened.emit("lift", best)


## Climbs `player` (her HubPlayer) into the seat.
func seat(player: Node3D) -> void:
	driver = player
	player.process_mode = Node.PROCESS_MODE_DISABLED
	(player as CollisionObject3D).collision_layer = 0
	player.reparent(_seat, false)
	player.position = Vector3.ZERO
	player.rotation = Vector3.ZERO
	var look := player.get_node_or_null("Visual") as Node3D
	if look != null:
		look.rotation.y = 0.0
		if look.get_child_count() > 0:
			look.get_child(0).set("pose", "sit")


## Climbs her back off, beside the forklift. Returns her.
func unseat(world: Node3D) -> Node3D:
	var player := driver
	driver = null
	if player == null:
		return null
	player.reparent(world, false)
	player.global_position = global_position + global_basis.x * 1.4
	player.process_mode = Node.PROCESS_MODE_INHERIT
	(player as CollisionObject3D).collision_layer = 1
	var look := player.get_node_or_null("Visual") as Node3D
	if look != null and look.get_child_count() > 0:
		look.get_child(0).set("pose", "stand")
	return player


func _physics_process(delta: float) -> void:
	# Keep her sitting there looking natural (her walking script is off).
	if driver != null:
		var look := driver.get_node_or_null("Visual")
		if look != null and look.get_child_count() > 0 and look.get_child(0).has_method("animate"):
			look.get_child(0).call("animate", delta, 0.0)


func _move_forks(delta: float) -> void:
	_fork_height = move_toward(_fork_height, _fork_target, FORK_SPEED * delta)
	_carriage.position.y = _fork_height


func _pick_up(pallet: Node3D) -> void:
	carrying = pallet
	_fork_target = FORK_HIGH * 0.5
	var body := pallet as CollisionObject3D
	if body != null:
		body.collision_layer = 0
	pallet.reparent(_carriage, true)
	# Square it up on the forks.
	var tween := create_tween()
	tween.tween_property(pallet, "position", Vector3(CARRY_SPOT.x, 0.02, CARRY_SPOT.z), 0.25)
	tween.parallel().tween_property(pallet, "rotation", Vector3.ZERO, 0.25)


func _set_down(pallet: Node3D) -> void:
	carrying = null
	var world := get_parent() as Node3D
	pallet.reparent(world, true)
	pallet.global_position.y = 0.0
	pallet.rotation = Vector3(0.0, pallet.rotation.y, 0.0)
	var body := pallet as CollisionObject3D
	if body != null:
		body.collision_layer = 1


## The forklift's look: a chunky yellow body with a counterweight, an
## overhead cage, a mast at the front and two forks on a carriage that goes
## up and down.
func build_look() -> void:
	var look := Node3D.new()
	look.name = "Look"
	add_child(look)
	var yellow := Color(1.0, 0.78, 0.15)
	var dark := Color(0.15, 0.15, 0.18)
	var steel := Color(0.6, 0.62, 0.66)
	_box(look, Vector3(1.2, 0.7, 1.8), Vector3(0.0, 0.55, 0.2), yellow)  # Body.
	_box(look, Vector3(1.25, 0.6, 0.45), Vector3(0.0, 0.7, 1.0), dark)  # Counterweight.
	_box(look, Vector3(0.7, 0.35, 0.6), Vector3(0.0, 1.05, 0.35), dark)  # Seat base.
	_box(look, Vector3(0.6, 0.5, 0.12), Vector3(0.0, 1.35, 0.6), dark)  # Seat back.
	for x: float in [-0.55, 0.55]:
		for z: float in [-0.45, 0.85]:
			_box(look, Vector3(0.07, 1.4, 0.07), Vector3(x, 1.55, z), dark)  # Cage posts.
		_cylinder(look, 0.28, 0.25, Vector3(x * 1.05, 0.28, -0.5), dark, Vector3(0.0, 0.0, PI / 2.0))  # Front wheels.
		_cylinder(look, 0.22, 0.22, Vector3(x * 1.0, 0.22, 0.85), dark, Vector3(0.0, 0.0, PI / 2.0))  # Back wheels.
	_box(look, Vector3(1.2, 0.06, 1.4), Vector3(0.0, 2.25, 0.2), yellow)  # Cage roof.
	_box(look, Vector3(0.25, 0.12, 0.08), Vector3(0.0, 2.33, 0.6), Color(1.0, 0.55, 0.1), true)  # Beacon.
	for x: float in [-0.45, 0.45]:
		_box(look, Vector3(0.1, 2.2, 0.12), Vector3(x, 1.15, -0.78), steel)  # Mast.
	_carriage = Node3D.new()
	_carriage.name = "Carriage"
	add_child(_carriage)
	_box(_carriage, Vector3(1.0, 0.5, 0.08), Vector3(0.0, 0.3, -0.88), dark)
	for x: float in [-0.3, 0.3]:
		_box(_carriage, Vector3(0.14, 0.06, 1.25), Vector3(x, 0.0, -1.5), steel)  # The forks.
	_seat = Marker3D.new()
	_seat.name = "Seat"
	_seat.position = Vector3(0.0, 0.62, 0.4)
	add_child(_seat)


static func _paint(color: Color, glowing: bool = false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/psx_surface.gdshader")
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("box_uv", false)
	if glowing:
		material.set_shader_parameter("emission", color)
		material.set_shader_parameter("emission_strength", 2.0)
	return material


static func _box(parent: Node3D, size: Vector3, where: Vector3, color: Color, glowing: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _paint(color, glowing)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = where
	parent.add_child(part)
	return part


static func _cylinder(parent: Node3D, radius: float, height: float, where: Vector3, color: Color, turn: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	mesh.material = _paint(color)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = where
	part.rotation = turn
	parent.add_child(part)
