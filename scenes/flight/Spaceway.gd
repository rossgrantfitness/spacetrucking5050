class_name Spaceway
extends MultiMeshInstance3D
## A "spaceway": two lines of little glowing reflector beacons lining a
## space lane, like the reflectors on a highway at night. They give empty
## space a road to follow, and whipping past them is one of the best
## speed cues there is. A pulse of light runs along them toward where the
## lane leads (res://shaders/spaceway.gdshader).
##
## Give it the lane's `points` (in the world, in order); it lines both
## sides with a beacon every `spacing` meters. All the beacons are one
## MultiMesh, so hundreds of them cost about as much as one.


const SHADER := preload("res://shaders/spaceway.gdshader")
const FLARE := preload("res://textures/generated/flare.png")

## The lane, as spots in the world it passes through, in order.
@export var points := PackedVector3Array()
## Meters between beacons along the lane.
@export var spacing: float = 200.0
## How far each line of beacons is from the middle of the lane.
@export var half_width: float = 80.0
## How big each beacon looks (meters).
@export var beacon_size: float = 16.0
## Left and right beacon colors (like a highway's yellow and white lines).
@export var left_color := Color(1.0, 0.72, 0.3)
@export var right_color := Color(0.75, 0.9, 1.0)


func _ready() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Two MultiMeshes would need two nodes; instead the colors alternate by
	# side using a second MultiMeshInstance for the right-hand line.
	_build(self, -1.0, left_color)
	var right := MultiMeshInstance3D.new()
	right.name = "RightLine"
	right.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(right)
	_build(right, 1.0, right_color)


func _build(target: MultiMeshInstance3D, side: float, color: Color) -> void:
	var spots: Array[Transform3D] = []
	var along_km: Array[float] = []
	var travelled := 0.0
	for i in range(1, points.size()):
		var from := points[i - 1]
		var to := points[i]
		var length := from.distance_to(to)
		if length < 1.0:
			continue
		var direction := (to - from) / length
		var sideways := direction.cross(Vector3.UP).normalized() * side * half_width
		var meters := 0.0
		while meters < length:
			spots.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * beacon_size), from + direction * meters + sideways))
			along_km.append((travelled + meters) / 1000.0)
			meters += spacing
		travelled += length
	var quad := QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("flare", FLARE)
	material.set_shader_parameter("color", color)
	quad.material = material
	var beacons := MultiMesh.new()
	beacons.transform_format = MultiMesh.TRANSFORM_3D
	beacons.use_custom_data = true
	beacons.mesh = quad
	beacons.instance_count = spots.size()
	for i in spots.size():
		beacons.set_instance_transform(i, spots[i])
		beacons.set_instance_custom_data(i, Color(along_km[i], 0.0, 0.0, 0.0))
	target.multimesh = beacons
	# The beacons are spread over kilometers; never skip drawing them.
	target.custom_aabb = AABB(Vector3.ONE * -1.0e6, Vector3.ONE * 2.0e6)
