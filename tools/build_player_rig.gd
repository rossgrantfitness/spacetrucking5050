extends SceneTree
## Builds the Thumper's look, res://scenes/flight/RigLoadVisual.tscn, from the
## developer's five models of the one player rig (art/models/rig_load_0.glb =
## empty deck ... rig_load_4.glb = piled high):
##   - each model turned nose-forward (-Z), scaled to the rig's length and
##     set where the old hand-built rig sat (so its collision still fits);
##   - four engine nozzles at the tail (the model's 2 x 2 engine block),
##     where Ship hangs its flames, flares and trails.
## RigLoadVisual.gd shows one model at a time, by how heavy the job is.
##
## Run it from the project folder with:
##     godot --headless --path . -s tools/build_player_rig.gd

const OUT := "res://scenes/flight/RigLoadVisual.tscn"
const MODELS := "res://art/models/rig_load_%d.glb"
## (Loaded when it runs: these scripts use the game's autoloads, which a
## -s tool can't see while it's being compiled.)
const LOOK_SCRIPT := "res://scenes/flight/RigLoadVisual.gd"
const ENGINE_TRAIL := "res://scenes/flight/EngineTrail.gd"
const ENGINE_FLARE := "res://scenes/flight/EngineFlare.gd"
## Nose to tail, in meters (the old rig and its collision capsule: 36 m).
const LENGTH := 36.0
## Where the rig's middle sits (the collision capsule's middle).
const MIDDLE := Vector3(0.0, 0.8, -1.5)
## The engines, in the model's own units across (x) and up (y), at its tail.
const ENGINES := [Vector2(-0.077, 0.03), Vector2(0.077, 0.03), Vector2(-0.077, -0.06), Vector2(0.077, -0.06)]


func _initialize() -> void:
	var look := Node3D.new()
	look.name = "RigLoadVisual"
	look.set_script(load(LOOK_SCRIPT))
	var size := 1.0
	for i in 5:
		var model := (load(MODELS % i) as PackedScene).instantiate() as Node3D
		model.name = "Load%d" % i
		if i == 0:
			size = _bounds(model).size.x
		# The models' noses point along -X: a quarter turn puts them at -Z.
		model.rotation.y = -PI * 0.5
		model.scale = Vector3.ONE * LENGTH / size
		model.position = MIDDLE
		model.visible = i == 0
		look.add_child(model)
		model.owner = look
	var scale := LENGTH / size
	for i in ENGINES.size():
		var spot: Vector2 = ENGINES[i]
		var nozzle := Marker3D.new()
		nozzle.name = "Nozzle" if i == 0 else "Nozzle%d" % (i + 1)
		nozzle.position = MIDDLE + Vector3(spot.x * scale, spot.y * scale, LENGTH * 0.5 + 0.2)
		look.add_child(nozzle)
		nozzle.owner = look
		var trail := MeshInstance3D.new()
		trail.name = "EngineTrail"
		trail.set_script(load(ENGINE_TRAIL))
		nozzle.add_child(trail)
		trail.owner = look
		var flare := MeshInstance3D.new()
		flare.name = "EngineFlare"
		flare.set_script(load(ENGINE_FLARE))
		flare.position = Vector3(0.0, 0.0, 0.4)
		nozzle.add_child(flare)
		flare.owner = look
	var scene := PackedScene.new()
	var error := scene.pack(look)
	if error == OK:
		error = ResourceSaver.save(scene, OUT)
	print("%s: %s" % [OUT, error_string(error)])
	look.free()
	quit()


## The box around every mesh in `model` (in the model's own space).
func _bounds(model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var to_model := Transform3D.IDENTITY
		var walker: Node = mesh
		while walker != null and walker != model:
			if walker is Node3D:
				to_model = (walker as Node3D).transform * to_model
			walker = walker.get_parent()
		var part := to_model * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box
