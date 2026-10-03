class_name AsteroidField
extends Node3D
## Scatters hundreds of chunky, slowly tumbling rocks through an egg-shaped
## region of space, plus a few giant landmark rocks to steer around, with
## collision so you can't fly straight through them.
##
## Everything is generated when the scene starts, from a seed: the same seed
## always makes the same field. All the knobs are in the Inspector when you
## select this node in the scene.


const ROCK_SHADER := preload("res://shaders/tumbling_rock.gdshader")

## How many ordinary rocks.
@export var rock_count: int = 420
## The size of the egg-shaped region the rocks fill: width, height, length.
@export var field_size := Vector3(2600.0, 800.0, 3800.0)
## The smallest and biggest radius of an ordinary rock. Most are small.
@export var rock_radius_range := Vector2(3.0, 45.0)
## How many giant landmark rocks, and how big they are.
@export var landmark_count: int = 7
@export var landmark_radius_range := Vector2(80.0, 160.0)
## The fraction of rocks squeezed close to the line down the middle of the
## field (the way you'll probably fly), so plenty of them pass close by.
@export_range(0.0, 1.0, 0.05) var near_route_fraction: float = 0.35
## No rocks within keep_clear_radius of these spots (like where the ship
## starts). Global coordinates.
@export var keep_clear_spots := PackedVector3Array([Vector3.ZERO])
@export var keep_clear_radius: float = 150.0
## How fast rocks tumble at most, in radians per second. Big rocks turn slower.
@export var max_spin: float = 0.35
## How many different rock shapes to make.
@export var shape_count: int = 5
## Same seed = same field.
@export var field_seed: int = 5050
## Rock colors: dusty mauve, warm brown, slate, sandstone, rust.
@export var rock_colors := PackedColorArray([
	Color(0.56, 0.42, 0.52), Color(0.56, 0.41, 0.31), Color(0.4, 0.42, 0.53),
	Color(0.7, 0.6, 0.46), Color(0.62, 0.34, 0.26)])

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = field_seed
	# Each rock: its spot (relative to this node) and radius.
	var spots := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in landmark_count:
		spots.append(_random_spot(false))
		radii.append(_rng.randf_range(landmark_radius_range.x, landmark_radius_range.y))
	for i in rock_count:
		spots.append(_random_spot(_rng.randf() < near_route_fraction))
		# Cubing a 0..1 random number makes small rocks common and big ones rare.
		radii.append(lerpf(rock_radius_range.x, rock_radius_range.y, pow(_rng.randf(), 3.0)))
	_build_rocks(spots, radii)
	_build_collision(spots, radii)


## Hands each rock to one of a few shared rock shapes, drawn with MultiMeshes
## (one draw call per shape instead of one per rock).
func _build_rocks(spots: PackedVector3Array, radii: PackedFloat32Array) -> void:
	var material := ShaderMaterial.new()
	material.shader = ROCK_SHADER
	for shape in shape_count:
		var mine: Array[int] = []
		for i in spots.size():
			if i % shape_count == shape:
				mine.append(i)
		var rocks := MultiMesh.new()
		rocks.transform_format = MultiMesh.TRANSFORM_3D
		rocks.use_colors = true  # These two must be switched on before
		rocks.use_custom_data = true  # instance_count is set.
		rocks.instance_count = mine.size()
		rocks.mesh = RockMesh.build(field_seed + shape * 101)
		for slot in mine.size():
			var i := mine[slot]
			var turn := Basis.from_euler(Vector3(_rng.randf(), _rng.randf(), _rng.randf()) * TAU)
			rocks.set_instance_transform(slot, Transform3D(turn.scaled(Vector3.ONE * radii[i]), spots[i]))
			var color := rock_colors[_rng.randi_range(0, rock_colors.size() - 1)]
			rocks.set_instance_color(slot, color * _rng.randf_range(0.85, 1.1))
			# Spin axis squeezed into 0..1 (the shader unsqueezes it), and spin
			# speed in the 4th slot. Big rocks tumble slower, like big things do.
			var axis := Vector3(_rng.randfn(), _rng.randfn(), _rng.randfn()).normalized()
			var spin := _rng.randf_range(0.15, 1.0) * max_spin * clampf(15.0 / radii[i], 0.03, 1.0)
			rocks.set_instance_custom_data(slot, Color(axis.x * 0.5 + 0.5, axis.y * 0.5 + 0.5, axis.z * 0.5 + 0.5, spin))
		var drawer := MultiMeshInstance3D.new()
		drawer.name = "Rocks%d" % shape
		drawer.multimesh = rocks
		drawer.material_override = material
		add_child(drawer)


## One invisible ball per rock, a little smaller than the rock so grazing
## hits feel fair. Balls don't care which way a rock is tumbling.
func _build_collision(spots: PackedVector3Array, radii: PackedFloat32Array) -> void:
	var body := StaticBody3D.new()
	body.name = "Collision"
	add_child(body)
	for i in spots.size():
		var ball := SphereShape3D.new()
		ball.radius = radii[i] * 0.85
		var shape := CollisionShape3D.new()
		shape.shape = ball
		shape.position = spots[i]
		body.add_child(shape)


## A random spot inside the egg-shaped field, away from the keep-clear spots.
func _random_spot(near_route: bool) -> Vector3:
	var spot := Vector3.ZERO
	for attempt in 50:
		var unit := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
		if unit.length_squared() > 1.0:
			continue  # Outside the egg; try again.
		if near_route:
			unit *= Vector3(0.06, 0.1, 1.0)  # Squeeze toward the middle line.
		spot = unit * field_size * 0.5
		if _is_clear(to_global(spot)):
			break
	return spot


func _is_clear(global_spot: Vector3) -> bool:
	for clear_spot in keep_clear_spots:
		if global_spot.distance_to(clear_spot) < keep_clear_radius:
			return false
	return true
