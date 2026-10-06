extends SceneTree
## Puts the developer's truck stop model (res://art/models/truck_stop_station.glb)
## into the truck stop out in space, res://scenes/flight/Station.tscn:
##   - takes out the old placeholder hub, ring, spokes and beacons;
##   - keeps the docking bay (lights, hazard frame, chevrons), the sign
##     board and the parking deck with its parked trucks, which sit on the
##     model's front (+Z, the side you fly in from);
##   - adds the model, scaled up to station size, and gives it a collision
##     copy of its own triangles so you bonk off it.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_station_model.gd
## (Safe to run again: it starts from the placeholder parts each time it
## finds them, and replaces the model if it's already there.)

const STATION := "res://scenes/flight/Station.tscn"
const MODEL := "res://art/models/truck_stop_station.glb"
## The model comes 1 x 0.37 x 1 (meters); this makes it 720 m across.
const MODEL_SCALE := 720.0
## Where the model's front edge sits (the docking bay is at +133).
const FRONT_Z := 128.0
## Placeholder parts to take out (names starting with these).
const OLD_PARTS: PackedStringArray = ["Hub", "Ring", "Spoke", "Beacon", "Model"]  # ("Model" too: ModelShape.)


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
	model.position = Vector3(0.0, 0.0, FRONT_Z - 0.5 * MODEL_SCALE)
	station.add_child(model)
	model.owner = station
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		var shape := CollisionShape3D.new()
		shape.name = "ModelShape"
		# The triangles, already at full size (physics dislikes scaled shapes).
		var to_station := model.transform * instance.transform
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
