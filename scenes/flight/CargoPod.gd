class_name CargoPod
extends RefCounted
## CARGO YOU CAN SEE: the load you're hauling, slung under the rig in
## clamps, like a sky-crane carrying a container. What it looks like comes
## from the job (JobData.look(): containers, a reefer, tanks, crates, a
## livestock pod or machinery under a tarp), and heavier loads are bigger
## (more containers, more crates). The handling already feels the weight
## (FlightModel.load_share); this is so you can see it too.
##
## Sized to whatever rig you're driving, from the model's own size (like
## RigAddOns). It's just looks: the rig's collision shape doesn't change.
## Called by Ship whenever the job in the back changes.


const DARK := Color(0.16, 0.17, 0.2)
const STEEL := Color(0.45, 0.47, 0.5)
const WOOD := Color(0.62, 0.45, 0.25)
const WINDOW := Color(1.0, 0.82, 0.45)
const REEFER_WHITE := Color(0.9, 0.92, 0.95)


## Hangs `job`'s load under the model in `pivot` (none: takes it off).
## `share` is how heavy it is for this rig (0 = light, 1 = a full load).
static func fit(pivot: Node3D, job: JobData, share: float) -> void:
	var old := pivot.get_node_or_null("Cargo")
	if old != null:
		pivot.remove_child(old)
		old.queue_free()
	if job == null:
		return
	var hull := RigAddOns.hull_box(pivot)
	if hull.size.z <= 0.0:
		return
	var holder := Node3D.new()
	holder.name = "Cargo"
	pivot.add_child(holder)
	var heft := clampf(share, 0.0, 1.0)
	# The load's box: under the middle of the rig, a bit narrower than it,
	# longer and deeper the heavier it is.
	var length := hull.size.z * lerpf(0.4, 0.62, heft)
	var width := hull.size.x * lerpf(0.55, 0.75, heft)
	var height := minf(hull.size.y * lerpf(0.4, 0.75, heft), width * 0.9)
	var gap := hull.size.y * 0.08
	var middle := hull.position.z + hull.size.z * 0.55
	var space := AABB(Vector3(hull.get_center().x - width / 2.0, hull.position.y - gap - height, middle - length / 2.0), Vector3(width, height, length))
	_clamps(holder, space, gap)
	var color := job.look_color()
	match job.look():
		"reefer":
			_containers(holder, space, heft, REEFER_WHITE, true)
		"tank":
			_tanks(holder, space, heft, color)
		"crates":
			_crates(holder, space, heft, job)
		"livestock":
			_livestock(holder, space, color)
		"machinery":
			_machinery(holder, space, color, job)
		_:
			_containers(holder, space, heft, color, false)


## The clamps that hold it up: two dark struts down from the hull, and a
## spreader bar along the top of the load.
static func _clamps(holder: Node3D, space: AABB, gap: float) -> void:
	var top := space.end.y
	var center := space.get_center()
	var unit := space.size.x * 0.06
	RigAddOns.make_box(holder, Vector3(unit * 1.4, unit * 0.8, space.size.z * 0.9), Vector3(center.x, top + unit * 0.4, center.z), DARK)
	for end: float in [-0.35, 0.35]:
		RigAddOns.make_box(holder, Vector3(space.size.x * 0.5, gap + unit, unit * 1.2), Vector3(center.x, top + gap / 2.0, center.z + end * space.size.z), DARK)


## One to three shipping containers end to end (more for heavier loads),
## with ribs, door ends and, for a reefer, a chiller unit on the front.
static func _containers(holder: Node3D, space: AABB, heft: float, color: Color, reefer: bool) -> void:
	var count := 1 + int(heft * 2.99)
	var each := space.size.z / count
	var center := space.get_center()
	for i in count:
		var z := space.position.z + each * (i + 0.5)
		var box := Vector3(space.size.x, space.size.y, each * 0.94)
		RigAddOns.make_box(holder, box, Vector3(center.x, center.y, z), color)
		# Corrugated ribs down the sides.
		for rib in 4:
			var rz := z - box.z * 0.4 + box.z * 0.8 * rib / 3.0
			RigAddOns.make_box(holder, Vector3(box.x * 1.03, box.y * 0.92, box.z * 0.03), Vector3(center.x, center.y, rz), color.darkened(0.25))
		if reefer:
			RigAddOns.make_box(holder, Vector3(box.x * 1.01, box.y * 0.12, box.z * 0.96), Vector3(center.x, center.y + box.y * 0.2, z), Color(0.2, 0.45, 0.85))
	# The doors at the back, and a reefer's chiller up front.
	RigAddOns.make_box(holder, Vector3(space.size.x * 0.9, space.size.y * 0.88, space.size.z * 0.02), Vector3(center.x, center.y, space.end.z), color.darkened(0.4))
	if reefer:
		var unit := Vector3(space.size.x * 0.6, space.size.y * 0.6, space.size.z * 0.06)
		RigAddOns.make_box(holder, unit, Vector3(center.x, center.y, space.position.z - unit.z / 2.0), DARK)
		RigAddOns.make_box(holder, unit * Vector3(0.7, 0.25, 0.2), Vector3(center.x, center.y + unit.y * 0.2, space.position.z - unit.z), Color(0.4, 0.9, 1.0), true)


## Round tanks lying along the rig (one, or two side by side when heavy),
## with dark bands and end caps.
static func _tanks(holder: Node3D, space: AABB, heft: float, color: Color) -> void:
	var side_by_side := heft > 0.55
	var count := 2 if side_by_side else 1
	var radius := minf(space.size.y, space.size.x / count) / 2.0
	var center := space.get_center()
	for i in count:
		var x := center.x + (0.0 if count == 1 else (i - 0.5) * radius * 2.05)
		var tank := RigAddOns.make_cylinder(holder, radius, space.size.z, Vector3(x, center.y, center.z), color)
		tank.rotation = Vector3(PI / 2.0, 0.0, 0.0)
		for band: float in [-0.3, 0.0, 0.3]:
			var ring := RigAddOns.make_cylinder(holder, radius * 1.05, space.size.z * 0.04, Vector3(x, center.y, center.z + band * space.size.z), DARK)
			ring.rotation = Vector3(PI / 2.0, 0.0, 0.0)
		for end: float in [-0.5, 0.5]:
			var cap := RigAddOns.make_cylinder(holder, radius * 0.8, space.size.z * 0.03, Vector3(x, center.y, center.z + end * space.size.z), STEEL)
			cap.rotation = Vector3(PI / 2.0, 0.0, 0.0)


## A stack of wooden crates under a cargo net (more for heavier loads),
## some painted the load's color.
static func _crates(holder: Node3D, space: AABB, heft: float, job: JobData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(job.id)
	var rows := 2 + int(heft * 2.0)
	var cols := 2
	var layers := 1 + int(heft * 1.99)
	var cell := Vector3(space.size.x / cols, space.size.y / layers, space.size.z / rows)
	for layer in layers:
		for row in rows:
			for col in cols:
				if layer > 0 and rng.randf() < 0.2:
					continue  # (A gap here and there, so it reads as a stack.)
				var size := cell * rng.randf_range(0.82, 0.95)
				var where := space.position + Vector3(cell.x * (col + 0.5), cell.y * (layer + 0.5), cell.z * (row + 0.5))
				var color := job.look_color() if rng.randf() < 0.3 else WOOD.lightened(rng.randf_range(-0.1, 0.15))
				RigAddOns.make_box(holder, size, where, color)
	# The cargo net: a few dark straps over the top and round the sides.
	var center := space.get_center()
	for strap in 3:
		var z := space.position.z + space.size.z * (0.2 + 0.3 * strap)
		RigAddOns.make_box(holder, Vector3(space.size.x * 1.04, space.size.y * 1.04, space.size.z * 0.03), Vector3(center.x, center.y, z), DARK)


## A rounded pod with vents and a row of little lit windows down each side
## (somebody's in there).
static func _livestock(holder: Node3D, space: AABB, color: Color) -> void:
	var center := space.get_center()
	RigAddOns.make_box(holder, space.size, center, color)
	RigAddOns.make_box(holder, space.size * Vector3(0.85, 0.12, 1.02), center + Vector3(0.0, space.size.y * 0.5, 0.0), color.darkened(0.3))
	var windows := 5
	for side: float in [-1.0, 1.0]:
		for i in windows:
			var z := space.position.z + space.size.z * (i + 0.5) / windows
			RigAddOns.make_box(holder, Vector3(space.size.x * 0.03, space.size.y * 0.22, space.size.z * 0.1),
					Vector3(center.x + side * space.size.x * 0.5, center.y + space.size.y * 0.15, z), WINDOW, true)
	# Air vents down the bottom.
	for i in 3:
		var z := space.position.z + space.size.z * (0.25 + 0.25 * i)
		RigAddOns.make_box(holder, Vector3(space.size.x * 0.6, space.size.y * 0.05, space.size.z * 0.12), Vector3(center.x, space.position.y, z), DARK)


## Odd lumpy shapes under a tarp, strapped to a flatbed.
static func _machinery(holder: Node3D, space: AABB, color: Color, job: JobData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(job.id)
	var center := space.get_center()
	var bed := space.size.y * 0.12
	RigAddOns.make_box(holder, Vector3(space.size.x, bed, space.size.z), Vector3(center.x, space.position.y + bed / 2.0, center.z), STEEL)
	var lumps := 2 + rng.randi_range(0, 2)
	for i in lumps:
		var z := space.position.z + space.size.z * (i + 0.5) / lumps
		var size := Vector3(space.size.x * rng.randf_range(0.5, 0.95), (space.size.y - bed) * rng.randf_range(0.5, 1.0), space.size.z / lumps * rng.randf_range(0.6, 0.9))
		var lump := RigAddOns.make_box(holder, size, Vector3(center.x, space.position.y + bed + size.y / 2.0, z), color)
		lump.rotation = Vector3(0.0, rng.randf_range(-0.2, 0.2), 0.0)
		if rng.randf() < 0.5:
			var drum := RigAddOns.make_cylinder(holder, size.x * 0.25, size.y * 0.4, Vector3(center.x + size.x * 0.3, space.position.y + bed + size.y, z), color.darkened(0.2))
			drum.rotation = Vector3(0.0, 0.0, PI / 2.0)
	for strap in 2:
		var z := space.position.z + space.size.z * (0.3 + 0.4 * strap)
		RigAddOns.make_box(holder, Vector3(space.size.x * 1.02, space.size.y, space.size.z * 0.025), Vector3(center.x, center.y, z), Color(0.95, 0.75, 0.15))
