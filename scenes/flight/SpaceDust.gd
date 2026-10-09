class_name SpaceDust
extends MeshInstance3D
## Space dust: the specks that stream past and sell your speed. The clever
## part (an endless field from a small box) lives in
## res://shaders/space_dust.gdshader; this script builds the specks once and
## keeps the shader up to date with the ship's speed and the system's color.


const DUST_SHADER := preload("res://shaders/space_dust.gdshader")

## Scales on tuning.tres's dust numbers, so a second layer can look
## different: the "Motes" layer is a few bigger, slower-glowing chunks in a
## smaller box, whipping past close for an extra sense of speed.
@export var count_scale: float = 1.0
@export var box_scale: float = 1.0
@export var size_scale: float = 1.0
@export var brightness_scale: float = 1.0
@export var streak_scale: float = 1.0

## The ship we're flying (its velocity stretches the specks into streaks).
var ship: Ship
## The current solar system's signature color.
var tint := Color.WHITE

var _material := ShaderMaterial.new()


func _ready() -> void:
	var tuning := GameState.tuning
	_material.shader = DUST_SHADER
	# The box size is baked into the specks, so it's read once, right here.
	_material.set_shader_parameter("box_size", tuning.dust_box_size * box_scale)
	mesh = _build_specks(maxi(roundi(tuning.dust_count * count_scale), 1), tuning.dust_box_size * box_scale)
	material_override = _material


func _process(_delta: float) -> void:
	if ship == null:
		return
	var tuning := GameState.tuning
	_material.set_shader_parameter("streak", ship.flight.velocity * tuning.dust_streak_seconds * streak_scale)
	_material.set_shader_parameter("speck_size", tuning.dust_size * size_scale)
	_material.set_shader_parameter("brightness", tuning.dust_brightness * brightness_scale)
	_material.set_shader_parameter("tint", tint)


## One tiny 4-corner quad per speck. All 4 corners start at the speck's home
## spot; the shader spreads them out into a streak.
func _build_specks(count: int, box_size: float) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050  # Same dust every flight.
	var homes := PackedVector3Array()
	var corners := PackedVector2Array()
	var triangles := PackedInt32Array()
	for i in count:
		var home := Vector3(rng.randf(), rng.randf(), rng.randf()) * box_size
		var first := i * 4
		for corner: Vector2 in [Vector2(0, -1), Vector2(0, 1), Vector2(1, -1), Vector2(1, 1)]:
			homes.append(home)
			corners.append(corner)
		triangles.append_array([first, first + 1, first + 2, first + 2, first + 1, first + 3])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = homes
	arrays[Mesh.ARRAY_TEX_UV] = corners
	arrays[Mesh.ARRAY_INDEX] = triangles
	var specks := ArrayMesh.new()
	specks.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# The shader moves the specks to wherever the camera is, so tell Godot the
	# mesh could be anywhere; otherwise it might skip drawing it.
	specks.custom_aabb = AABB(Vector3.ONE * -1.0e6, Vector3.ONE * 2.0e6)
	return specks
