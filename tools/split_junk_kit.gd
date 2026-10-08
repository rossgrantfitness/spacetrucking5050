extends SceneTree
## Cuts the developer's sheet of cargo and junk (art/models/space_junk_pile.glb:
## about forty crates, containers, barrels, canisters, terminals, cable
## tangles and a little walker, laid out side by side as ONE mesh) into
## separate pieces, saved as a MeshLibrary: res://art/models/junk_kit.res.
## The junk fields and junk clouds out in space (AsteroidField.gd) tumble
## these pieces.
##
## How it finds the pieces: triangles that share a corner belong together;
## then parts whose footprints overlap (a crate and its handles, a tangle of
## cables) are merged. Each piece is centered and scaled to about 1.8 m
## across (the fields scale them up per piece). Tiny crumbs are skipped.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/split_junk_kit.gd

const SOURCE := "res://art/models/space_junk_pile.glb"
const OUT := "res://art/models/junk_kit.res"
## Each piece's biggest side, in meters.
const PIECE_SIZE := 1.8
## Pieces with fewer triangles than this are crumbs (skipped).
const MIN_TRIANGLES := 40

var _parent := PackedInt32Array()


func _initialize() -> void:
	var model := (load(SOURCE) as PackedScene).instantiate() as Node3D
	var source := model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var arrays := source.mesh.surface_get_arrays(0)
	var material := source.mesh.surface_get_material(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if indices.is_empty():
		# No index list: every three corners in a row are a triangle.
		indices.resize(verts.size())
		for i in verts.size():
			indices[i] = i
	# 1. Corners that touch (shared index, or the same spot: seams are split).
	_parent.resize(verts.size())
	for i in verts.size():
		_parent[i] = i
	var spots := {}
	for i in verts.size():
		var key := Vector3i((verts[i] * 2000.0).round())
		if spots.has(key):
			_join(i, spots[key])
		else:
			spots[key] = i
	for t in range(0, indices.size(), 3):
		_join(indices[t], indices[t + 1])
		_join(indices[t], indices[t + 2])
	# 2. Each group's footprint (seen from above: the sheet lies flat).
	var boxes := {}
	for i in verts.size():
		var root := _find(i)
		boxes[root] = AABB(verts[i], Vector3.ZERO) if not boxes.has(root) else (boxes[root] as AABB).expand(verts[i])
	var roots := boxes.keys()
	for a in roots.size():
		for b in range(a + 1, roots.size()):
			var box_a: AABB = boxes[roots[a]]
			var box_b: AABB = boxes[roots[b]]
			if _overlap_xz(box_a, box_b):
				_join(roots[a], roots[b])
	# 3. Triangles by piece.
	var pieces := {}
	for t in range(0, indices.size(), 3):
		var root := _find(indices[t])
		# (Packed arrays are copied when read, so add to it and put it back.)
		var tris: PackedInt32Array = pieces.get(root, PackedInt32Array())
		tris.append_array([indices[t], indices[t + 1], indices[t + 2]])
		pieces[root] = tris
	var library := MeshLibrary.new()
	var count := 0
	for root: int in pieces:
		var tris: PackedInt32Array = pieces[root]
		if tris.size() / 3 < MIN_TRIANGLES:
			continue
		var box := AABB(verts[tris[0]], Vector3.ZERO)
		for index in tris:
			box = box.expand(verts[index])
		var scale := PIECE_SIZE / maxf(box.size[box.size.max_axis_index()], 0.0001)
		var center := box.get_center()
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in tris:
			tool.set_normal(normals[index])
			tool.set_uv(uvs[index])
			tool.add_vertex((verts[index] - center) * scale)
		tool.set_material(material)
		var mesh := tool.commit()
		library.create_item(count)
		library.set_item_name(count, "Piece%d" % count)
		library.set_item_mesh(count, mesh)
		count += 1
	model.free()
	var error := ResourceSaver.save(library, OUT, ResourceSaver.FLAG_COMPRESS)
	print("%s: %s (%d pieces)" % [OUT, error_string(error), count])
	quit()


func _find(i: int) -> int:
	while _parent[i] != i:
		_parent[i] = _parent[_parent[i]]
		i = _parent[i]
	return i


func _join(a: int, b: int) -> void:
	var root_a := _find(a)
	var root_b := _find(b)
	if root_a != root_b:
		_parent[root_b] = root_a


func _overlap_xz(a: AABB, b: AABB) -> bool:
	return a.position.x < b.end.x and b.position.x < a.end.x and a.position.z < b.end.z and b.position.z < a.end.z
