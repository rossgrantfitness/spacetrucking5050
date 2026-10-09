class_name RockMesh
## Builds chunky low-poly asteroid meshes: a lumpy, slightly squashed ball
## with flat facets, the classic PS1 space rock. Different seeds give
## different rocks; the same seed always gives the same rock.


## Builds one rock about 1 meter in radius (scale it up to make big rocks).
static func build(rock_seed: int) -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = rock_seed
	noise.frequency = 0.9
	var rng := RandomNumberGenerator.new()
	rng.seed = rock_seed

	var corners := PackedVector3Array()
	var faces: Array[Vector3i] = []
	_icosphere(corners, faces)
	# Push every corner in or out with smooth noise, so the ball gets lumpy,
	# then squash it a little so not every rock is round.
	var squash := Vector3(rng.randf_range(0.8, 1.15), rng.randf_range(0.7, 1.0), rng.randf_range(0.85, 1.2))
	for i in corners.size():
		var corner := corners[i]
		corners[i] = corner * (1.0 + noise.get_noise_3dv(corner * 1.7) * 0.45) * squash

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		var a := corners[face.x]
		var b := corners[face.y]
		var c := corners[face.z]
		var outward := (b - a).cross(c - a)
		if outward.dot(a + b + c) < 0.0:
			outward = -outward
		else:
			# Godot shows a triangle's front when its corners go CLOCKWISE as
			# seen from outside, so swap two corners to get that order.
			var swap := b
			b = c
			c = swap
		# Flat shading: all three corners share one normal, and each facet gets
		# a slightly different shade, for that chunky faceted look.
		var shade := rng.randf_range(0.8, 1.0)
		surface.set_color(Color(shade, shade, shade))
		surface.set_normal(outward.normalized())
		for corner in [a, b, c]:
			surface.add_vertex(corner)
	return surface.commit()


## A ball made of 80 triangles: an icosahedron (20 triangles) with each
## triangle split into 4, and every corner pushed out to radius 1.
static func _icosphere(corners: PackedVector3Array, faces: Array[Vector3i]) -> void:
	var t := (1.0 + sqrt(5.0)) / 2.0  # The golden ratio.
	for corner in [
			Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
			Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
			Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]:
		corners.append((corner as Vector3).normalized())
	var big_faces: Array[Vector3i] = [
		Vector3i(0, 11, 5), Vector3i(0, 5, 1), Vector3i(0, 1, 7), Vector3i(0, 7, 10), Vector3i(0, 10, 11),
		Vector3i(1, 5, 9), Vector3i(5, 11, 4), Vector3i(11, 10, 2), Vector3i(10, 7, 6), Vector3i(7, 1, 8),
		Vector3i(3, 9, 4), Vector3i(3, 4, 2), Vector3i(3, 2, 6), Vector3i(3, 6, 8), Vector3i(3, 8, 9),
		Vector3i(4, 9, 5), Vector3i(2, 4, 11), Vector3i(6, 2, 10), Vector3i(8, 6, 7), Vector3i(9, 8, 1),
	]
	var midpoints := {}  # Shared edge -> index of its midpoint corner.
	for face in big_faces:
		var ab := _midpoint(face.x, face.y, corners, midpoints)
		var bc := _midpoint(face.y, face.z, corners, midpoints)
		var ca := _midpoint(face.z, face.x, corners, midpoints)
		faces.append(Vector3i(face.x, ab, ca))
		faces.append(Vector3i(face.y, bc, ab))
		faces.append(Vector3i(face.z, ca, bc))
		faces.append(Vector3i(ab, bc, ca))


static func _midpoint(i: int, j: int, corners: PackedVector3Array, midpoints: Dictionary) -> int:
	var edge := Vector2i(mini(i, j), maxi(i, j))
	if not midpoints.has(edge):
		midpoints[edge] = corners.size()
		corners.append(((corners[i] + corners[j]) * 0.5).normalized())
	return midpoints[edge]
