class_name EngineTrail
extends MeshInstance3D
## A glowing ribbon streaming out behind an engine.
##
## Put this on a marker at an engine nozzle. Every frame it remembers where
## the nozzle is, forgets spots older than Tuning's trail_lifetime, and draws a
## fading ribbon through the remembered spots, always turned to face the
## camera. Because the ship keeps moving, flying faster spreads the spots out
## into a longer trail. Brightness follows speed too, so a parked ship leaves
## no trail at all.


## Never remember more spots than this (keeps very high frame rates cheap).
const MAX_POINTS: int = 128
## If the nozzle jumps farther than this in one frame (the ship was teleported
## back to the start), wipe the trail instead of drawing a giant streak.
const TELEPORT_DISTANCE: float = 200.0

## Oldest spots first, newest last. Each spot has an age in seconds.
var _points: Array[Vector3] = []
var _ages: Array[float] = []
var _ship: Ship
var _ribbon := ImmediateMesh.new()
var _material := StandardMaterial3D.new()


func _ready() -> void:
	# Live in world space: the trail stays where it was drawn as the ship moves.
	top_level = true
	global_transform = Transform3D.IDENTITY
	# We redraw every frame ourselves, so Godot's motion smoothing must not.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_ship = _find_ship()
	if _ship != null:
		_ship.teleported.connect(clear)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD  # Glows on top of what's behind it.
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh = _ribbon


func _process(delta: float) -> void:
	if _ship == null:
		return
	var lifetime := GameState.tuning.trail_lifetime
	var nozzle := (get_parent() as Node3D).get_global_transform_interpolated().origin

	if not _points.is_empty() and nozzle.distance_to(_points.back()) > TELEPORT_DISTANCE:
		clear()
	for i in _ages.size():
		_ages[i] += delta
	while not _ages.is_empty() and (_ages[0] > lifetime or _ages.size() >= MAX_POINTS):
		_points.pop_front()
		_ages.pop_front()
	_points.append(nozzle)
	_ages.append(0.0)

	_redraw(lifetime)


## Forgets the whole trail at once.
func clear() -> void:
	_points.clear()
	_ages.clear()
	_ribbon.clear_surfaces()


func _redraw(lifetime: float) -> void:
	_ribbon.clear_surfaces()
	var camera := get_viewport().get_camera_3d()
	var tuning := GameState.tuning
	var brightness := tuning.trail_brightness * clampf(_ship.speed_ratio(), 0.0, 2.0)
	if camera == null or _points.size() < 2 or brightness <= 0.01:
		return
	var eye := camera.global_position
	var color := _ship.ship_data.trail_color

	_ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	for i in _points.size():
		var spot := _points[i]
		# Which way the trail runs at this spot.
		var along := _points[i + 1] - spot if i + 1 < _points.size() else spot - _points[i - 1]
		# 1 at the engine, fading to 0 at the tail.
		var life := clampf(1.0 - _ages[i] / lifetime, 0.0, 1.0)
		# Sideways, at right angles to both the trail and the line of sight,
		# so the ribbon always shows its face to the camera.
		var side := along.cross(eye - spot).normalized() * tuning.trail_width * 0.5 * (0.3 + 0.7 * life)
		var glow := Color(color.r, color.g, color.b, brightness * life * life)
		_ribbon.surface_set_color(glow)
		_ribbon.surface_add_vertex(spot - side)
		_ribbon.surface_set_color(glow)
		_ribbon.surface_add_vertex(spot + side)
	_ribbon.surface_end()


func _find_ship() -> Ship:
	var node := get_parent()
	while node != null and not node is Ship:
		node = node.get_parent()
	return node as Ship
