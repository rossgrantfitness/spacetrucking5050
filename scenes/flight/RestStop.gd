class_name RestStop
extends Node3D
## A REST STOP out on a long haul, built from its place data (PlaceData's
## "Rest stop" group), so adding one is just adding a data file:
##   diner          the Comet Diner: a neon canopy, a giant donut and a
##                  coffee cup on the roof. A hot meal at the counter.
##   fuel_depot     big round tanks and pipes. Cheap fuel, nothing else.
##   weigh_station  a scale platform under the lane, traffic lights and a
##                  booth. Weigh your load (a small bonus if it's legal).
## All three are drive-throughs: fly through a ring, pull up under the
## canopy, use the counter, roll out the far side (see FlightSandbox.gd).
## Placeholder art from primitives; swap the model out any time.

const SURFACE_SHADER := preload("res://shaders/psx_surface.gdshader")
const STEEL := Color(0.42, 0.44, 0.5)
const DARK := Color(0.16, 0.17, 0.22)

## How far the approach rings are from the middle, along the lane.
const RING_DISTANCE: float = 350.0


## The whole rest stop for `place`, ready to go under World/Places.
static func build(place: PlaceData) -> RestStop:
	var stop := RestStop.new()
	stop.name = place.id
	var facing := place.rest_stop_facing.normalized() if not place.rest_stop_facing.is_zero_approx() else Vector3.FORWARD
	var up := Vector3.UP if absf(facing.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	stop.transform = Transform3D(Basis.looking_at(facing, up), place.map_position)
	var accent := {"diner": Color(1.0, 0.35, 0.65), "fuel_depot": Color(1.0, 0.75, 0.2), "weigh_station": Color(0.3, 0.95, 0.5)}.get(place.rest_stop, Color(0.4, 0.9, 1.0)) as Color
	var model := Node3D.new()
	model.name = "Model"
	stop.add_child(model)
	stop._canopy(model, accent)
	match place.rest_stop:
		"diner":
			stop._diner(model, accent)
		"fuel_depot":
			stop._fuel_depot(model)
		"weigh_station":
			stop._weigh_station(model)
	var dock := Marker3D.new()
	dock.name = "DockPoint"
	dock.position = Vector3(0.0, -15.0, 0.0)
	stop.add_child(dock)
	for end: float in [1.0, -1.0]:
		var ring := ApproachRing.new()
		ring.name = "ApproachRing" if end > 0.0 else "ApproachRing2"
		ring.color = accent
		ring.transform = Transform3D(Basis.IDENTITY if end > 0.0 else Basis(Vector3.UP, PI), Vector3(0.0, 0.0, RING_DISTANCE * end))
		stop.add_child(ring)
	var launch := Marker3D.new()
	launch.name = "LaunchPoint"
	launch.transform = Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, 600.0))
	stop.add_child(launch)
	return stop


## The canopy over the lane: a roof slab on four pillars, neon strips under
## its edges, and the building beside it (with collision, off the lane).
func _canopy(model: Node3D, accent: Color) -> void:
	_solid(model, Vector3(240.0, 12.0, 280.0), Vector3(0.0, 70.0, 0.0), DARK)
	for x: float in [-115.0, 115.0]:
		_part(model, Vector3(4.0, 3.0, 276.0), Vector3(x, 63.0, 0.0), accent, true)
		for z: float in [-120.0, 120.0]:
			_solid(model, Vector3(14.0, 160.0, 14.0), Vector3(x, -10.0, z), STEEL)
	# The building beside the lane, with lit windows.
	_solid(model, Vector3(110.0, 90.0, 200.0), Vector3(200.0, -20.0, 0.0), Color(0.24, 0.27, 0.36))
	for z in 5:
		_part(model, Vector3(2.0, 16.0, 22.0), Vector3(144.0, -10.0, -80.0 + z * 40.0), Color(1.0, 0.85, 0.5), true)
	_part(model, Vector3(114.0, 4.0, 204.0), Vector3(200.0, 26.0, 0.0), accent, true)


func _diner(model: Node3D, accent: Color) -> void:
	# A giant donut standing on the roof...
	var donut := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 22.0
	torus.outer_radius = 40.0
	torus.rings = 16
	torus.ring_segments = 8
	torus.material = _paint(Color(0.95, 0.55, 0.75), true)
	donut.mesh = torus
	donut.position = Vector3(200.0, 75.0, -40.0)
	donut.rotation = Vector3(0.0, 0.0, PI / 2.0)
	model.add_child(donut)
	# ...and a steaming coffee cup.
	var cup := _cylinder(model, 22.0, 40.0, Vector3(200.0, 55.0, 55.0), Color(0.95, 0.95, 0.92))
	cup.mesh.set("bottom_radius", 16.0)
	_cylinder(model, 19.0, 2.0, Vector3(200.0, 75.5, 55.0), Color(0.35, 0.2, 0.12))
	_part(model, Vector3(4.0, 18.0, 6.0), Vector3(224.0, 55.0, 55.0), Color(0.95, 0.95, 0.92))
	# Pink and teal neon down the lane.
	for side: float in [-1.0, 1.0]:
		_part(model, Vector3(3.0, 3.0, 276.0), Vector3(side * 100.0, -88.0, 0.0), accent if side < 0.0 else Color(0.3, 0.95, 0.95), true)


func _fuel_depot(model: Node3D) -> void:
	for i in 4:
		var tank := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 34.0
		ball.height = 68.0
		ball.radial_segments = 10
		ball.rings = 6
		ball.material = _paint(Color(0.92, 0.9, 0.85) if i % 2 == 0 else Color(1.0, 0.75, 0.2))
		tank.mesh = ball
		tank.position = Vector3(-230.0, -20.0 + (i % 2) * 30.0, -105.0 + i * 70.0)
		model.add_child(tank)
		_part(model, Vector3(120.0, 5.0, 5.0), Vector3(-170.0, -30.0, -105.0 + i * 70.0), STEEL)


func _weigh_station(model: Node3D) -> void:
	# The scale: a striped platform under the lane.
	for i in 8:
		var stripe := Color(0.95, 0.85, 0.2) if i % 2 == 0 else DARK
		_solid(model, Vector3(170.0, 6.0, 30.0), Vector3(0.0, -95.0, -105.0 + i * 30.0), stripe)
	# Traffic lights on the pillars, and the officer's booth.
	for z: float in [-120.0, 120.0]:
		_part(model, Vector3(10.0, 26.0, 10.0), Vector3(-115.0, 40.0, z), DARK)
		_part(model, Vector3(11.0, 7.0, 11.0), Vector3(-115.0, 48.0, z), Color(1.0, 0.25, 0.2), true)
		_part(model, Vector3(11.0, 7.0, 11.0), Vector3(-115.0, 32.0, z), Color(0.3, 1.0, 0.4), true)
	_solid(model, Vector3(40.0, 40.0, 40.0), Vector3(-180.0, -60.0, 0.0), Color(0.3, 0.5, 0.95))
	_part(model, Vector3(2.0, 12.0, 26.0), Vector3(-159.0, -55.0, 0.0), Color(1.0, 0.9, 0.6), true)


# --- Parts ----------------------------------------------------------------------------

func _paint(color: Color, glowing: bool = false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SURFACE_SHADER
	material.set_shader_parameter("albedo", color)
	material.set_shader_parameter("box_uv", false)
	if glowing:
		material.set_shader_parameter("emission", color)
		material.set_shader_parameter("emission_strength", 1.6)
	return material


func _part(parent: Node3D, size: Vector3, where: Vector3, color: Color, glowing: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _paint(color, glowing)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = where
	parent.add_child(part)
	return part


## A box you can bonk into.
func _solid(parent: Node3D, size: Vector3, where: Vector3, color: Color) -> void:
	_part(parent, size, where, color)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.position = where
	body.add_child(shape)
	parent.add_child(body)


func _cylinder(parent: Node3D, radius: float, height: float, where: Vector3, color: Color) -> MeshInstance3D:
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
	parent.add_child(part)
	return part
