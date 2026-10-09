extends SceneTree
## Puts the developer's casino model, "The Nebula Jackpot"
## (res://art/models/nebula_jackpot_casino.glb), into the High Roller casino
## out in space, res://scenes/flight/HighRollerStation.tscn:
##   - takes out the old placeholder drum, roulette wheel, tower, playing
##     cards, neon dice and marquee (the model has its own sign);
##   - keeps the docking bay (the block, its glowing face, the canopy and its
##     bulbs), which sticks out of the model's front (+Z, the side the
##     sign faces and you fly in from);
##   - adds the model, scaled up to station size, and gives it a collision
##     copy of its own triangles so you bonk off it.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_casino_model.gd
## (Safe to run again: it replaces the model if it's already there. To get
## the placeholder casino back, run tools/build_high_roller.gd.)

const STATION := "res://scenes/flight/HighRollerStation.tscn"
const MODEL := "res://art/models/nebula_jackpot_casino.glb"
## The model comes about 0.95 x 0.74 x 0.96 (meters); this makes it about
## 860 m across: big enough that the docking bay looks like a door in it.
const MODEL_SCALE := 900.0
## Where the model's middle sits: pushed back so its rim is at about z = +140 and
## the docking bay (its front at z = +182) pokes out of it.
const MIDDLE := Vector3(0.0, 0.0, -290.0)
## Placeholder parts to take out (names starting with these).
const OLD_PARTS: PackedStringArray = ["Drum", "Ring", "Roulette", "Tower", "Beacon", "Card", "Dice",
		"NeonDie", "DieCable", "Sign", "Model"]  # ("Model" too: a model from an earlier run.)


func _initialize() -> void:
	var station := (load(STATION) as PackedScene).instantiate() as Node3D
	var body := station.get_node("Collision") as StaticBody3D
	for node in station.get_children() + body.get_children():
		for prefix in OLD_PARTS:
			if String(node.name).begins_with(prefix):
				node.get_parent().remove_child(node)
				node.free()
				break
	var model := (load(MODEL) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	model.scale = Vector3.ONE * MODEL_SCALE
	model.position = MIDDLE
	station.add_child(model)
	model.owner = station
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		var shape := CollisionShape3D.new()
		shape.name = "ModelShape"
		# The triangles, already at full size (physics dislikes scaled shapes).
		var to_station := model.transform * _transform_in(model, instance)
		var faces := instance.mesh.get_faces()
		for i in faces.size():
			faces[i] = to_station * faces[i]
		var triangles := ConcavePolygonShape3D.new()
		triangles.set_faces(faces)
		shape.shape = triangles
		body.add_child(shape, true)
		shape.owner = station
	var scene := PackedScene.new()
	var error := scene.pack(station)
	if error == OK:
		error = ResourceSaver.save(scene, STATION)
	print("%s: %s" % [STATION, error_string(error)])
	station.free()
	quit()


## `node`'s transform relative to `top` (works outside the scene tree).
func _transform_in(top: Node3D, node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var walker: Node = node
	while walker != null and walker != top:
		if walker is Node3D:
			result = (walker as Node3D).transform * result
		walker = walker.get_parent()
	return result
