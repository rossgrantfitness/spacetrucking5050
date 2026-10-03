extends MultiMeshInstance3D
## A cheap starry backdrop: hundreds of tiny glowing cubes scattered on a huge
## sphere. Used behind the boot screen and in flight. (The full PSX-era sky,
## with oversized swirly planets, arrives in M4.)
##
## A MultiMesh draws many copies of one mesh in a single go, which is much
## faster than hundreds of separate nodes.


@export var star_count: int = 450
## How far away the stars sit, in meters.
@export var radius: float = 60.0
## Size of an average star cube, in meters.
@export var star_size: float = 0.22
## How fast the whole sky turns, in radians per second. Slow and dreamy.
@export var drift_speed: float = 0.012
## Stick to the camera's position (but not its turning), so the stars act as
## if they were infinitely far away, however far you fly. Used in flight.
@export var follow_camera: bool = false

## A few soft star tints: crisp white, warm white, pale cyan, pale pink.
const STAR_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0),
	Color(1.0, 0.97, 0.88),
	Color(0.7, 0.95, 1.0),
	Color(1.0, 0.78, 0.92),
]


func _ready() -> void:
	if follow_camera:
		# We move every frame ourselves; Godot's motion smoothing would lag.
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var rng := RandomNumberGenerator.new()
	rng.seed = 5050  # Same sky every time.

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # Stars glow; no lighting.
	material.vertex_color_use_as_albedo = true  # Lets each star have its own tint.
	material.disable_fog = true  # Stars shine through any space haze.
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * star_size
	cube.material = material

	var stars := MultiMesh.new()
	stars.transform_format = MultiMesh.TRANSFORM_3D
	stars.use_colors = true  # Must be switched on BEFORE setting instance_count.
	stars.instance_count = star_count
	stars.mesh = cube
	for i in star_count:
		# Three random bell-curve numbers make an evenly spread random direction.
		var direction := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		var star_scale := rng.randf_range(0.5, 1.6)
		var star_basis := Basis.from_scale(Vector3.ONE * star_scale)
		stars.set_instance_transform(i, Transform3D(star_basis, direction * radius))
		var tint: Color = STAR_COLORS[rng.randi_range(0, STAR_COLORS.size() - 1)]
		stars.set_instance_color(i, tint * rng.randf_range(0.6, 1.0))
	multimesh = stars


func _process(delta: float) -> void:
	rotate_y(drift_speed * delta)
	if follow_camera:
		var camera := get_viewport().get_camera_3d()
		if camera != null:
			global_position = camera.global_position
