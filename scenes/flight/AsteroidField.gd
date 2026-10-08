class_name AsteroidField
extends Node3D
## Scatters hundreds of chunky, slowly tumbling rocks through an egg-shaped
## region of space, plus a few giant landmark rocks to steer around, with
## collision so you can't fly straight through them.
##
## Set `layout` to "shell" and the rocks surround this node on every side
## instead: a ball of rocks around a station, between two radii, so there's
## no flying over, under or around it. Lanes (`lane_starts` to `lane_ends`)
## are kept clear: the traffic lanes in to the approach rings. FlightSandbox
## puts one round each station whose place data asks for it.
##
## Switch on `junk` and it's a debris field instead: the developer's cargo
## and junk pieces (crates, containers, barrels, terminals, cable tangles)
## tumbling about (a spilled cargo, an old scrapyard). Same bonks.
##
## Everything is generated when the scene starts, from a seed: the same seed
## always makes the same field. All the knobs are in the Inspector when you
## select this node in the scene.


const ROCK_SHADER := preload("res://shaders/tumbling_rock.gdshader")
const ROCK_TEXTURE := preload("res://textures/generated/rock.png")
const JUNK_TEXTURE := preload("res://textures/generated/hull_panels.png")
## The developer's cargo and junk pieces (crates, containers, barrels,
## terminals...), cut from one sheet by tools/split_junk_kit.gd. Junk fields
## tumble these, in their own paint.
const JUNK_KIT := preload("res://art/models/junk_kit.res")
## Scrap colors for junk fields: rusty orange, faded teal, hazard yellow,
## dull white, old red.
const JUNK_COLORS := [Color(0.7, 0.42, 0.28), Color(0.35, 0.62, 0.62), Color(0.9, 0.75, 0.25), Color(0.8, 0.8, 0.78), Color(0.7, 0.28, 0.28)]

## On: a debris field of junk instead of rocks.
@export var junk: bool = false
## "egg": rocks fill an egg-shaped region (field_size). "shell": rocks
## surround this spot on every side, between shell_radii.x and .y meters out.
@export_enum("egg", "shell") var layout: String = "egg"
@export var shell_radii := Vector2(1500.0, 2600.0)
## Clear lanes through the rocks, each from a start to an end (global
## coordinates), lane_radius wide.
@export var lane_starts := PackedVector3Array()
@export var lane_ends := PackedVector3Array()
@export var lane_radius: float = 170.0
## Past this distance the rocks aren't drawn (0 = always drawn).
@export var draw_distance: float = 0.0

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
# Every rock's center (in world space) and radius, for rocks_within().
var _rock_centers := PackedVector3Array()
var _rock_radii := PackedFloat32Array()
# The rocks sorted into big cubes of space, so rocks_within() only checks the
# rocks near the point (a field can have thousands): cube -> rock indices.
const GRID_CELL: float = 500.0
var _grid := {}
var _biggest_radius := 0.0


func _ready() -> void:
	_rng.seed = field_seed
	# Each rock: its spot (relative to this node) and radius.
	var spots := PackedVector3Array()
	var radii := PackedFloat32Array()
	for i in landmark_count:
		radii.append(_rng.randf_range(landmark_radius_range.x, landmark_radius_range.y))
		spots.append(_random_spot(false, radii[-1]))
	for i in rock_count:
		# Cubing a 0..1 random number makes small rocks common and big ones rare.
		radii.append(lerpf(rock_radius_range.x, rock_radius_range.y, pow(_rng.randf(), 3.0)))
		spots.append(_random_spot(_rng.randf() < near_route_fraction, radii[-1]))
	_build_rocks(spots, radii)
	_build_collision(spots, radii)
	add_to_group("asteroid_fields")  # So the HUD's radar can find us.
	for i in spots.size():
		_rock_centers.append(to_global(spots[i]))
		var cell := _cell_of(_rock_centers[i])
		if not _grid.has(cell):
			_grid[cell] = PackedInt32Array()
		var members: PackedInt32Array = _grid[cell]
		members.append(i)
		_grid[cell] = members  # (Packed arrays are copies: put it back.)
		_biggest_radius = maxf(_biggest_radius, radii[i])
	_rock_radii = radii


## The rocks whose surfaces are within `reach` meters of `point`, as
## Vector4s: x, y, z = the rock's center (world space), w = its radius.
## The HUD's radar globe and proximity light use this.
func rocks_within(point: Vector3, reach: float) -> Array[Vector4]:
	var found: Array[Vector4] = []
	var low := _cell_of(point - Vector3.ONE * (reach + _biggest_radius))
	var high := _cell_of(point + Vector3.ONE * (reach + _biggest_radius))
	if (high - low).length_squared() > 400:
		# A huge reach: just check every rock.
		low = Vector3i.ZERO
		high = Vector3i(-1, -1, -1)
		for i in _rock_centers.size():
			_maybe_add(found, i, point, reach)
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				var cell := Vector3i(x, y, z)
				if _grid.has(cell):
					for i: int in _grid[cell]:
						_maybe_add(found, i, point, reach)
	return found


func _maybe_add(found: Array[Vector4], i: int, point: Vector3, reach: float) -> void:
	var center := _rock_centers[i]
	if center.distance_to(point) - _rock_radii[i] <= reach:
		found.append(Vector4(center.x, center.y, center.z, _rock_radii[i]))


func _cell_of(point: Vector3) -> Vector3i:
	return Vector3i((point / GRID_CELL).floor())


## Hands each rock to one of a few shared rock shapes, drawn with MultiMeshes
## (one draw call per shape instead of one per rock).
func _build_rocks(spots: PackedVector3Array, radii: PackedFloat32Array) -> void:
	var material := ShaderMaterial.new()
	material.shader = ROCK_SHADER
	material.set_shader_parameter("rock_texture", JUNK_TEXTURE if junk else ROCK_TEXTURE)
	var kit := JUNK_KIT.get_item_list() if junk else PackedInt32Array()
	if not kit.is_empty():
		material.set_shader_parameter("rock_texture", _kit_texture())
		material.set_shader_parameter("mesh_uv", true)
	var shapes := kit.size() if not kit.is_empty() else shape_count
	for shape in shapes:
		var mine: Array[int] = []
		for i in spots.size():
			if i % shapes == shape:
				mine.append(i)
		var rocks := MultiMesh.new()
		rocks.transform_format = MultiMesh.TRANSFORM_3D
		rocks.use_colors = true  # These two must be switched on before
		rocks.use_custom_data = true  # instance_count is set.
		rocks.instance_count = mine.size()
		if not kit.is_empty():
			rocks.mesh = JUNK_KIT.get_item_mesh(kit[shape])
		else:
			rocks.mesh = junk_mesh(shape) if junk else RockMesh.build(field_seed + shape * 101)
		for slot in mine.size():
			var i := mine[slot]
			var turn := Basis.from_euler(Vector3(_rng.randf(), _rng.randf(), _rng.randf()) * TAU)
			rocks.set_instance_transform(slot, Transform3D(turn.scaled(Vector3.ONE * radii[i]), spots[i]))
			var color: Color = JUNK_COLORS[_rng.randi_range(0, JUNK_COLORS.size() - 1)] if junk else rock_colors[_rng.randi_range(0, rock_colors.size() - 1)]
			if not kit.is_empty():
				color = Color.WHITE  # (The pieces have their own paint.)
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
		drawer.visibility_range_end = draw_distance
		add_child(drawer)


## The picture the junk pieces are painted with.
func _kit_texture() -> Texture2D:
	var mesh := JUNK_KIT.get_item_mesh(JUNK_KIT.get_item_list()[0])
	var paint := mesh.surface_get_material(0) as BaseMaterial3D
	return paint.albedo_texture if paint != null else JUNK_TEXTURE


## A piece of space junk (about 1 m across, scaled up per piece): a hull
## panel, a barrel, a girder, a crate or a wedge.
static func junk_mesh(kind: int) -> Mesh:
	match kind % 5:
		0:
			var panel := BoxMesh.new()
			panel.size = Vector3(1.6, 0.15, 1.1)
			return panel
		1:
			var barrel := CylinderMesh.new()
			barrel.top_radius = 0.45
			barrel.bottom_radius = 0.45
			barrel.height = 1.2
			barrel.radial_segments = 8
			barrel.rings = 1
			return barrel
		2:
			var girder := BoxMesh.new()
			girder.size = Vector3(0.25, 0.25, 2.2)
			return girder
		3:
			var crate := BoxMesh.new()
			crate.size = Vector3(0.9, 0.9, 0.9)
			return crate
	var wedge := PrismMesh.new()
	wedge.size = Vector3(1.2, 0.8, 0.6)
	return wedge


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


## A random spot for a rock of this radius: inside the egg (or the shell),
## away from the keep-clear spots and out of the lanes.
func _random_spot(near_route: bool, radius: float) -> Vector3:
	var spot := Vector3.ZERO
	for attempt in 60:
		if layout == "shell":
			# Any direction, any distance between the two radii (evenly by
			# volume, so the outside isn't sparser than the inside).
			var direction := Vector3(_rng.randfn(), _rng.randfn(), _rng.randfn()).normalized()
			var inner := pow(shell_radii.x, 3.0)
			var outer := pow(shell_radii.y, 3.0)
			spot = direction * pow(lerpf(inner, outer, _rng.randf()), 1.0 / 3.0)
		else:
			var unit := Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
			if unit.length_squared() > 1.0:
				continue  # Outside the egg; try again.
			if near_route:
				unit *= Vector3(0.06, 0.1, 1.0)  # Squeeze toward the middle line.
			spot = unit * field_size * 0.5
		if _is_clear(to_global(spot), radius):
			break
	return spot


func _is_clear(global_spot: Vector3, radius: float) -> bool:
	for clear_spot in keep_clear_spots:
		if global_spot.distance_to(clear_spot) < keep_clear_radius:
			return false
	for i in mini(lane_starts.size(), lane_ends.size()):
		var nearest := Geometry3D.get_closest_point_to_segment(global_spot, lane_starts[i], lane_ends[i])
		if global_spot.distance_to(nearest) < lane_radius + radius:
			return false
	return true
