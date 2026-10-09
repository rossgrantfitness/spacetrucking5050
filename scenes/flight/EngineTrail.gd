class_name EngineTrail
extends MeshInstance3D
## A glowing ribbon streaming out behind an engine.
##
## Put this on a marker at an engine nozzle, anywhere inside a ship that has
## speed_ratio() and trail_color() functions (your Ship, or a TrafficShip).
## Every frame the engine puffs out a bit of glowing exhaust, which shoots
## straight out the back of the nozzle (the way the nozzle points), and the
## trail is a fading ribbon through the puffs, always turned to face the
## camera. Puffs older than Tuning's trail_lifetime are gone.
##
## The puffs fly out of the nozzle as fast as the ship is going, so flying
## faster still makes a longer trail. And because they shoot out the back
## (rather than just being left behind where the ship was), the trail always
## streams out of the engines, even when the ship is drifting sideways or
## coasting backwards with Newtonian flight. Flying straight ahead, the puffs
## hang still in space, just where the engine was. Brightness follows speed
## too, so a parked ship leaves no trail at all.


## Never remember more spots than this (keeps very high frame rates cheap).
const MAX_POINTS: int = 128
## If the nozzle jumps farther than this in one frame (the ship was teleported
## back to the start), wipe the trail instead of drawing a giant streak.
const TELEPORT_DISTANCE: float = 200.0

## Oldest puffs first, newest last. Each puff has where it left the nozzle,
## how fast it's flying (world space), and an age in seconds.
var _starts: Array[Vector3] = []
var _speeds: Array[Vector3] = []
var _ages: Array[float] = []
## Where each puff is now (worked out from the three above every frame).
var _points: Array[Vector3] = []
var _last_nozzle := Vector3.ZERO
var _ship_velocity := Vector3.ZERO
var _source: Node3D  # The ship this trail belongs to.
var _ribbon := ImmediateMesh.new()
var _material := StandardMaterial3D.new()
var _clock := 0.0


func _ready() -> void:
	# Live in world space: the trail stays where it was drawn as the ship moves.
	top_level = true
	global_transform = Transform3D.IDENTITY
	# We redraw every frame ourselves, so Godot's motion smoothing must not.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_source = find_source(self)
	if _source != null and _source.has_signal("teleported"):
		_source.connect("teleported", clear)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD  # Glows on top of what's behind it.
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh = _ribbon


func _process(delta: float) -> void:
	if _source == null:
		return
	var lifetime := GameState.tuning.trail_lifetime
	var nozzle_transform := (get_parent() as Node3D).get_global_transform_interpolated()
	var nozzle := nozzle_transform.origin

	if not _starts.is_empty() and nozzle.distance_to(_last_nozzle) > TELEPORT_DISTANCE:
		clear()
	# How fast the engine is moving through space (smoothed a little, so
	# uneven frames don't make the trail wiggle).
	if not _starts.is_empty() and delta > 0.0:
		_ship_velocity = _ship_velocity.lerp((nozzle - _last_nozzle) / delta, minf(delta * 20.0, 1.0))
	_last_nozzle = nozzle
	for i in _ages.size():
		_ages[i] += delta
	while not _ages.is_empty() and (_ages[0] > lifetime or _ages.size() >= MAX_POINTS):
		_starts.pop_front()
		_speeds.pop_front()
		_ages.pop_front()
	# The new puff: out the back of the nozzle (its +Z, the way the exhaust
	# points), on top of the ship's own speed, so it streams straight back
	# from the engine whichever way the ship is actually drifting.
	var back := nozzle_transform.basis.z.normalized()
	_starts.append(nozzle)
	_speeds.append(_ship_velocity + back * _ship_velocity.length())
	_ages.append(0.0)
	_points.resize(_starts.size())
	for i in _starts.size():
		_points[i] = _starts[i] + _speeds[i] * _ages[i]

	_redraw(lifetime)


## Forgets the whole trail at once.
func clear() -> void:
	_points.clear()
	_starts.clear()
	_speeds.clear()
	_ages.clear()
	_ship_velocity = Vector3.ZERO
	_ribbon.clear_surfaces()


func _redraw(lifetime: float) -> void:
	_clock = Time.get_ticks_msec() * 0.001
	_ribbon.clear_surfaces()
	var camera := get_viewport().get_camera_3d()
	var tuning := GameState.tuning
	var brightness := tuning.trail_brightness * clampf(float(_source.call("speed_ratio")), 0.0, 1.3)
	if camera == null or _points.size() < 2 or brightness <= 0.01:
		return
	var eye := camera.global_position
	var color: Color = _source.call("trail_color")

	# Two ribbons: a wide one in the engine's color, and a thin white-hot core
	# down the middle, like late-90s racing-game exhaust.
	_add_ribbon(lifetime, eye, color, brightness, 1.0)
	_add_ribbon(lifetime, eye, Color.WHITE, brightness * 0.8, 0.3)


func _add_ribbon(lifetime: float, eye: Vector3, color: Color, brightness: float, width_scale: float) -> void:
	var tuning := GameState.tuning
	_ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	for i in _points.size():
		var spot := _points[i]
		# Which way the trail runs at this spot.
		var along := _points[i + 1] - spot if i + 1 < _points.size() else spot - _points[i - 1]
		# 1 at the engine, fading to 0 at the tail.
		var life := clampf(1.0 - _ages[i] / lifetime, 0.0, 1.0)
		# Sideways, at right angles to both the trail and the line of sight,
		# so the ribbon always shows its face to the camera.
		var side := along.cross(eye - spot).normalized() * tuning.trail_width * 0.5 * width_scale * (0.3 + 0.7 * life)
		# Pulses of hot plasma racing down the trail, and the color cooling
		# toward the tail (a hue shift: orange burns out to red-purple).
		var pulse := 0.7 + 0.3 * sin(float(_points.size() - i) * 0.8 - _clock * 30.0)
		var cooled := color.lerp(Color.from_hsv(fposmod(color.h - 0.12, 1.0), color.s, color.v * 0.8), 1.0 - life)
		var glow := Color(cooled.r, cooled.g, cooled.b, brightness * life * life * pulse)
		_ribbon.surface_set_color(glow)
		_ribbon.surface_add_vertex(spot - side)
		_ribbon.surface_set_color(glow)
		_ribbon.surface_add_vertex(spot + side)
	_ribbon.surface_end()


## The nearest parent of `node` that knows its speed and trail color (your
## Ship, or a TrafficShip).
static func find_source(node: Node) -> Node3D:
	node = node.get_parent()
	while node != null and not node.has_method("trail_color"):
		node = node.get_parent()
	return node as Node3D
