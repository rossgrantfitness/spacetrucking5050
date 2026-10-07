class_name ProDocking
extends Node3D
## PRO DOCKING: park in the loading bay yourself (an optional switch in the
## pause menu; the autopilot docks you when it's off).
##
## Fly through a station's ring and a glowing wireframe bay appears in
## front of its dock. Bring the rig into the bay, lined up with it (nose in,
## or backed in like a real trucker), slow it right down and hold it there.
## The bay turns from cyan to yellow (lined up) to green (parked), and the
## dock crew tips you for a neat park: more for a slow, centered, straight
## one, half again for backing in. Numbers under "Pro docking" in tuning.tres.
##
## The flight scene makes one of these per attempt (see FlightSandbox.gd).

## Parked: {"place", "backed_in", "score" (0 to 1), "grade", "tip"}.
signal parked(result: Dictionary)

const CYAN := Color(0.35, 0.95, 1.0)
const YELLOW := Color(1.0, 0.82, 0.25)
const GREEN := Color(0.4, 1.0, 0.45)

## Which place's bay this is.
var place_id: String = ""
## The bay's middle, and the way into the station (from the ring to the dock).
var bay_center: Vector3 = Vector3.ZERO
var axis: Vector3 = Vector3.FORWARD
## How long the rig's been parked in it (seconds).
var held: float = 0.0
## Whether it's lined up right now, and whether it's parked.
var lined_up: bool = false
var in_place: bool = false

var _ship: Ship
var _frame: Array[MeshInstance3D] = []
var _material := ShaderMaterial.new()
var _done := false


## Puts the bay out in front of `dock` (in the world), facing along
## `into` (the way through the ring), in clear space if it can.
func start(ship: Ship, id: String, dock: Vector3, into: Vector3) -> void:
	_ship = ship
	place_id = id
	axis = into.normalized()
	var tuning := GameState.tuning
	bay_center = dock - axis * tuning.pro_dock_bay_distance
	for stretch: float in [1.0, 1.5, 2.0, 3.0, 4.0]:
		var spot := dock - axis * tuning.pro_dock_bay_distance * stretch
		if _clear(spot, tuning.pro_dock_bay_radius):
			bay_center = spot
			break
	_build(tuning)


## The bay's own axes: z along the way in, so x and y are across it.
func bay_basis() -> Basis:
	var up := Vector3.UP if absf(axis.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	return Basis.looking_at(axis, up)


## How the rig sits in the bay right now: {"across" (m from the middle
## line), "along" (m in front of / behind the middle), "speed", "facing"
## (1 = nose in, -1 = backed in, 0 = sideways)}.
func measure(spot: Vector3, nose: Vector3, speed: float) -> Dictionary:
	var local := bay_basis().inverse() * (spot - bay_center)
	return {"across": Vector2(local.x, local.y).length(), "along": local.z, "speed": speed, "facing": nose.dot(axis)}


## Whether a measurement counts as parked.
static func is_parked(fit: Dictionary, tuning: Tuning) -> bool:
	return float(fit["across"]) < tuning.pro_dock_bay_radius * 0.6 and absf(float(fit["along"])) < tuning.pro_dock_bay_depth * 0.5 \
			and float(fit["speed"]) < tuning.pro_dock_max_speed and is_lined_up(fit, tuning)


static func is_lined_up(fit: Dictionary, tuning: Tuning) -> bool:
	return absf(float(fit["facing"])) >= cos(deg_to_rad(tuning.pro_dock_max_degrees))


## How neat a park is, 0 to 1 (centered, slow, straight), its grade, and
## the dock crew's tip for it.
static func score(fit: Dictionary, tuning: Tuning) -> Dictionary:
	var centered := 1.0 - clampf(float(fit["across"]) / (tuning.pro_dock_bay_radius * 0.6), 0.0, 1.0)
	var gentle := 1.0 - clampf(float(fit["speed"]) / tuning.pro_dock_max_speed, 0.0, 1.0)
	var lowest := cos(deg_to_rad(tuning.pro_dock_max_degrees))
	var straight := clampf((absf(float(fit["facing"])) - lowest) / maxf(1.0 - lowest, 0.001), 0.0, 1.0)
	var neat := (centered + gentle + straight) / 3.0
	var backed_in := float(fit["facing"]) < 0.0
	var tip := roundi(tuning.pro_dock_tip * (0.5 + 0.5 * neat) * (tuning.pro_dock_backed_in if backed_in else 1.0))
	var grade := "PERFECT" if neat >= 0.8 else ("NICE" if neat >= 0.5 else "OKAY")
	return {"score": neat, "grade": grade, "backed_in": backed_in, "tip": tip}


## A line of guidance for the HUD: how far to the bay, how fast, lined up?
func guidance() -> String:
	if _ship == null:
		return ""
	var fit := measure(_ship.global_position, _ship.flight.nose(), _ship.flight.speed())
	var tuning := GameState.tuning
	var distance := _ship.global_position.distance_to(bay_center)
	var words := "PRO DOCK  BAY %dM  %.1f M/S" % [roundi(distance), float(fit["speed"])]
	if in_place:
		return words + "  HOLD IT..."
	if not is_lined_up(fit, tuning):
		return words + "  LINE UP"
	return words + ("  SLOW DOWN" if float(fit["speed"]) >= tuning.pro_dock_max_speed else "  LINED UP")


## Whether the rig has wandered off and given up on the bay.
func abandoned() -> bool:
	return _ship != null and _ship.global_position.distance_to(bay_center) > GameState.tuning.pro_dock_give_up_distance


func _physics_process(delta: float) -> void:
	if _ship == null or _done:
		return
	var tuning := GameState.tuning
	var fit := measure(_ship.global_position, _ship.flight.nose(), _ship.flight.speed())
	lined_up = is_lined_up(fit, tuning)
	in_place = is_parked(fit, tuning)
	held = held + delta if in_place else 0.0
	_paint(GREEN if in_place else (YELLOW if lined_up else CYAN))
	if held >= tuning.pro_dock_hold_seconds:
		_done = true
		var result := score(fit, tuning)
		result["place"] = place_id
		parked.emit(result)


## Whether there's nothing solid within `radius` of `spot` (the station's
## own hull, say), not counting the rig.
func _clear(spot: Vector3, radius: float) -> bool:
	if not is_inside_tree() or _ship == null:
		return true
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, spot)
	query.exclude = [_ship.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


## The bay: a glowing wireframe box (the mouth, the back wall and the four
## long edges), plus arrows down the middle pointing in.
func _build(tuning: Tuning) -> void:
	_material.shader = preload("res://shaders/psx_surface.gdshader")
	_material.set_shader_parameter("albedo", CYAN)
	_material.set_shader_parameter("emission", CYAN)
	_material.set_shader_parameter("emission_strength", 1.6)
	global_transform = Transform3D(bay_basis(), bay_center)
	var half := tuning.pro_dock_bay_radius
	var depth := tuning.pro_dock_bay_depth
	var bar := 1.5
	# (Local -z is the way in: Basis.looking_at points -z along `axis`.)
	for end: float in [-0.5, 0.5]:
		var z := end * depth
		for side: float in [-1.0, 1.0]:
			_bar(Vector3(half * 2.0, bar, bar), Vector3(0.0, side * half, z))
			_bar(Vector3(bar, half * 2.0, bar), Vector3(side * half, 0.0, z))
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_bar(Vector3(bar, bar, depth), Vector3(corner.x * half, corner.y * half, 0.0))
	for i in 3:
		_bar(Vector3(half * 0.5, bar, bar), Vector3(0.0, -half, depth * 0.5 - depth * (i + 1) / 4.0))


func _bar(size: Vector3, where: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = _material
	part.position = where
	add_child(part)
	_frame.append(part)
	return part


func _paint(color: Color) -> void:
	_material.set_shader_parameter("albedo", color)
	_material.set_shader_parameter("emission", color)
